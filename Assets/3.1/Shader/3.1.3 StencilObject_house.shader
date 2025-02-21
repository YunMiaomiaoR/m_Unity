Shader "Unlit/3.1.3 StencilObject_house"
{
    Properties
    {
        _MainTex     ("Texture", 2D)        = "white" {}
        _MainCol     ("MainColor", Color)   = (0.0, 0.0, 0.0, 0.0)
        _DiffuseCol  ("DiffuseCol", Color)  = (1.0, 1.0, 1.0, 1.0)

        _ID      ("Mask ID", Int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Geometry+2" }
        Cull off
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 200

        Stencil{
            Ref [_ID]
            Comp equal
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma target 3.0

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 posWS  : TEXCOORD0;
                float3 nDirWS : TEXCOORD1;
                float2 uv0    : TEXCOORD2;
            };

            sampler2D _MainTex;
            half4 _MainCol;
            half4 _DiffuseCol;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv0 = v.uv;
                return o;
            }

            fixed4 frag (v2f i,  float f : VFACE) : SV_Target
            {
                // 正面不透明度1，背面不透明度0.5
                fixed a = 1;
                if (f < 0) 
                    a = 0.5;

                float3 lDirWS = normalize(_WorldSpaceLightPos0.xyz);
                half halfLambert = dot(i.nDirWS, lDirWS) * 0.5 + 0.5;

                fixed3 albedo = tex2D(_MainTex, i.uv0).rgb * _MainCol;
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _DiffuseCol * albedo.rgb;
                half3 diffuse = _LightColor0.rgb * albedo * max(0, halfLambert);

                half3 finalCol = ambient + diffuse;
                return half4(finalCol, 1.0);
            }
            ENDCG
        }
    }
}
