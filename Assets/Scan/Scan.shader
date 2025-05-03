Shader "Unlit/Scan"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : POSITION;
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 depth_uv : TEXCOORD1;
            };

            sampler2D _MainTex;  float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            //ScanParam
            fixed4 _ScanCol;
            float  _ScanDistance;
            float  _ScanSpeed;
            float  _ScanRange;
            //float  _Opacity;


            v2f vert(appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                o.depth_uv = v.texcoord.xy;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 finalColor = tex2D(_MainTex, i.uv);
                //HLSLSupport.cginc: #define SAMPLE_DEPTH_TEXTURE(sampler, uv) (tex2D(sampler, uv).r)
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.depth_uv);
                // Z buffer to linear 0..1 depth
                float linear01Depth = Linear01Depth(depth);

                if (linear01Depth < _ScanDistance && linear01Depth < 1 && _ScanDistance - linear01Depth < _ScanRange)
                {
                    float diff = saturate(1 - (_ScanDistance - linear01Depth) / _ScanRange);
                    finalColor = lerp(finalColor, _ScanCol, diff);
                }

                return finalColor;
            }
            ENDCG
        }
    }
}
