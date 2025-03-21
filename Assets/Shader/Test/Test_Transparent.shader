Shader "Advanced Hair Shader Pack/Aniso_Transparent" {
	Properties{
	_MainTex("Diffuse (RGB) Alpha (A)", 2D) = "white" {}
	_Color("Main Color", Color) = (1,1,1,1)
        _Cutoff("Alpha Cut-Off Threshold", float) = 0.95

	}
		SubShader{
		UsePass "Hidden/Test_Opaque/OPAQUE"

		Cull off
		ZWrite off

		 Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" "ForceNoShadowCasting" = "True" }

		CGPROGRAM

                 #include "Lighting.cginc"
                 #pragma surface surf Lambert  alpha:auto 
                #pragma target 3.0

         struct Input
	{
	 float2 uv_MainTex;
         float3 viewDir;
	};
       sampler2D _MainTex;
	float _Cutoff;
	fixed4  _Color;
        void surf(Input IN, inout SurfaceOutput o)
	{
		fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);
		o.Albedo = albedo.rgb*_Color.rgb;
		o.Alpha = saturate(albedo.a / (_Cutoff + 0.0001));
		clip(albedo.a - 0.0001);
	}

	ENDCG

	}


}