Shader "Shader/Portal"
{
    Properties
    {
        [Header(Glass)]
        // ������
        _MainTex     ("Main Texture", 2D)                   = "white" {}
        _ColorInt    ("Main Texture Tint", Range(0.0, 1.0)) = 0.5
        // ��͹��ͼ
        _BumpMap     ("Bumpmap", 2D)                        = "bump" {}
        _BumpInt     ("Bumpmap Intensity", Range(0, 64))    = 10
        // �Ŷ�
        _NoiseTex    ("Noise Texture", 2D)                  = "bump" {}
        _NoiseInt    ("Distort Intensity", Range(0.0, 1.0)) = 0.5

        _GlassColor  ("Glass Color", Color)                 = (1, 1, 1, 1)
        _Transparency("Transparency", Range(0.0, 1.0))      = 0.5

        [Header(Border)]
        _BorderSize         ("Border Size", Range(0.0, 0.05))        = 0.01
  [HDR] _BorderColor        ("Border Color", Color)                  = (0.0, 0.0, 0.0, 1.0)
        _BorderTransparency ("Border Transparency", Range(0.0, 1.0)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite On
        //ZTest LEqual
        // unity������Ӱshader��������������Ϣ��Ⱦ����Ӱ��ͼ��
		UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"

        Pass
        {
            Name"BASE"
            Tags {"LightMode"="Always" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex    : SV_POSITION;
                float2 uvmain    : TEXCOORD0;
                float2 uvbump    : TEXCOORD1;
                float2 uvdistort : TEXCOORD2;
                float4 uvgrab    : TEXCOORD3;
            };

            // Glass
            sampler2D _MainTex;    float4 _MainTex_ST;
            float     _ColorInt;
            sampler2D _BumpMap;    float4 _BumpMap_ST;
            float     _BumpInt;
            sampler2D _NoiseTex;   float4 _NoiseTex_ST;
            float     _NoiseInt;
            fixed4    _GlassColor;
            float     _Transparency;
            // Border
            float     _BorderSize;
            float4    _BorderColor;
            float     _BorderTransparency;

            // �������ɾ��εĺ���
            /*
            UV * 2 - 1����UV�����[0, 1]��Χת����[-1, 1]��Χ��
            abs(...)��ȡ����ֵ��ʹ������ֵ��[-1, 1]��Χ�ڶԳơ�
            - float2(Width, Height)����ȥ���εĿ�Ⱥ͸߶ȣ��õ�������α߽�ľ��롣

            fwidth(d)������d����Ļ�ռ��еĵ��������ڿ���ݴ���fwidthͨ������d��x��y�����ϵĵ���֮�͡�
            d / fwidth(d)��������d��һ����ʹ�þ���ĵ�λ����Ļ������ء�
            1 - ...��������ת��Ϊһ����1��0�Ľ���ֵ������Խ��ֵԽ�󣬾���ԽԶֵԽС��

            min(d.x, d.y)��ȡd.x��d.y�еĽ�Сֵ����ʾ������α߽����С���롣
            saturate(...)�������������[0, 1]��Χ�ڣ�ȷ�����ֵ���ᳬ�������Χ��
            */
            void Unity_Rectangle_float(float2 UV, float Width, float Height, out float Out)
            {
                float2 d = abs(UV * 2 - 1) - float2(Width, Height);
                d = 1 - d / fwidth(d);
                Out = saturate(min(d.x, d.y));
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uvbump = TRANSFORM_TEX(v.uv, _BumpMap);
                o.uvmain = TRANSFORM_TEX(v.uv, _MainTex);
                o.uvdistort = TRANSFORM_TEX(v.uv, _NoiseTex);
                // ���ƽ̨����
                #if UNITY_UV_STARTS_AT_TOP
                float scale = -1.0;
                #else
                float scale = 1.0;
                #endif
                // ������ü��ռ��µ����꣬����NDC�ռ��ϵ�λ�ú�ӳ�䵽ģ�������uv
                o.uvgrab.xy = (float2 (o.vertex.x, o.vertex.y * scale) + o.vertex.w) * 0.5;
                o.uvgrab.zw = o.vertex.zw;
                return o;
            }

            // ץ���õ���ģ������ḳֵ����
            sampler2D _GrabBlurTexture;
            float4    _GrabBlurTexture_TexelSize;

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed2 distort = (tex2D(_NoiseTex, i.uvdistort).xy * 2 - 1) * _NoiseInt;
                fixed2 distortUV = i.uvmain + distort;
                fixed4 glassCol = tex2D(_MainTex, distortUV) * _GlassColor;
                glassCol = fixed4(glassCol.rgb, _Transparency);

                // ���㷽��mask
                float rectangleMask;
                float borderSize = 1 - _BorderSize;
                Unity_Rectangle_float(i.uvmain, borderSize, borderSize, rectangleMask);
                rectangleMask = 1 - rectangleMask;
                fixed4 borderColor = _BorderColor * rectangleMask * _BorderTransparency;

                // ģ��
                half2 bump = UnpackNormal(tex2D(_BumpMap, i.uvbump)).rg;
                float2 offset = bump * _BumpInt * _GrabBlurTexture_TexelSize.xy;
                i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
                half4 col = tex2Dproj(_GrabBlurTexture, UNITY_PROJ_COORD(i.uvgrab));

                fixed4 finalCol = lerp(col, glassCol, _ColorInt) + borderColor;
                return finalCol;
            }
            ENDCG
        }
    }
}
