Shader "Unlit/Snow"
{
    Properties
    { 
        _TessellationUniform ("Tessellation Uniform", Float) = 10
        _BaseTex    ("Base Texture", 2D) = "white"{}
        _SnowTex    ("Snow Texture", 2D) = "white"{}
        _BumpInt    ("Bump Intensity", Float) = 0.2
        _BaseCol    ("Base Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _MaskTex    ("Mask Texture", 2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase"}
        LOD 100

        Pass
        {
            CGPROGRAM
            // 定义2个函数 hull domain
            #pragma hull hull
            #pragma domain domain

            // #pragma vertex vert
            #pragma vertex tessvert
            #pragma fragment frag

            #include "UnityCG.cginc"
            // 曲面细分头文件
            #include "Tessellation.cginc"

            #pragma target 5.0

            // 在 HLSL 中，内置的normal有特定的用途，有时会与编译器的期望不一致，尤其是在 Tessellation 的情景中, 这里我们不用内置appdata传参
            struct appdata
            {
                float4 vertex  : POSITION;
                float2 uv      : TEXCOORD0;
                float3 normal  : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv      : TEXCOORD0;
                float4 vertex  : SV_POSITION;
                float3 nDir    : TEXCOORD1;
                float4 uv_base : TEXCOORD2;
                float4 uv_snow : TEXCOORD3;
            };

            float     _TessellationUniform;
            sampler2D _BaseTex;
            sampler2D _SnowTex;
            float     _BumpInt;
            float4    _BaseCol;
            sampler2D _MaskTex;     float4 _MaskTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.uv = v.uv;
                o.nDir = UnityObjectToWorldNormal(v.normal);
                
                float4 _MaskTex_var = tex2Dlod(_MaskTex, float4(o.uv, 0.0, 0));
                float4 _BaseTex_var = tex2Dlod(_BaseTex, float4(o.uv, 0.0, 0));
                
                // 根据灰度进行顶点偏移（雪地用 -= 下移）
                v.vertex.xyz -= v.normal * (_BaseTex_var.r - 0.7 + _MaskTex_var.r) * _BumpInt;

                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            // 有些硬件不支持曲面细分着色器，定义这个宏能够不报错
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                //顶点着色器结构的定义
                struct TessVertex{
                    float4 vertex  : INTERNALTESSPOS;
                    float3 normal  : NORMAL;
                    float4 tangent : TANGENT;
                    float2 uv      : TEXCOORD0;
                };
                
                struct OutputPatchConstant{
                    // 不同图元，该结构会有不同
                    // 该部分用于Hull Shader里面
                    // 定义了patch的属性
                    // Tessellation Factor, 多边形边数
                    float edge[3] : SV_TESSFACTOR;
                    // Inner Tessllation Factor
                    float inside  : SV_INSIDETESSFACTOR;

                    float3 vTangent[4] : TANGENT;
                    float2 vUV[4]      : TEXCOORD;
                    float3 vTanUCorner[4] : TANUCORNER;
                    float3 vTanVCorner[4] : TANVCORNER;
                    float4 vCWts          : TANWEIGHTS;  
                };

                TessVertex tessvert (appdata v)
                {
                    // 顶点着色器函数
                    TessVertex o;
                    o.vertex = v.vertex;
                    o.normal = v.normal;
                    o.tangent = v.tangent;
                    o.uv = v.uv;
                    return o;
                }

                // 基于距离的细分（Unity函数）
                float4 Tessellation(TessVertex v, TessVertex v1, TessVertex v2)
                {
                    float minDist = 1.0;
                    float maxDist = 25.0;
                    return UnityDistanceBasedTess(v.vertex, v1.vertex, v2.vertex, minDist, maxDist, _TessellationUniform);
                }
                // 控制细分强度
                float Tessellation(TessVertex v)
                {
                    return _TessellationUniform;
                }

                OutputPatchConstant hullconst (InputPatch<TessVertex,3> patch){
                    // 定义曲面细分的参数
                    OutputPatchConstant o;
                    UNITY_INITIALIZE_OUTPUT(OutputPatchConstant, o);
                    float4 ts = Tessellation(patch[0], patch[1], patch[2]);
                    o.edge[0] = ts.x;
                    o.edge[1] = ts.y;
                    o.edge[2] = ts.z;
                    o.inside  = ts.w;
                    return o;
                }

                [UNITY_domain("tri")]                   //确定图元，quad，triangle等
                [UNITY_partitioning("fractional_odd")]  //拆分edge的规则，equal_spacing，fractional_odd，fractional_ever
                [UNITY_outputtopology("triangle_cw")]
                [UNITY_patchconstantfunc("hullconst")]    //一个patch共三个点，三点共用这个函数
                [UNITY_outputcontrolpoints(3)]          //不同图元对应不同的控制点

                TessVertex hull (InputPatch<TessVertex,3> patch,uint id : SV_OutputControlPointID){
                    // 定义hullshaderV函数
                    return patch[id];
                }

                [UNITY_domain("tri")]   //同样需要定义图元

                v2f domain (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3> patch, float3 bary : SV_DOMAINLOCATION)
                // bary重心坐标
                {
                    appdata v;
                    // 使用到的所有信息都需要传入，不传计算出来的是错的
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
                float4 MaskTex_var = tex2D(_MaskTex, TRANSFORM_TEX(i.uv, _MaskTex));
                float4 BaseTex_var = tex2D(_BaseTex, i.uv) * _BaseCol;
                float4 SnowCol_var = tex2D(_SnowTex, i.uv);
                // 用Mask插值
                float4 c = lerp(SnowCol_var, BaseTex_var, MaskTex_var.r);

                float3 finalCol = c.xyz;
                return float4(finalCol, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
