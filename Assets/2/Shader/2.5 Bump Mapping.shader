Shader "Unlit/2.5 Bump Mapping"
{
    Properties
    {
        [KeywordEnum(ParallaxMapping, SPM, ReliefMapping, POM)] _BMP("Bump Mape Type", Float) = 0

        _MainTex    ("主纹理", 2D)     ="white"{}
        _NormalTex  ("法线贴图", 2D)   = "bump"{}
        _HeightTex  ("高度图", 2D)     = "white"{}
        _Cubmap     ("环境贴图", 2D)   = "_Skybox"{}

        _MainCol    ("基本色", Color)      = (1.0, 1.0, 1.0, 1.0)
        _DiffuseCol ("漫反射颜色", Color)  = (1.0, 1.0, 1.0, 1.0)
        _SpecularCol("高光颜色", Color)    = (1.0, 1.0, 1.0, 1.0)

        _Gloss      ("光泽度", Range(0, 30))          = 10
        _NormalInt  ("法线扰动强度", Range(0, 5))       = 1
        _HeightInt  ("高度图扰动强度", Range(0, 0.05))   = 0.02
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            #pragma multi_compile _BMP_PARALLAXMAPPING _BMP_SPM _BMP_RELIEFMAPPING _BMP_POM

            sampler2D _MainTex; float4 _MainTex_ST;
            sampler2D _NormalTex; float4 _NormalTex_ST;
            sampler2D _HeightTex; float4 _HeightTex_ST;
            samplerCUBE _Cubmap;

            half4 _MainCol;
            half4 _DiffuseCol;
            half4 _SpecularCol;

            half _Gloss;
            half _NormalInt;
            half _HeightInt;

            struct appdata
            {
                float4 vertex   : POSITION;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                float2 uv       : TEXCOORD0;
            };

            struct v2f
            {
                float4 posCS  : SV_POSITION;
                float4 posWS  : TEXCOORD0;
                float3 tDirWS : TEXCOORD1;
                float3 bDirWS : TEXCOORD2;
                float3 nDirWS : TEXCOORD3;
                float2 uv0    : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.posCS = UnityObjectToClipPos(v.vertex);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = normalize(UnityObjectToWorldNormal(v.normal));
                o.tDirWS = normalize(UnityObjectToWorldDir(v.tangent.xyz));
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w);
                o.uv0 = v.uv;
                return o;
            }

            // 视差映射：偏移uv
            float2 ParallaxMapping(float2 uv, float3 vDirTS)
            {
                //高度采样
                float height = tex2D(_HeightTex, uv).r;
                //视点方向越接近法线，UV偏移越小
                float2 offsetuv = vDirTS.xy / vDirTS.z * height * _HeightInt;

                return uv - offsetuv;
            }

            // 陡峭视差映射：射线步进
            float2 SPM(float2 uv, float3 vDirTS)
            {
                // 高度层数
                // 分层数由视点方向与法向夹角决定，视点方向和法线越靠近 采样偏离越小，就可以采用较少的分层
                float minLayers = 20;
                float maxLayers = 100;
                float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0.0, 0.0 ,1.0), vDirTS)));
                // 每层高度
                float layerHeight = 1.0 / numLayers;
                // 当前层高度
                float currentLayerHeight = 0.0;
                // 视点方向偏移量
                float2 offsetuv = vDirTS.xy / vDirTS.z * _HeightInt;
                // 每层高度偏移量
                float2 deltauv = offsetuv / numLayers;
                // 当前uv
                float2 currentuv = uv;
                // 用当前uv采样高度图
                float currentHeight = tex2D(_HeightTex, currentuv).r;

                while(currentLayerHeight < currentHeight)
                {
                    // 按层高进行uv偏移
                    currentuv += deltauv;
                    // 重采高度
                    currentHeight = tex2Dlod(_HeightTex, float4(currentuv, 0, 0)).r;
                    // 采样点高度
                    currentLayerHeight += layerHeight;
                }
                return currentuv;
            }

            // 浮雕映射：射线步进+二分查找
            float2 ReliefMapping(float2 uv, float3 vDirTS)
            {
                // 高度层数
                // 分层数由视点方向与法向夹角决定，视点方向和法线越靠近 采样偏离越小，就可以采用较少的分层
                float minLayers = 20;
                float maxLayers = 100;
                float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0.0, 0.0 ,1.0), vDirTS)));
                // 每层高度
                float layerHeight = 1.0 / numLayers;
                // 当前层高度
                float currentLayerHeight = 0.0;
                // 视点方向偏移量
                float2 offsetuv = vDirTS.xy / vDirTS.z * _HeightInt;
                // 每层高度偏移量
                float2 deltauv = offsetuv / numLayers;
                // 当前uv
                float2 currentuv = uv;
                // 用当前uv采样高度图
                float currentHeight = tex2D(_HeightTex, currentuv).r;

                while(currentLayerHeight < currentHeight)
                {
                    // 按层高进行uv偏移
                    currentuv += deltauv;
                    // 重采高度
                    currentHeight = tex2Dlod(_HeightTex, float4(currentuv, 0, 0)).r;
                    // 采样点高度
                    currentLayerHeight += layerHeight;
                }
                // 二分查找
                float2 T0 = currentuv - deltauv, T1 = currentuv;
                for (int i = 0; i < 20; i++)
                {
                    currentHeight = tex2D(_HeightTex, (T0 + T1) / 2).r;
                    currentLayerHeight = length((T0 + T1) / 2) / length(offsetuv);
                    if (currentHeight < currentLayerHeight)
                    {
                        T0 = (T0 + T1) / 2;
                    }
                    else
                    {
                        T1 = (T0 + T1) / 2;
                    }
                }
                return (T0 + T1) / 2;
            }

            // 视差遮蔽映射：射线步进+线性插值
            float2 POM(float2 uv, float3 vDirTS)
            {
                // 高度层数
                // 分层数由视点方向与法向夹角决定，视点方向和法线越靠近 采样偏离越小，就可以采用较少的分层
                float minLayers = 20;
                float maxLayers = 100;
                float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0.0, 0.0 ,1.0), vDirTS)));
                // 每层高度
                float layerHeight = 1.0 / numLayers;
                // 当前层高度
                float currentLayerHeight = 0.0;
                // 视点方向偏移量
                float2 offsetuv = vDirTS.xy / vDirTS.z * _HeightInt;
                // 每层高度偏移量
                float2 deltauv = offsetuv / numLayers;
                // 当前uv
                float2 currentuv = uv;
                // 用当前uv采样高度图
                float currentHeight = tex2D(_HeightTex, currentuv).r;

                while(currentLayerHeight < currentHeight)
                {
                    // 按层高进行uv偏移
                    currentuv += deltauv;
                    // 重采高度
                    currentHeight = tex2Dlod(_HeightTex, float4(currentuv, 0, 0)).r;
                    // 采样点高度
                    currentLayerHeight += layerHeight;
                }

                // 前一个采样点
                float2 preuv = currentuv - deltauv;
                // 线性插值
                float afterHeight = currentHeight - currentLayerHeight;
                float beforeHeight = tex2D(_HeightTex, preuv).r - (currentLayerHeight - layerHeight);
                float weight = afterHeight / (afterHeight - beforeHeight);
                float2 finaluv = preuv * weight + currentuv * (1 - weight);
                
                return finaluv;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 向量准备
                half3x3 TBN = half3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                half3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                half3 vDirTS = normalize(mul(TBN, vDirWS));

                // 视差映射
                #if _BMP_PARALLAXMAPPING
                float2 pm_uv = ParallaxMapping(i.uv0, vDirTS);
                #elif _BMP_SPM
                float2 pm_uv = SPM(i.uv0, vDirTS);
                #elif _BMP_RELIEFMAPPING
                float2 pm_uv = ReliefMapping(i.uv0, vDirTS);
                #elif _BMP_POM
                float2 pm_uv = POM(i.uv0, vDirTS);
                #endif

                half3 nDirTS = UnpackNormal(tex2D(_NormalTex, pm_uv)).xyz;
                half3 nDirWS = normalize(lerp(i.nDirWS, mul(nDirTS, TBN), _NormalInt));
                half3 lDirWS = normalize(_WorldSpaceLightPos0.xyz);
                half3 hDirWS = normalize(lDirWS + vDirWS);
                half3 rDirWS = normalize(reflect(-lDirWS, nDirWS));

                half NdotL = dot(nDirWS, lDirWS);
                half NdotH = dot(nDirWS, hDirWS);
                half VdotR = dot(vDirWS, rDirWS);

                // 光照模型
                // 环境光
                half4 albedo = tex2D(_MainTex, pm_uv) * _MainCol;
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _DiffuseCol * albedo.rgb;

                half3 diffuse = _LightColor0.rgb * albedo * max(0, NdotL);
                half3 specular = _LightColor0.rgb * _SpecularCol.rgb * pow(max(0, NdotH), _Gloss);

                half3 finalCol = ambient + diffuse + specular;

                return half4 (finalCol, 1.0);
            }
            ENDCG
        }
    }
}
