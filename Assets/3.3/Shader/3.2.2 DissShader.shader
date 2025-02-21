Shader "Unlit/DissShader"
{
    Properties
    {
        _MainTex            ("MainTex", 2D)                        = "white"{}
        _DisplacementMap    ("位移贴图", 2D)                        = "gray"{}
        _DisplacementInt    ("位移强度", Range(0.0, 1.0))           = 0
        _SpecularPow        ("光滑度", Range(0, 60))                = 30
        _TessellationUniform("Tessellation Uniform", Range(1, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque"
               "LightMode"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            // 定义2个函数 hull domain
            #pragma hull hullProgram
            #pragma domain ds

            // #pragma vertex vert
            #pragma vertex tessvert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            // 曲面细分头文件
            #include "Tessellation.cginc"

            #pragma target 5.0

            // 在 HLSL 中，内置的normal有特定的用途，有时会与编译器的期望不一致，尤其是在 Tessellation 的情景中, 这里我们不用内置appdata传参
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float4 worldPos : TEXCOORD1;
                half3 TtoW0 : TEXCOORD2;
                half3 TtoW1 : TEXCOORD3;
                half3 TtoW2 : TEXCOORD4;
            };

            sampler2D _MainTex; float4 _MainTex_ST;
            float _TessellationUniform;

            sampler2D _DisplacementMap; float4 _DisplacementMap_ST;
            float _DisplacementInt;
            float _SpecularPow;

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 顶点着色器 用tex2Dlod来读取图片，z分量为0，w分量为mipmap的level 这里取0; g通道代表位移强度
                float displacement = tex2Dlod(_DisplacementMap, float4(o.uv.xy, 0.0, 0.0)).g;
                // remap[0,1] → [-0.5,0.5]
                displacement = (displacement - 0.5) * _DisplacementInt;
                // normal只用于顶点变换，可以不传递
                v.normal = normalize(v.normal);
                // 计算沿着法线方向的位移量，再加回去
                v.vertex.xyz += v.normal * displacement;

                o.pos = UnityObjectToClipPos(v.vertex);
                // 单独传递
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                // 构造TBN矩阵
                half3 nDirWS = UnityObjectToWorldNormal(v.normal);
                half3 tDirWS = UnityObjectToWorldDir(v.tangent.xyz);
                half3 bDirWS = cross(nDirWS, tDirWS) * v.tangent.w; //可以再 * unity_WorldTransformParams.w, 保切线空间的正确性，特别是在模型缩放（尤其是负缩放）时
                // 定义domain ds, 不支持float4, worldPos在前面单独传递
                o.TtoW0 = float3(tDirWS.x, bDirWS.x, nDirWS.x);
                o.TtoW1 = float3(tDirWS.y, bDirWS.y, nDirWS.y);
                o.TtoW2 = float3(tDirWS.z, bDirWS.z, nDirWS.z);

                return o;
            }

            // 有些硬件不支持曲面细分着色器，定义这个宏能够不报错
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                //顶点着色器结构的定义
                struct TessVertex{
                    float4 vertex : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 uv : TEXCOORD0;
                };
                
                struct OutputPatchConstant{
                    // 不同图元，该结构会有不同
                    // 该部分用于Hull Shader里面
                    // 定义了patch的属性
                    // Tessellation Factor, 多边形边数
                    float edge[3] : SV_TESSFACTOR;
                    // Inner Tessllation Factor
                    float inside  : SV_INSIDETESSFACTOR;
                };

                TessVertex tessvert (appdata v){
                    // 顶点着色器函数
                    TessVertex o;
                    o.vertex = v.vertex;
                    o.normal = v.normal;
                    o.tangent = v.tangent;
                    o.uv = v.uv;
                    return o;
                }

                OutputPatchConstant hsconst (InputPatch<TessVertex,3> patch){
                    // 定义曲面细分的参数
                    OutputPatchConstant o;
                    o.edge[0] = _TessellationUniform;
                    o.edge[1] = _TessellationUniform;
                    o.edge[2] = _TessellationUniform;
                    o.inside  = _TessellationUniform;
                    return o;
                }

                [UNITY_domain("tri")]                   //确定图元，quad，triangle等
                [UNITY_partitioning("fractional_odd")]  //拆分edge的规则，equal_spacing，fractional_odd，fractional_ever
                [UNITY_outputtopology("triangle_cw")]
                [UNITY_patchconstantfunc("hsconst")]    //一个patch共三个点，三点共用这个函数
                [UNITY_outputcontrolpoints(3)]          //不同图元对应不同的控制点

                TessVertex hullProgram (InputPatch<TessVertex,3> patch,uint id : SV_OutputControlPointID){
                    // 定义hullshaderV函数
                    return patch[id];
                }

                [UNITY_domain("tri")]   //同样需要定义图元

                v2f ds (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3>patch,float3 bary : SV_DOMAINLOCATION)
                // bary重心坐标
                {
                    appdata v;
                    v.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
                    v.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
                    v.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
                    v.uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;
                    
                    v2f o = vert (v);
                    return o;
                }
            #endif

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = i.worldPos.xyz;
                float3 lDir = normalize(UnityWorldSpaceLightDir(worldPos));
                float3 vDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 hDir = normalize(lDir + vDir);
                float3 tnormal = UnpackNormal(tex2D(_DisplacementMap, i.uv));
                half3  nDirWS = normalize(half3(dot(i.TtoW0, tnormal), dot(i.TtoW1, tnormal), dot(i.TtoW2, tnormal)));

                float3 LdotN = max(0, dot(lDir, nDirWS));
                float3 NdotH = dot(nDirWS, hDir);

                float3 albedo = tex2D(_MainTex, i.uv).rgb;
                float3 lightColor = _LightColor0.rgb;

                float3 diffuse = albedo * lightColor * LdotN;
                float3 specular = albedo * pow(NdotH, _SpecularPow);

                float3 finalCol = diffuse + specular;

                return float4(finalCol, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}