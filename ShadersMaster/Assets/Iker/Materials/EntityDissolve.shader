Shader "Custom/EntityVoid"
{
    Properties
    {
        _VoidColor ("Void Color", Color) = (0,0,0,1)

        _Dissolve ("Dissolve", Range(0,1)) = 0.5
        _NoiseScale ("Noise Scale", Float) = 6
        _NoiseSpeed ("Noise Speed", Float) = 0.6

        _EdgeWidth ("Edge Width", Range(0.001,0.2)) = 0.04
        _EdgeSoft ("Edge Softness", Range(0.001,0.2)) = 0.08

        _RimColor ("Rim Color (HDR)", Color) = (1,0,0,1)
        _RimIntensity ("Rim Intensity", Float) = 12
        _FresnelPower ("Fresnel Power", Range(0.5,8)) = 3

        _InnerGlow ("Inner Glow", Range(0,1)) = 0.25
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "Queue"="AlphaTest" "RenderType"="TransparentCutout" }

        Pass
        {
            Name "Unlit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 posWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
            };

            float4 _VoidColor;
            float _Dissolve;
            float _NoiseScale;
            float _NoiseSpeed;

            float _EdgeWidth;
            float _EdgeSoft;

            float4 _RimColor;
            float _RimIntensity;
            float _FresnelPower;
            float _InnerGlow;

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.posWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewDirWS = GetWorldSpaceViewDir(o.posWS);
                return o;
            }

            // Cheap animated pseudo-noise 0..1 in world space
            float pseudoNoise(float3 p, float t)
            {
                p = p * _NoiseScale + t;
                float n = sin(p.x) * sin(p.y * 1.37) * sin(p.z * 1.91);
                return saturate(n * 0.5 + 0.5);
            }

            half4 frag (Varyings i) : SV_Target
            {
                float t = _Time.y * _NoiseSpeed;

                // Noise used ONLY to define the cut (not to paint inside)
                float noise = pseudoNoise(i.posWS, t);

                // Signed distance from cut boundary
                float d = noise - _Dissolve;
                clip(d);

                // Edge bands: sharp rim + soft outer glow
                float rimSharp = 1.0 - smoothstep(0.0, _EdgeWidth, d);
                float rimSoft  = 1.0 - smoothstep(0.0, _EdgeSoft,  d);

                // Fresnel to make it feel like a "hole"
                float3 N = normalize(i.normalWS);
                float3 V = normalize(i.viewDirWS);
                float fres = pow(1.0 - saturate(dot(N, V)), _FresnelPower);

                // Base void: pure black
                float3 col = _VoidColor.rgb;

                // Controlled rim: red/cyan only near edge + fresnel
                float rim = saturate(rimSharp + rimSoft * 0.35) * saturate(fres + 0.25);
                col += _RimColor.rgb * rim * _RimIntensity;

                // Slight inner glow (optional) to avoid "flat black sticker"
                col += _RimColor.rgb * rimSoft * _InnerGlow;

                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
