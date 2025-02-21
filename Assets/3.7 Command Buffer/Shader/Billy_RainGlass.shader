Shader "Billy/RainGlass"
{
	Properties
	{
		_MainTex("Texture", 2D) = "white" {}
		_Size("Size",Float) = 1
		_Distortion("Distortion",range(0,5)) = 4
		_Blur("Blur",range(0,1)) = 1
	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" "Queue" = "Transparent"}

			GrabPass{"_GrabTexture"}

			Pass
			{
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
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float4 grabUv : TEXCOORD1;
				};

				sampler2D _MainTex;
				sampler2D _GrabTexture;
				float4 _MainTex_ST;
				float _Size;
				float _Distortion;
				float _Blur;

				v2f vert(appdata v)
				{
					v2f o;
					o.vertex = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.uv, _MainTex);
					o.grabUv = UNITY_PROJ_COORD(ComputeGrabScreenPos(o.vertex));
					return o;
				}


				float N21(float2 p) {
					p = frac(p*float2(123.34,345.45));
					p += dot(p,p + 34.345);
					return frac(p.x*p.y);
	}

				float3 Layer(float2 UV,float t) {
					float2 aspect = float2(2, 1);
					float2 uv = UV * _Size*aspect;

					uv.y += t * 0.25;
					float2 gv = frac(uv) - 0.5;
					float2 id = floor(uv);


					float n = N21(id);

					t += n * 6.28631;


					float w = UV.y * 10;

					float x = (n - 0.5)*0.8;

					x += (0.4 - abs(x))*sin(3 * w)*pow(sin(w),6)*0.45;
					float y = -sin(t + sin(t + sin(t)*0.5))*0.45;

					y -= (gv.x - x)*(gv.x - x);


					float2 dropPos = (gv - float2(x, y)) / aspect;
					float drop = smoothstep(0.05,0.03,length(dropPos));


					float2 dropTrailPos = (gv - float2(x, t*0.25)) / aspect;
					dropTrailPos.y = (frac(dropTrailPos.y * 8) / 8) - 0.03;
					float dropTrail = smoothstep(0.03, 0.02, length(dropTrailPos));
					float fogTrail = smoothstep(-0.05, 0.05, dropPos.y);
					fogTrail *= smoothstep(0.5, y, gv.y);
					dropTrail *= fogTrail;

					fogTrail *= smoothstep(0.05,0.04,abs(dropPos.x));

					//	col += fogTrail * 0.5;
					//	col += dropTrail;
					//	col += drop;

						float2 offs = drop * dropPos + dropTrail * dropTrailPos;
						return float3(offs,fogTrail);
	}

					fixed4 frag(v2f i) : SV_Target
					{
						float t = fmod(_Time.y,7200);
						float4 col = 0;
						//水滴层
						 float3 drops = Layer(i.uv,t);
						 //*是放大UV向量+，—是位移UV向量，瞎j8乘
						  drops += Layer(i.uv*1.35 + 7.51,t);
						  drops += Layer(i.uv*0.95 + 1.54,t);
						  drops += Layer(i.uv*1.57 - 6.54,t);
						  //fogTrail是水滴的拖尾因为我们需要拖尾处清楚所以我们需要取个反减值
						   float fade = 1 - saturate(fwidth(i.uv) * 60);
						   float blur = _Blur * 7 * (1 - drops.z*fade);

						   col = tex2Dlod(_MainTex,float4(i.uv+drops.xy*_Distortion,0,blur));

							   float2 projUv = i.grabUv.xy / i.grabUv.w;
							   projUv += drops.xy*_Distortion*fade;
							   blur *= 0.01;
							   const float numSamples = 32;
							   float a = N21(i.uv)*6.2831;
							   for (float i = 0; i < numSamples; i++) {
								   float2 offs = float2(sin(a),cos(a))*blur;
								   float d = frac(sin((i + 1) * 546) * 5421);
								   d = sqrt(d);
								   offs *= d;
								   col += tex2D(_GrabTexture,projUv + offs);
								   a++;
		   }
							   col /= numSamples;
							   return col;
						   }
						   ENDCG
					   }
		}
}