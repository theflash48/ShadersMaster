Shader "Custom/WallTiles_Unlit"
{
    Properties
    {
        _TileColor ("Tile Color", Color) = (0.95,0.95,0.95,1)
        _GroutColor ("Grout Color", Color) = (0.82,0.82,0.82,1)
        _TilesPerMeter ("Tiles Per Meter", Float) = 6
        _GroutWidth ("Grout Width", Range(0.001,0.08)) = 0.02
        _Variation ("Tile Variation", Range(0,0.15)) = 0.05
        _NoiseScale ("Variation Scale", Float) = 3
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry" "RenderType"="Opaque" }

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
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            float4 _TileColor;
            float4 _GroutColor;
            float _TilesPerMeter;
            float _GroutWidth;
            float _Variation;
            float _NoiseScale;

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                return o;
            }

            // Hash simple 0..1 a partir de una celda
            float hash21(float2 p)
            {
                p = frac(p * 0.1031);
                p += dot(p, p.yx + 33.33);
                return frac((p.x + p.y) * p.x);
            }

            half4 frag (Varyings i) : SV_Target
            {
                // UV repetida
                float2 uv = i.uv * _TilesPerMeter;

                float2 cell = floor(uv);
                float2 f = frac(uv);

                // Distancia a bordes del tile (0 en borde, 0.5 centro)
                float2 d = min(f, 1.0 - f);
                float edgeDist = min(d.x, d.y);

                // Línea de junta: si estás cerca del borde -> grout
                float grout = smoothstep(_GroutWidth, _GroutWidth * 1.6, edgeDist);
                // grout = 0 cerca del borde, 1 en el interior del tile

                // Variación por tile (muy leve)
                float n = hash21(cell * _NoiseScale);
                float variation = (n - 0.5) * 2.0 * _Variation;

                float3 tileCol = saturate(_TileColor.rgb + variation);
                float3 col = lerp(_GroutColor.rgb, tileCol, grout);

                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
