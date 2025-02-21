Shader "Unlit/Tessellation"
{
    Properties
    {
        _TessellationUniform("Tessellation Uniform", Range(1, 10)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            // ����2������ hull domain
            #pragma hull hullProgram
            #pragma domain ds

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
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.tangent = v.tangent;
                o.normal = v.normal;
                return o;
            }

            // ��ЩӲ����֧������ϸ����ɫ��������������ܹ�������
            #ifdef UNITY_CAN_COMPILE_TESSELLATION
                //������ɫ���ṹ�Ķ���
                struct TessVertex{
                    float4 vertex : INTERNALTESSPOS;
                    float3 normal : NORMAL;
                    float4 tangent : TANGENT;
                    float2 uv : TEXCOORD0;
                };
                
                struct OutputPatchConstant{
                    // ��ͬͼԪ���ýṹ���в�ͬ
                    // �ò�������Hull Shader����
                    // ������patch������
                    // Tessellation Factor, ����α���
                    float edge[3] : SV_TESSFACTOR;
                    // Inner Tessllation Factor
                    float inside  : SV_INSIDETESSFACTOR;
                };

                TessVertex tessvert (appdata v){
                    // ������ɫ������
                    TessVertex o;
                    o.vertex = v.vertex;
                    o.normal = v.normal;
                    o.tangent = v.tangent;
                    o.uv = v.uv;
                    return o;
                }

                float _TessellationUniform;

                OutputPatchConstant hsconst (InputPatch<TessVertex,3> patch){
                    // ��������ϸ�ֵĲ���
                    OutputPatchConstant o;
                    o.edge[0] = _TessellationUniform;
                    o.edge[1] = _TessellationUniform;
                    o.edge[2] = _TessellationUniform;
                    o.inside  = _TessellationUniform;
                    return o;
                }

                [UNITY_domain("tri")]                   //ȷ��ͼԪ��quad��triangle��
                [UNITY_partitioning("fractional_odd")]  //���edge�Ĺ���equal_spacing��fractional_odd��fractional_ever
                [UNITY_outputtopology("triangle_cw")]
                [UNITY_patchconstantfunc("hsconst")]    //һ��patch�������㣬���㹲���������
                [UNITY_outputcontrolpoints(3)]          //��ͬͼԪ��Ӧ��ͬ�Ŀ��Ƶ�

                TessVertex hullProgram (InputPatch<TessVertex,3> patch,uint id : SV_OutputControlPointID){
                    // ����hullshaderV����
                    return patch[id];
                }

                [UNITY_domain("tri")]   //ͬ����Ҫ����ͼԪ

                v2f ds (OutputPatchConstant tessFactors, const OutputPatch<TessVertex,3>patch,float3 bary : SV_DOMAINLOCATION)
                // bary��������
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
                return float4(1.0, 1.0, 1.0, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
