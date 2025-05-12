Shader "Unlit/DispWithDistance"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _TilingTex("TileMap",2D) = "white"{}
        _TilingValue("TilingValue",float) = 100
        _FadeDistance("Fade Distance", Float) = 10
        _DispDistance("Disapear Distance", Float) = 3
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off 

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
                float3 normal:NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenPos : TEXCOORD1;
                float3 worldNormal:TEXCOORD2;
                float3 worldPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            sampler2D _TilingTex;   float4 _MainTex_ST;
            float _TilingValue;
            float _DispDistance;
            float _FadeDistance;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 计算相机到当前像素的距离
                float3 camerPos = _WorldSpaceCameraPos;
                float distance = length(camerPos - i.worldPos);
                
                // 计算距离渐变因子
                //float fade = saturate(distance / _FadeDistance);
                float fadeRange = _FadeDistance - _DispDistance;
                float fade = (distance - _DispDistance) / fadeRange;

                // 动态调整剪裁
                float2 uv = i.screenPos.xy/i.screenPos.w;
                half clipValue = tex2D(_TilingTex,uv*_TilingValue).r;
                float alpha = step(clipValue, fade);
                clip(alpha-0.5);    // 小于0.5会被丢弃

                // 光照计算
                half3 lightDir =  normalize(_WorldSpaceLightPos0.xyz);
                half3 worldNormal = normalize(i.worldNormal);
                fixed3 col = tex2D(_MainTex, i.uv).rgb*saturate(dot(lightDir,worldNormal)*0.5+0.5);
                return fixed4(col, fade);   // a也随着拉近变小
            }
            ENDCG
        }
    }
}