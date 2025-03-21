Shader "ConstraintDepth_Transparent"
{
    Properties
    {
        _MainTex ("Diffuse(RGB) Alpha(A)", 2D)      = "white" {}
        _Color   ("Diffuse Color", Color)           = (1, 1, 1, 1)
        _Cutoff  ("Alpha Cut-off Threshold", Range(0.001, 1.0)) = 0.7
    }
    SubShader
    {
        UsePass "Hidden/ConstraintDepth_Opaque/OPAQUE"
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" "ForceNoShadowCasting"="True" }
        Cull Off
        ZWrite Off

            CGPROGRAM
            #pragma surface surf Lambert  alpha:auto
            #include "UnityCG.cginc"
            #pragma target 3.0

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Input
            {
                float2 uv_MainTex;
                float3 viewDir;
            };

            sampler2D _MainTex;
            half4 _Color;
            float _Cutoff;

            //没有显式的返回值，但通过 inout SurfaceOutput o 参数 直接修改 Surface Shader 的输出数据
            void surf(Input IN, inout SurfaceOutput o)
            {
                fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);
                o.Albedo = albedo.rgb * _Color.rgb;
                //albedo.a 大于 _Cutoff 时，不透明; albedo.a 小于 _Cutoff 时，半透明
                o.Alpha = saturate(albedo.a / (_Cutoff + 0.0001));
                clip(albedo.a - 0.0001);    //a很低的地方直接不算颜色
            }
            ENDCG
    }
}
