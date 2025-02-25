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

        // 代码中 MAX_SAMPLE_KERNEL_COUNT 替换成32
        #define MAX_SAMPLE_KERNEL_COUNT 32
        sampler2D _MainTex; float4 _MainTex_ST; float4 _MainTex_TexelSize;
        sampler2D _NoiseTex; float4 _NoiseTex_ST;
        // 相机获取
        sampler2D _CameraDepthNormalsTexture;
        float4x4  _InverseProjectionMatrix;
        sampler2D _AOTex;
        // 脚本传参
        float _RangeStrength;
        float _DepthBiasValue;
        float _AOStrength;
        // 采样核
        float  _SampleKernelCount;
        float4 _SampleKernelArray[MAX_SAMPLE_KERNEL_COUNT];  //数组
        float  _SampleKernelRadius;
        // 滤波模糊
        float  _BilaterFilterFactor;
        float2 _BlurRadius;

        // 获取法线
        float3 GetNormal(float2 uv)
        {
            float4 cdn = tex2D(_CameraDepthNormalsTexture,uv);
            return DecodeViewNormalStereo(cdn);
        }
            
        // 比较两个法线向量的相似度, 返回一个结语0到1之间的值
        half CompareNormal(float3 normal1, float3 normal2)
        {
            return smoothstep(_BilaterFilterFactor, 1.0, dot(normal1, normal2));
        }
        
        // 第一步：获得相机空间下的像素方向
        v2f vert_ao (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            float4 clipPos = float4(v.uv * 2 - 1.0, 1.0, 1.0);
            float4 viewVec = mul(_InverseProjectionMatrix, clipPos);    //用投影矩阵的逆矩阵
            o.viewVec = viewVec.xyz / viewVec.w;     // 远裁平面
            return o;
        }
        
        // 第二步：获得深度信息，相乘得到向量
        fixed4 frag_ao (v2f i) : SV_Target
        {
            // 屏幕纹理
            fixed4 col = tex2D(_MainTex, i.uv);
            float3 viewNormal;      // 相机空间下法线方向
            float linear01Depth;    //深度值0-1
            // 获得纹理信息并解码
            float4 depthnormal = tex2D(_CameraDepthNormalsTexture, i.uv);
            DecodeDepthNormal(depthnormal, linear01Depth, viewNormal);
            // 相机空间下像素向量
            float3 viewPos = linear01Depth * i.viewVec;

            // 随机正交基-效果改进 (nDir来自相机)
            viewNormal = normalize(viewNormal) * float3(1, 1, -1);  //相机空间右手坐标系z为负 转过来
            // 噪声纹理缩放
            float2 noiseScale = _ScreenParams.xy / 4.0;
            float2 noiseUV = i.uv * noiseScale;
            // 采样得到随机向量
            float3 randvec = tex2D(_NoiseTex, noiseUV).xyz;
            // TBN
            float3 tangent = normalize(randvec - viewNormal * dot(randvec, viewNormal));
            float3 bitangent = cross(viewNormal, tangent);
            float3x3 TBN = float3x3(tangent, bitangent, viewNormal);

            // 生成采样核心后：从每一个采样位置的深度变化程度累计AO
            float ao = 0;
            int sampleCount = _SampleKernelCount;
            for(int i = 0; i < sampleCount; i++)
            {
                float3 randomVec = mul(_SampleKernelArray[i].xyz, TBN); //采样方向
                float weight = smoothstep(0.2, 0, length(randomVec.xy));//针对不同的采样方向分配权重

                // 采样位置
                float3 randomPos = viewPos + randomVec * _SampleKernelRadius; //相机空间下的采样位置
                float3 rclipPos = mul((float3x3)unity_CameraProjection, randomPos); //相机空间到裁剪空间
                float2 rscreenPos = (rclipPos.xy / rclipPos.z) * 0.5 + 0.5; //裁剪空间到屏幕空间

                float randomDepth;
                float3 randomNormal;
                // 从纹理中读取上述信息
                float4 rcdn = tex2D(_CameraDepthNormalsTexture, rscreenPos);
                DecodeDepthNormal(rcdn, randomDepth, randomNormal);

                // 对比计算AO(优化)
                float range = abs(randomDepth - linear01Depth) * _ProjectionParams.z > _SampleKernelRadius ? 0.0 : 1.0; //深度变化过大的归零 (_ProjectionParams.z 将深度差异从 [0, 1] 范围映射到实际的世界空间距离)
                float sefCheck = randomDepth + _DepthBiasValue < linear01Depth ? 1.0 : 0.0; //深度变化不大判断为平面（防止自阴影伪影）

                ao += range * sefCheck * weight;
            }
            ao = ao / sampleCount;
            ao = max(0.0, 1 - ao * _AOStrength);
            return float4(ao, ao, ao, 1);
        }

        // 双边滤波模糊
        fixed4 frag_blur (v2f i) : SV_Target
        {
            // 采样偏移量
            float2 delta = _MainTex_TexelSize.xy * _BlurRadius.xy;

            // 计算采样纹理坐标，包括左右、上下不同距离的像素
            float2 uv = i.uv;
            float2 uv0a = i.uv - delta;
            float2 uv0b = i.uv + delta;
            float2 uv1a = i.uv - 2.0 * delta;
            float2 uv1b = i.uv + 2.0 * delta;
            float2 uv2a = i.uv - 3.0 * delta;
            float2 uv2b = i.uv + 3.0 * delta;

            // 获取法线信息
            float3 normal = GetNormal(uv);
            float3 normal0a = GetNormal(uv0a);
            float3 normal0b = GetNormal(uv0b);
            float3 normal1a = GetNormal(uv1a);
            float3 normal1b = GetNormal(uv1b);
            float3 normal2a = GetNormal(uv2a);
            float3 normal2b = GetNormal(uv2b);

            // 采样
            fixed4 col = tex2D(_MainTex, uv);
            fixed4 col0a = tex2D(_MainTex, uv0a);
            fixed4 col0b = tex2D(_MainTex, uv0b);
            fixed4 col1a = tex2D(_MainTex, uv1a);
            fixed4 col1b = tex2D(_MainTex, uv1b);
            fixed4 col2a = tex2D(_MainTex, uv2a);
            fixed4 col2b = tex2D(_MainTex, uv2b);

            // 计算权重: 素法线的相似度*固定的权重系数
            half w = 0.37004405286; //当前像素权重值
            half w0a = CompareNormal(normal, normal0a) * 0.31718061674;
            half w0b = CompareNormal(normal, normal0b) * 0.31718061674;
            half w1a = CompareNormal(normal, normal1a) * 0.19823788546;
            half w1b = CompareNormal(normal, normal1b) * 0.19823788546;
            half w2a = CompareNormal(normal, normal2a) * 0.11453744493;
            half w2b = CompareNormal(normal, normal2b) * 0.11453744493;

            // 加权求和
            half3 result;
            result = w * col.rgb;
            result += w0a * col0a.rgb;
            result += w0b * col0b.rgb;
            result += w1a * col1a.rgb;
            result += w1b * col1b.rgb;
            result += w2a * col2a.rgb;
            result += w2b * col2b.rgb;

            // 归一化结果 (除以所有权重和)
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
