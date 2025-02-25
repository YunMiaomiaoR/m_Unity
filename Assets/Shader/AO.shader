Shader "AO/ScreenSpaceAOEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "black" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off
        ZWrite Off
        ZTest Always

        CGINCLUDE
        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv     : TEXCOORD0;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 uv     : TEXCOORD0;
            float3 viewVec: TEXCOORD1;
        };

        // ������ MAX_SAMPLE_KERNEL_COUNT �滻��32
        #define MAX_SAMPLE_KERNEL_COUNT 32
        sampler2D _MainTex; float4 _MainTex_ST; float4 _MainTex_TexelSize;
        sampler2D _NoiseTex; float4 _NoiseTex_ST;
        // �����ȡ
        sampler2D _CameraDepthNormalsTexture;
        float4x4  _InverseProjectionMatrix;
        sampler2D _AOTex;
        // �ű�����
        float _RangeStrength;
        float _DepthBiasValue;
        float _AOStrength;
        // ������
        float  _SampleKernelCount;
        float4 _SampleKernelArray[MAX_SAMPLE_KERNEL_COUNT];  //����
        float  _SampleKernelRadius;
        // �˲�ģ��
        float  _BilaterFilterFactor;
        float2 _BlurRadius;

        // ��ȡ����
        float3 GetNormal(float2 uv)
        {
            float4 cdn = tex2D(_CameraDepthNormalsTexture,uv);
            return DecodeViewNormalStereo(cdn);
        }
            
        // �Ƚ������������������ƶ�, ����һ������0��1֮���ֵ
        half CompareNormal(float3 normal1, float3 normal2)
        {
            return smoothstep(_BilaterFilterFactor, 1.0, dot(normal1, normal2));
        }
        
        // ��һ�����������ռ��µ����ط���
        v2f vert_ao (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            float4 clipPos = float4(v.uv * 2 - 1.0, 1.0, 1.0);
            float4 viewVec = mul(_InverseProjectionMatrix, clipPos);    //��ͶӰ����������
            o.viewVec = viewVec.xyz / viewVec.w;     // Զ��ƽ��
            return o;
        }
        
        // �ڶ�������������Ϣ����˵õ�����
        fixed4 frag_ao (v2f i) : SV_Target
        {
            // ��Ļ����
            fixed4 col = tex2D(_MainTex, i.uv);
            float3 viewNormal;      // ����ռ��·��߷���
            float linear01Depth;    //���ֵ0-1
            // ���������Ϣ������
            float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);
            DecodeDepthNormal(depthnormal, linear01Depth, viewNormal);
            // ����ռ�����������
            float3 viewPos = linear01Depth * i.viewVec;

            // ���������-Ч���Ľ� (nDir�������)
            viewNormal = normalize(viewNormal) * float3(1, 1, -1);  //����ռ���������ϵzΪ�� ת����
            // ������������
            float2 noiseScale = _ScreenParams.xy / 4.0;
            float2 noiseUV = i.uv * noiseScale;
            // �����õ��������
            float3 randvec = tex2D(_NoiseTex, noiseUV).xyz;
            // TBN
            float3 tangent = normalize(randvec - viewNormal * dot(randvec, viewNormal));
            float3 bitangent = cross(viewNormal, tangent);
            float3x3 TBN = float3x3(tangent, bitangent, viewNormal);

            // ���ɲ������ĺ󣺴�ÿһ������λ�õ���ȱ仯�̶��ۼ�AO
            float ao = 0;
            int sampleCount = _SampleKernelCount;
            for(int i = 0; i < sampleCount; i++)
            {
                float3 randomVec = mul(_SampleKernelArray[i].xyz, TBN); //��������
                float weight = smoothstep(0.2, 0, length(randomVec.xy));//��Բ�ͬ�Ĳ����������Ȩ��

                // ����λ��
                float3 randomPos = viewPos + randomVec * _SampleKernelRadius; //����ռ��µĲ���λ��
                float3 rclipPos = mul((float3x3)unity_CameraProjection, randomPos); //����ռ䵽�ü��ռ�
                float2 rscreenPos = (rclipPos.xy / rclipPos.z) * 0.5 + 0.5; //�ü��ռ䵽��Ļ�ռ�

                float randomDepth;
                float3 randomNormal;
                // �������ж�ȡ������Ϣ
                float4 rcdn = tex2D(_CameraDepthNormalsTexture, rscreenPos);
                DecodeDepthNormal(rcdn, randomDepth, randomNormal);

                // �Աȼ���AO(�Ż�)
                float range = abs(randomDepth - linear01Depth) * _ProjectionParams.z > _SampleKernelRadius ? 0.0 : 1.0; //��ȱ仯����Ĺ��� (_ProjectionParams.z ����Ȳ���� [0, 1] ��Χӳ�䵽ʵ�ʵ�����ռ����)
                float sefCheck = randomDepth + _DepthBiasValue < linear01Depth ? 1.0 : 0.0; //��ȱ仯�����ж�Ϊƽ�棨��ֹ����ӰαӰ��

                ao += range * sefCheck * weight;
            }
            ao = ao / sampleCount;
            ao = max(0.0, 1 - ao * _AOStrength);
            return float4(ao, ao, ao, 1);
        }

        // ˫���˲�ģ��
        fixed4 frag_blur (v2f i) : SV_Target
        {
            // ����ƫ����
            float2 delta = _MainTex_TexelSize.xy * _BlurRadius.xy;

            // ��������������꣬�������ҡ����²�ͬ���������
            float2 uv = i.uv;
            float2 uv0a = i.uv - delta;
            float2 uv0b = i.uv + delta;
            float2 uv1a = i.uv - 2.0 * delta;
            float2 uv1b = i.uv + 2.0 * delta;
            float2 uv2a = i.uv - 3.0 * delta;
            float2 uv2b = i.uv + 3.0 * delta;

            // ��ȡ������Ϣ
            float3 normal = GetNormal(uv);
            float3 normal0a = GetNormal(uv0a);
            float3 normal0b = GetNormal(uv0b);
            float3 normal1a = GetNormal(uv1a);
            float3 normal1b = GetNormal(uv1b);
            float3 normal2a = GetNormal(uv2a);
            float3 normal2b = GetNormal(uv2b);

            // ����
            fixed4 col = tex2D(_MainTex, uv);
            fixed4 col0a = tex2D(_MainTex, uv0a);
            fixed4 col0b = tex2D(_MainTex, uv0b);
            fixed4 col1a = tex2D(_MainTex, uv1a);
            fixed4 col1b = tex2D(_MainTex, uv1b);
            fixed4 col2a = tex2D(_MainTex, uv2a);
            fixed4 col2b = tex2D(_MainTex, uv2b);

            // ����Ȩ��: �ط��ߵ����ƶ�*�̶���Ȩ��ϵ��
            half w = 0.37004405286; //��ǰ����Ȩ��ֵ
            half w0a = CompareNormal(normal, normal0a) * 0.31718061674;
            half w0b = CompareNormal(normal, normal0b) * 0.31718061674;
            half w1a = CompareNormal(normal, normal1a) * 0.19823788546;
            half w1b = CompareNormal(normal, normal1b) * 0.19823788546;
            half w2a = CompareNormal(normal, normal2a) * 0.11453744493;
            half w2b = CompareNormal(normal, normal2b) * 0.11453744493;

            // ��Ȩ���
            half3 result;
            result = w * col.rgb;
            result += w0a * col0a.rgb;
            result += w0b * col0b.rgb;
            result += w1a * col1a.rgb;
            result += w1b * col1b.rgb;
            result += w2a * col2a.rgb;
            result += w2b * col2b.rgb;

            // ��һ����� (��������Ȩ�غ�)
            result /= w + w0a + w0b + w1a + w1b + w2a + w2b;
            return fixed4(result, 1.0);
        }
        
        fixed4 frag_composite (v2f i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv);
            fixed ao = tex2D(_AOTex, i.uv).r;
            col.rgb *= ao;
            return col;
        }
        ENDCG


        // Pass0 : Generate AO
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_ao
            #pragma fragment frag_ao
            ENDCG
        }

        // Pass1 : Bilateral Filter Blur
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_ao
            #pragma fragment frag_blur
            ENDCG
        }

        // Pass2 : Composite AO
        Pass
        {
            CGPROGRAM
            #pragma vertex vert_ao
            #pragma fragment frag_composite
            ENDCG
        }
    }
}
