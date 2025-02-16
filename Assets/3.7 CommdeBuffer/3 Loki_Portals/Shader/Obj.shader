Shader "Unlit/Obj"
{
    Properties
    {
        _MainTex ("Texture", 2D)       = "white" {}
        _Color   ("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
        // 描边
        _StrokeWidth ("Stroke Width", Range(0.0, 0.5))  = 0.1
  [HDR] _StrokeColor ("Stroke Color", Color)            = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"  "Queue" = "Geometry+2" }
        LOD 100
        Stencil{
            Ref 0
            Comp Equal
        }

        Pass
        {

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex       : SV_POSITION;
                float3 worldNormal  : NORMAL;
                float2 uv           : TEXCOORD0;
                float4 screenPos    : TEXCOORD1;
            };

            // 物体
            sampler2D _MainTex; float4 _MainTex_ST;
            float4    _Color;
            uniform float4 _LightColor0;

            // 描边
            float     _StrokeWidth;
            sampler2D _CameraDepthTexture;
            float4    _StrokeColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;

                float3 nDir = i.worldNormal;
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz);
                
                float halfLambert = 0.5 * dot(nDir, lDir) + 0.5;
                float3 diffuse = halfLambert * col.rgb * _LightColor0.rgb;
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                float4 objColor = float4 (diffuse + ambient, 1.0);

                // 采样物体和传送门深度
                float existingDepth = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPos)).r;
                // 转换为线性深度
                float existingDepthLinear = LinearEyeDepth(existingDepth);
                // 深度差值(场景深度-物体深度)
                float depthDiffrence = existingDepthLinear - i.screenPos.w;
                // 插值(2.0是阈值)
                float strokeDepthLerp = saturate(depthDiffrence / 2.0);
                float4 strokeColor = lerp(_StrokeColor, objColor, strokeDepthLerp);
                // 二进制开关
                float strokeCutoff = depthDiffrence < _StrokeWidth && depthDiffrence > 0 ? 1 : 0;
                
                return strokeCutoff * strokeColor + objColor;
            }
            ENDCG
        }
    }
}
