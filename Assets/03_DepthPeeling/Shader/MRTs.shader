Shader "Unlit/MRTs"
{
    Properties
    {
        _MainTex ("Texture", 2D)  = "white" {}
        _Color   ("Color", Color) = (1, 0, 0, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "autolight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 color : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                SHADOW_COORDS(3)
            };

            // �Զ���ṹ�壬���Է��ض����ȾĿ��, ����ÿ����ȾĿ��ᱻӳ�䵽һ����ȾĿ��ۣ�SV_Target0, SV_Target1 �ȣ�
            struct fout
            {
                float4 rt0 : SV_Target0;
                float4 rt1 : SV_Target1;
            };

            sampler2D _MainTex; float4 _MainTex_ST;
            float4 _Color;

            uniform sampler2D DepthRendered;
            uniform int DepthRenderedIndex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = v.normal;

                // ������
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // �����ߴӶ���ռ�ת��������ռ䣬��������ά��������ȡ_World2Objectǰ����
                fixed3 worldNormal = normalize(mul((float3x3) unity_ObjectToWorld, v.normal));
                // �ⷽ��
                fixed3 lDirWS = normalize(_WorldSpaceLightPos0.xyz);
                // ���������
                fixed3 diffuse = _LightColor0.rgb * saturate(dot(worldNormal, lDirWS));
                o.color = ambient + diffuse;

                o.screenPos = ComputeScreenPos(o.vertex);
                TRANSFER_SHADOW(o)
                return o;
            }

            fout frag (v2f i)
            {
                float depth = i.vertex.z / i.vertex.w;
                fixed shadow = SHADOW_ATTENUATION(i);
                half4 col = tex2D(_MainTex, i.uv) * _Color * shadow;
                col.rgb *= i.color;
                clip(col.a - 0.001);
                float renderDepth = tex2D(DepthRendered, i.screenPos.xy / i.screenPos.w).r;
                if (DepthRenderedIndex > 0 && depth >= renderDepth - 0.000001) discard;
                
                fout o;
                // �����ֵ����ɫ�ֱ������������ȾĿ����
                o.rt0 = depth;
                o.rt1 = col;
                return o;
            }
            ENDCG
        }
    }
}
