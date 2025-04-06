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
            // ����2������ hull domain
            #pragma hull hull
            #pragma domain domain

            // #pragma vertex vert
            #pragma vertex tessvert
            #pragma fragment frag

            #include "UnityCG.cginc"
            // ����ϸ��ͷ�ļ�
            #include "Tessellation.cginc"

            #pragma target 5.0

            // �� HLSL �У����õ�normal���ض�����;����ʱ�����������������һ�£��������� Tessellation ���龰��, �������ǲ�������appdata����
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
                
                // ���ݻҶȽ��ж���ƫ�ƣ�ѩ���� -= ���ƣ�
                v.vertex.xyz -= v.normal * (_BaseTex_var.r - 0.7 + _MaskTex_var.r) * _BumpInt;

                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            // ��ЩӲ����֧������ϸ����ɫ��������������ܹ�������
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                //������ɫ���ṹ�Ķ���
                struct TessVertex{
                    float4 vertex  : INTERNALTESSPOS;
                    float3 normal  : NORMAL;
                    float4 tangent : TANGENT;
                    float2 uv      : TEXCOORD0;
                };
                
                struct OutputPatchConstant{
                    // ��ͬͼԪ���ýṹ���в�ͬ
                    // �ò�������Hull Shader����
                    // ������patch������
                    // Tessellation Factor, ����α���
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
                    // ������ɫ������
                    TessVertex o;
                    o.vertex = v.vertex;
                    o.normal = v.normal;
                    o.tangent = v.tangent;
                    o.uv = v.uv;
                    return o;
                }

                // ���ھ����ϸ�֣�Unity������
                float4 Tessellation(TessVertex v, TessVertex v1, TessVertex v2)
                {
                    float minDist = 1.0;
                    float maxDist = 25.0;
                    return UnityDistanceBasedTess(v.vertex, v1.vertex, v2.vertex, minDist, maxDist, _TessellationUniform);
                }
                // ����ϸ��ǿ��
                float Tessellation(TessVertex v)
                {
                    return _TessellationUniform;
                }

                OutputPatchConstant hullconst (InputPatch<TessVertex,3> patch){
                    // ��������ϸ�ֵĲ���
                    OutputPatchConstant o;
                    UNITY_INITIALIZE_OUTPUT(OutputPatchConstant, o);
                    float4 ts = Tessellation(patch[0], patch[1], patch[2]);
                    o.edge[0] = ts.x;
                    o.edge[1] = ts.y;
                    o.edge[2] = ts.z;
                    o.inside  = ts.w;
                    return o;
                }

                [UNITY_domain("tri")]                   //ȷ��ͼԪ��quad��triangle��
                [UNITY_partitioning("fractional_odd")]  //���edge�Ĺ���equal_spacing��fractional_odd��fractional_ever
                [UNITY_outputtopology("triangle_cw")]
                [UNITY_patchconstantfunc("hullconst")]    //һ��patch�������㣬���㹲���������
                [UNITY_outputcontrolpoints(3)]          //��ͬͼԪ��Ӧ��ͬ�Ŀ��Ƶ�

                TessVertex hull (InputPatch<TessVertex,3> patch,uint id : SV_OutputControlPointID){
                    // ����hullshaderV����
                    return patch[id];
                }

                [UNITY_domain("tri")]   //ͬ����Ҫ����ͼԪ

                v2f domain (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3> patch, float3 bary : SV_DOMAINLOCATION)
                // bary��������
                {
                    appdata v;
                    // ʹ�õ���������Ϣ����Ҫ���룬��������������Ǵ��
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
                // ��Mask��ֵ
                float4 c = lerp(SnowCol_var, BaseTex_var, MaskTex_var.r);

                float3 finalCol = c.xyz;
                return float4(finalCol, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
