Shader "Custom/ShaderOlas"
{
    Properties
    {
        // Color / profundidad
        _ShallowColor ("Shallow Color", Color) = (0.18, 0.28, 0.22, 1)
        _DeepColor    ("Deep Color",    Color) = (0.05, 0.09, 0.07, 1)
        _DepthMax     ("Depth Max", Float) = 2.5
        _Absorption   ("Absorption", Float) = 1.2

        // Transparencia
        _AlphaShallow ("Alpha Shallow", Range(0,1)) = 0.35
        _AlphaDeep    ("Alpha Deep",    Range(0,1)) = 0.85

        // Fresnel / reflejos (IBL)
        _FresnelPower       ("Fresnel Power", Range(0.1, 12)) = 5
        _ReflectionStrength ("Reflection Strength", Range(0,2)) = 1.0
        _BaseReflection     ("Base Reflection (cheat)", Range(0,1)) = 0.06
        _Smoothness         ("Smoothness", Range(0,1)) = 0.92

        // Anti-shimmer: roughness mínima (muy útil con Smoothness alto)
        _MinRoughness ("Min Roughness (anti-shimmer)", Range(0,1)) = 0.05

        // Specular directo desde la luz principal (para “brillo POOLS” aunque el entorno sea soso)
        _DirectSpecStrength ("Direct Spec Strength", Range(0,5)) = 1.0
        _DirectSpecPower    ("Direct Spec Power", Range(8,512)) = 160

        // Refracción (requiere Opaque Texture)
        _RefractionStrength ("Refraction Strength", Range(0,1)) = 0.12
        _Distortion         ("Distortion Amount", Range(0,1)) = 0.12

        // Borde / depth fade visual
        _EdgeFadeDistance ("Edge Fade Distance", Float) = 0.35
        _EdgeBoost        ("Edge Boost", Range(0,2)) = 0.35

        // Borde con “vida”
        _EdgeWaveAmount ("Edge Wave Amount", Range(0,1)) = 0.35
        _EdgeWaveScale  ("Edge Wave Scale", Float) = 0.8
        _EdgeWaveSpeed  ("Edge Wave Speed", Float) = 0.35

        // Normals
        [NoScaleOffset]_NormalA ("Normal A", 2D) = "bump" {}
        [NoScaleOffset]_NormalB ("Normal B", 2D) = "bump" {}
        _NormalScaleA ("Normal Scale A", Range(0,3)) = 0.35
        _NormalScaleB ("Normal Scale B", Range(0,3)) = 0.25

        _TilingA ("Tiling A (xy)", Vector) = (0.35, 0.35, 0, 0)
        _TilingB ("Tiling B (xy)", Vector) = (0.18, 0.18, 0, 0)
        _SpeedA  ("Speed A (xy)",  Vector) = (0.02, -0.015, 0, 0)
        _SpeedB  ("Speed B (xy)",  Vector) = (-0.01, 0.02, 0, 0)

        // Oleaje real (vertex displacement)
        _WaveAmplitude ("Wave Amplitude", Float) = 0.05
        _WaveFreq1     ("Wave Freq 1", Float) = 0.8
        _WaveFreq2     ("Wave Freq 2", Float) = 1.6
        _WaveSpeed1    ("Wave Speed 1", Float) = 0.35
        _WaveSpeed2    ("Wave Speed 2", Float) = -0.22
        _WaveDir1      ("Wave Dir 1 (xy)", Vector) = (1, 0.25, 0, 0)
        _WaveDir2      ("Wave Dir 2 (xy)", Vector) = (-0.4, 1, 0, 0)
        _WaveChop      ("Wave Chop", Range(0,1)) = 0.55

        // Para subir/bajar toda la ola (útil si el oleaje atraviesa el suelo y parpadea)
        _WaveBaseOffset ("Wave Base Offset", Float) = 0.0

        // Wave normals (clave para que se note desde cualquier ángulo)
        _WaveNormalEps ("Wave Normal Eps", Float) = 0.08
        _WaveNormalStrength ("Wave Normal Strength", Range(0,4)) = 2.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _CAMERA_OPAQUE_TEXTURE
            #pragma multi_compile _ _CAMERA_DEPTH_TEXTURE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareOpaqueTexture.hlsl"

            TEXTURE2D(_NormalA); SAMPLER(sampler_NormalA);
            TEXTURE2D(_NormalB); SAMPLER(sampler_NormalB);

            CBUFFER_START(UnityPerMaterial)
                float4 _ShallowColor;
                float4 _DeepColor;
                float  _DepthMax;
                float  _Absorption;

                float  _AlphaShallow;
                float  _AlphaDeep;

                float  _FresnelPower;
                float  _ReflectionStrength;
                float  _BaseReflection;
                float  _Smoothness;

                float  _MinRoughness;

                float  _DirectSpecStrength;
                float  _DirectSpecPower;

                float  _RefractionStrength;
                float  _Distortion;

                float  _EdgeFadeDistance;
                float  _EdgeBoost;

                float  _EdgeWaveAmount;
                float  _EdgeWaveScale;
                float  _EdgeWaveSpeed;

                float4 _TilingA;
                float4 _TilingB;
                float4 _SpeedA;
                float4 _SpeedB;

                float  _NormalScaleA;
                float  _NormalScaleB;

                float  _WaveAmplitude;
                float  _WaveFreq1;
                float  _WaveFreq2;
                float  _WaveSpeed1;
                float  _WaveSpeed2;
                float4 _WaveDir1;
                float4 _WaveDir2;
                float  _WaveChop;

                float  _WaveBaseOffset;

                float  _WaveNormalEps;
                float  _WaveNormalStrength;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float4 screenPos   : TEXCOORD1;

                float3 positionWS  : TEXCOORD2;
                float3 normalWS    : TEXCOORD3;
                float3 tangentWS   : TEXCOORD4;
                float3 bitangentWS : TEXCOORD5;
            };

            float3 UnpackNormalSimple(float4 p, float scale)
            {
                float3 n;
                n.xy = p.xy * 2.0 - 1.0;
                n.xy *= scale;
                n.z = sqrt(saturate(1.0 - dot(n.xy, n.xy)));
                return n;
            }

            float WaveHeight(float2 xz, float t)
            {
                float2 d1 = normalize(_WaveDir1.xy);
                float2 d2 = normalize(_WaveDir2.xy);

                float p1 = dot(xz, d1) * _WaveFreq1 + t * _WaveSpeed1;
                float p2 = dot(xz, d2) * _WaveFreq2 + t * _WaveSpeed2;

                float w = (sin(p1) + 0.6 * sin(p2)) * 0.5;

                // “Chop” para picos más marcados
                float expPow = lerp(1.0, 0.35, _WaveChop);
                w = sign(w) * pow(abs(w), expPow);

                return w * _WaveAmplitude;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float t = _Time.y;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                float2 xz = positionWS.xz;
                float eps = max(1e-4, _WaveNormalEps);

                float h  = WaveHeight(xz, t);
                float hX = WaveHeight(xz + float2(eps, 0), t);
                float hZ = WaveHeight(xz + float2(0, eps), t);

                float3 p0 = positionWS;                      p0.y += (h  + _WaveBaseOffset);
                float3 px = positionWS + float3(eps, 0, 0);  px.y += (hX + _WaveBaseOffset);
                float3 pz = positionWS + float3(0, 0, eps);  pz.y += (hZ + _WaveBaseOffset);

                positionWS = p0;

                float3 baseNormalWS = TransformObjectToWorldNormal(IN.normalOS);
                float3 waveNormalWS = normalize(cross(pz - p0, px - p0));

                float3 normalWS = normalize(baseNormalWS + (waveNormalWS - baseNormalWS) * _WaveNormalStrength);

                float3 tangentWS = normalize(TransformObjectToWorldDir(IN.tangentOS.xyz));
                tangentWS = normalize(tangentWS - normalWS * dot(tangentWS, normalWS));
                float3 bitangentWS = normalize(cross(normalWS, tangentWS) * IN.tangentOS.w);

                OUT.positionWS  = positionWS;
                OUT.normalWS    = normalWS;
                OUT.tangentWS   = tangentWS;
                OUT.bitangentWS = bitangentWS;

                float4 positionHCS = TransformWorldToHClip(positionWS);
                OUT.positionHCS = positionHCS;
                OUT.screenPos   = ComputeScreenPos(positionHCS);

                OUT.uv = IN.uv;
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
                float t = _Time.y;

                float3x3 TBN = float3x3(normalize(IN.tangentWS), normalize(IN.bitangentWS), normalize(IN.normalWS));

                // Normals (2 capas)
                float2 uvA = IN.uv * _TilingA.xy + t * _SpeedA.xy;
                float2 uvB = IN.uv * _TilingB.xy + t * _SpeedB.xy;

                float3 nA_ts = UnpackNormalSimple(SAMPLE_TEXTURE2D(_NormalA, sampler_NormalA, uvA), _NormalScaleA);
                float3 nB_ts = UnpackNormalSimple(SAMPLE_TEXTURE2D(_NormalB, sampler_NormalB, uvB), _NormalScaleB);

                float3 n_ts = normalize(float3(nA_ts.xy + nB_ts.xy, nA_ts.z * nB_ts.z));
                float3 n_ws = normalize(mul(n_ts, TBN));

                float3 viewDirWS = normalize(GetWorldSpaceViewDir(IN.positionWS));

                // Depth thickness
                float depthDiff = 0.0;
                float waterDepth01 = 0.0;

                #if defined(_CAMERA_DEPTH_TEXTURE)
                    float rawSceneDepth = SampleSceneDepth(screenUV);
                    float sceneEyeDepth = LinearEyeDepth(rawSceneDepth, _ZBufferParams);

                    float rawThisDepth = IN.screenPos.z / IN.screenPos.w;
                    float thisEyeDepth = LinearEyeDepth(rawThisDepth, _ZBufferParams);

                    depthDiff = max(0.0, sceneEyeDepth - thisEyeDepth);
                    waterDepth01 = saturate(depthDiff / max(1e-4, _DepthMax));
                #endif

                float3 depthColor = lerp(_ShallowColor.rgb, _DeepColor.rgb, waterDepth01);

                float absorb = exp(-depthDiff * _Absorption);
                float3 transmittanceColor = lerp(depthColor, _DeepColor.rgb, 1.0 - absorb);

                // Edge waviness
                float edge = 0.0;
                #if defined(_CAMERA_DEPTH_TEXTURE)
                    edge = saturate(depthDiff / max(1e-4, _EdgeFadeDistance));
                #endif
                float shore = 1.0 - edge;

                float2 e = IN.positionWS.xz * _EdgeWaveScale + t * _EdgeWaveSpeed;
                float noise = sin(dot(e, float2(1.31, 1.73))) * sin(dot(e, float2(-1.11, 2.07)));
                noise = noise * 0.5 + 0.5;

                float shoreWavy = saturate(shore + (noise - 0.5) * _EdgeWaveAmount);

                // Refraction + distortion
                float2 distortion = (n_ws.xz) * _Distortion;
                distortion += (noise - 0.5) * shoreWavy * 0.08;

                float3 refracted = transmittanceColor;
                #if defined(_CAMERA_OPAQUE_TEXTURE)
                    float2 refrUV = screenUV + distortion * _RefractionStrength;
                    float3 sceneCol = SampleSceneColor(refrUV).rgb;
                    refracted = lerp(sceneCol, transmittanceColor, saturate(0.35 + waterDepth01));
                #endif

                // Reflection (Probe / Skybox)
                float3 reflDirWS = reflect(-viewDirWS, n_ws);

                float perceptualRoughness = saturate(1.0 - _Smoothness);
                perceptualRoughness = max(perceptualRoughness, _MinRoughness); // anti-shimmer

                float3 envRefl = GlossyEnvironmentReflection(reflDirWS, perceptualRoughness, 1.0);

                float ndv = saturate(dot(n_ws, viewDirWS));
                float fresnel = pow(1.0 - ndv, _FresnelPower);

                float3 reflected = envRefl * (_BaseReflection + _ReflectionStrength * fresnel);

                // Specular directo (Main Light)
                float3 directSpec = 0;
                {
                    float4 shadowCoord = TransformWorldToShadowCoord(IN.positionWS);
                    Light mainLight = GetMainLight(shadowCoord);

                    float3 L = normalize(mainLight.direction);
                    float3 H = normalize(L + viewDirWS);

                    float ndl = saturate(dot(n_ws, L));
                    float ndh = saturate(dot(n_ws, H));

                    float spec = pow(ndh, _DirectSpecPower) * ndl;
                    directSpec = mainLight.color * spec * _DirectSpecStrength;
                }

                float3 edgeBoost = depthColor * (_EdgeBoost * shoreWavy);

                float3 col = refracted + reflected + directSpec + edgeBoost;

                float alpha = lerp(_AlphaShallow, _AlphaDeep, waterDepth01);
                alpha = saturate(alpha + fresnel * 0.20);
                alpha = saturate(alpha + shoreWavy * 0.08);

                return float4(col, alpha);
            }
            ENDHLSL
        }
    }
}
