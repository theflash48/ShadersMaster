Shader "Custom/DoorFrameMetal_URP"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.65,0.65,0.68,1)
        _SpecColor ("Specular Color", Color) = (1,1,1,1)
        _Smoothness ("Smoothness", Range(0,1)) = 0.85
        _MetalStrength ("Metal Strength", Range(0,2)) = 1.2

        _Brushed ("Brushed Amount", Range(0,1)) = 0.35
        _BrushScale ("Brush Scale", Float) = 25
        _BrushDir ("Brush Direction (XY)", Vector) = (1,0,0,0) // (1,0)=horizontal, (0,1)=vertical
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry" "RenderType"="Opaque" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 posWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            float4 _BaseColor;
            float4 _SpecColor;
            float _Smoothness;
            float _MetalStrength;

            float _Brushed;
            float _BrushScale;
            float4 _BrushDir;

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.posWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.uv = v.uv;
                return o;
            }

            // Hash 0..1 simple
            float hash21(float2 p)
            {
                p = frac(p * 0.1031);
                p += dot(p, p.yx + 33.33);
                return frac((p.x + p.y) * p.x);
            }

            half4 frag (Varyings i) : SV_Target
            {
                float3 N = normalize(i.normalWS);
                float3 V = normalize(GetWorldSpaceViewDir(i.posWS));

                Light light = GetMainLight();
                float3 L = normalize(-light.direction);

                // Diffuse muy bajo (metal casi no difuso)
                float NdotL = saturate(dot(N, L));
                float3 diffuse = _BaseColor.rgb * NdotL * 0.18;

                // Brushed: micro-variación a lo largo de una dirección en UV
                float2 dir = normalize(_BrushDir.xy + 1e-5);
                float brushCoord = dot(i.uv * _BrushScale, dir);

                // Rayas suaves + ruido por celda
                float stripe = sin(brushCoord) * 0.5 + 0.5;
                float n = hash21(floor(i.uv * _BrushScale));
                float brushed = lerp(1.0, saturate(0.75 + 0.25 * stripe + (n - 0.5) * 0.15), _Brushed);

                // Especular tipo Blinn-Phong con smoothness
                float3 H = normalize(L + V);
                float NdotH = saturate(dot(N, H));

                // Mapea smoothness a "shininess" (más alto = highlight más pequeño)
                float shininess = lerp(16.0, 256.0, _Smoothness);
                float spec = pow(NdotH, shininess) * _MetalStrength;

                float3 specular = _SpecColor.rgb * spec * light.color;

                // Fresnel ligero para metal
                float fres = pow(1.0 - saturate(dot(N, V)), 5.0);
                specular += _SpecColor.rgb * fres * 0.25;

                float3 col = (diffuse + specular) * brushed;

                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
