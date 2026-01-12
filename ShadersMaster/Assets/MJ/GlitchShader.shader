Shader "Custom/GlitchShader"
{
    Properties
    {
        [HDR]_Tint("Tint (HDR)", Color) = (1,1,1,1.5)
        _Opacity("Opacity", Range(0,1)) = 0.75

        _NoiseTex("NoiseTex", 2D) = "white" {}
        _NoiseTiling("NoiseTiling", Range(0.1,50)) = 11.0

        _ScanDensity("ScanDensity", Range(1,800)) = 420
        _ScanSpeed("ScanSpeed", Range(-40,40)) = 7.0

        _GlitchStrength("GlitchStrength", Range(0,0.25)) = 0.12
        _GlitchSpeed("GlitchSpeed", Range(0,30)) = 12.0

        _LineTearStrength("LineTearStrength", Range(0,0.25)) = 0.14

        _RGBSplit("RGB Split", Range(0,0.04)) = 0.014
        _ColorGlitchStrength("ColorGlitchStrength", Range(0,3)) = 2.0

        _BlockSize("BlockSize", Range(4,256)) = 120
        _BlockThreshold("BlockThreshold", Range(0,1)) = 0.55
        _BlockStrength("BlockStrength", Range(0,3)) = 1.8

        _FrameRate("FrameRate", Range(1,60)) = 14
        _FreezeChance("FreezeChance", Range(0,1)) = 0.35
        _FreezeStrength("FreezeStrength", Range(0,1)) = 1.0
        _FreezeBandDensity("FreezeBandDensity", Range(8,1024)) = 180

        _VerticalJitter("VerticalJitter", Range(0,0.05)) = 0.018
        _SnowStrength("SnowStrength", Range(0,2)) = 0.55
        _SnowSpeed("SnowSpeed", Range(0,40)) = 18

        _FresnelPower("FresnelPower", Range(0.1,10)) = 3.0
        _FresnelStrength("FresnelStrength", Range(0,5)) = 0.9

        _Dissolve("Dissolve", Range(0,1)) = 0.0
        _DissolveWidth("DissolveWidth", Range(0.0001,0.5)) = 0.08
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" "RenderType"="Transparent" }

        Pass
        {
            Name "Unlit"
            Tags { "LightMode"="UniversalForward" }

            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            CBUFFER_START(UnityPerMaterial)
                half4 _Tint;
                half _Opacity;

                half _NoiseTiling;

                half _ScanDensity;
                half _ScanSpeed;

                half _GlitchStrength;
                half _GlitchSpeed;

                half _LineTearStrength;

                half _RGBSplit;
                half _ColorGlitchStrength;

                half _BlockSize;
                half _BlockThreshold;
                half _BlockStrength;

                half _FrameRate;
                half _FreezeChance;
                half _FreezeStrength;
                half _FreezeBandDensity;

                half _VerticalJitter;
                half _SnowStrength;
                half _SnowSpeed;

                half _FresnelPower;
                half _FresnelStrength;

                half _Dissolve;
                half _DissolveWidth;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float3 positionWS  : TEXCOORD2;
            };

            Varyings vert(Attributes v)
            {
                Varyings o;
                VertexPositionInputs p = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionHCS = p.positionCS;
                o.positionWS = p.positionWS;

                VertexNormalInputs n = GetVertexNormalInputs(v.normalOS);
                o.normalWS = n.normalWS;

                o.uv = v.uv;
                return o;
            }

            half4 frag(Varyings i) : SV_Target
            {
                float t = _Time.y;
                float2 uv = i.uv;

                float fps = max(1.0, (float)_FrameRate);
                float tQ = floor(t * fps) / fps;

                float bandFreezeCount = max(8.0, (float)_FreezeBandDensity);
                float yFreezeBand = floor(uv.y * bandFreezeCount) / bandFreezeCount;

                float freezeN = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, float2(yFreezeBand * 7.31, floor(t * 3.0) * 0.11)).r;
                float freezeMask = smoothstep(1.0 - _FreezeChance, 1.0, freezeN) * _FreezeStrength;

                float burstN = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, float2(floor(t * 2.0) * 0.19, 0.37)).g;
                float burst = smoothstep(0.72, 0.98, burstN);

                float tUse = lerp(t, tQ, saturate(freezeMask * (0.55 + 0.45 * burst)));

                float scan = 0.5 + 0.5 * sin((uv.y * _ScanDensity) + (tUse * _ScanSpeed));
                scan = saturate(scan);

                float bandCount = max(1.0, _ScanDensity * 0.5);
                float yBand = floor(uv.y * bandCount) / bandCount;

                float vJ = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, float2(tUse * 0.9, floor(tUse * 6.0) * 0.13)).b;
                float vJitter = (vJ - 0.5) * 2.0 * _VerticalJitter * (0.25 + 0.75 * burst);

                float2 uvJ = uv;
                uvJ.y = frac(uvJ.y + vJitter);

                float blockSize = max(4.0, (float)_BlockSize);
                float2 blockUV = floor(uvJ * blockSize) / blockSize;
                float blockN = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, blockUV + float2(tUse * 0.22, tUse * 0.17)).r;
                float blockMask = smoothstep(_BlockThreshold, _BlockThreshold + 0.08, blockN);

                float lineN = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, float2(yBand * _NoiseTiling, floor(tUse * 10.0) * 0.07)).g;
                float lineTear = (lineN - 0.5) * 2.0;
                lineTear *= _LineTearStrength * (0.35 + 0.65 * burst);

                float2 nUV2 = float2((uvJ.x * _NoiseTiling) + tUse * (_GlitchSpeed * 1.7),
                                     (yBand * _NoiseTiling) + tUse * (_GlitchSpeed * 0.9));
                float n2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, nUV2).r;

                float glitch = (n2 - 0.5) * 2.0;
                float glitchAmp = _GlitchStrength;
                glitchAmp *= (0.30 + 0.70 * scan);
                glitchAmp *= (0.55 + 1.45 * blockMask * _BlockStrength);
                glitchAmp *= (0.35 + 0.65 * burst);

                float2 uvG = uvJ;
                uvG.x += glitch * glitchAmp;
                uvG.x += lineTear;

                float split = _RGBSplit * (0.45 + 0.55 * burst) * (0.6 + 0.4 * blockMask);
                float2 uvR = uvG + float2(split, 0);
                float2 uvB = uvG - float2(split, 0);

                float nR = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvR * (_NoiseTiling * 1.15) + float2(tUse * 0.11, tUse * 0.07)).r;
                float nG = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvG * (_NoiseTiling * 1.15) + float2(tUse * 0.13, tUse * 0.09)).g;
                float nB = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvB * (_NoiseTiling * 1.15) + float2(tUse * 0.17, tUse * 0.12)).b;

                float3 baseCol = _Tint.rgb;
                float3 glitchCol = float3(nR, nG, nB);
                float3 col = baseCol;
                col = lerp(col, col * (0.82 + 0.18 * scan), 0.7);
                col += (glitchCol - 0.5) * _ColorGlitchStrength * (0.30 + 0.70 * blockMask) * (0.25 + 0.75 * burst);

                float snowN = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvJ * (_NoiseTiling * 5.0) + float2(tUse * _SnowSpeed, tUse * (_SnowSpeed * 0.73))).r;
                float snow = (snowN - 0.5) * 2.0;
                col += snow * _SnowStrength * (0.15 + 0.85 * burst);

                float dissolveNoise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uvG * (_NoiseTiling * 0.75) + float2(tUse * 0.15, tUse * 0.09)).r;
                float mask = smoothstep(_Dissolve, _Dissolve + _DissolveWidth, dissolveNoise);

                float3 normalWS = normalize(i.normalWS);
                float3 viewDirWS = normalize(GetCameraPositionWS() - i.positionWS);
                float fres = pow(1.0 - saturate(dot(normalWS, viewDirWS)), _FresnelPower) * _FresnelStrength;

                float flicker = saturate(0.68 + 0.32 * sin(tUse * (_GlitchSpeed * 2.2) + n2 * 6.2831853));
                float alpha = _Opacity;
                alpha *= (0.30 + 0.70 * scan);
                alpha *= (0.75 + 0.25 * blockMask);
                alpha *= flicker;
                alpha *= mask;
                alpha = saturate(alpha);

                col *= (1.0 + fres);
                return half4(col, alpha);
            }
            ENDHLSL
        }
    }
}
