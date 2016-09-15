
Shader "Custom/Skybox" {

	Properties {
		_ShadingMap ("Shading Map", 2D) = "white" {}
		[Toggle] _Dither ("Dither", Float) = 0
		[NoScaleOffset] _DitherPattern ("Dither Pattern", 2D) = "gray" {}
		[PowerSlider(3)] _DitherSpreadU ("Dither Radius U", Range(0, 1)) = 0.0
		[PowerSlider(3)] _DitherSpreadV ("Dither Radius V", Range(0, 1)) = 0.0
	}


	SubShader {

		Tags { "RenderType" = "Opaque" }

		Pass {

			Tags { "Queue"="Background" }
			CGPROGRAM

			#pragma shader_feature _DITHER_ON

			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Dither.cginc"

			struct v2f {
				float2 uv : TEXCOORD0;
			};

			sampler2D _ShadingMap; float4 _ShadingMap_ST;
			DITHER_PROPERTIES;

			v2f vert(appdata_base v, out float4 pos : SV_POSITION) {
				v2f o;
				pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _ShadingMap);
				o.uv.y += 1;
				o.uv.y /= 2;
				return o;
			}

			fixed4 frag(v2f i DITHER_FRAGIN) : SV_Target {
				float4 dither = COMPUTE_DITHER;
				i.uv.x += dither.x * _DitherSpreadU;
				i.uv.y += dither.y * _DitherSpreadV;
				return tex2D(_ShadingMap, i.uv);
			}

			ENDCG

		}
	}
}
