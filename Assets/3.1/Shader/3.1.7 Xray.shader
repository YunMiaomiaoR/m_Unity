Shader "Unlit/3.1.7 Xray"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _XRayCol ("XRay Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Pass
        {
            Tags { "RenderType"="Transparent" "Queue"="Transparent" }
            Blend SrcAlpha One
            ZTest Greater
            ZWrite Off
            Cull Back

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float3 normal : TEXCOORD0;
                float3 vDir   : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            half4 _XRayCol;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.vDir = ObjSpaceViewDir(v.vertex);
                o.normal = v.normal;

                float3 normal = normalize(v.normal);
                float3 vDir = normalize(o.vDir);
                float rim = 1 - dot(normal, vDir);

                o.color = _XRayCol * rim;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }

        Pass
        {
            Tags { "RenderType"="Opaque" }
            ZTest LEqual
            ZWrite On

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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex; float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float4 finalCol = tex2D(_MainTex, i.uv);
                return finalCol;
            }
            ENDCG
        }
    }
}
