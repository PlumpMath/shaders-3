Shader "Custom/Cel Shaded Particle" {

	Properties {
		_ShadingMap ("Shading Map", 2D) = "white" {}
	}

	SubShader {

		Tags { "RenderType" = "Opaque" }

		Pass {
			Cull Off

			Tags { "LightMode" = "ForwardBase" }


			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f {
				float4 pos : SV_POSITION;
				float2 offset : TEXCOORD0;
			};

			sampler2D _ShadingMap; float4 _ShadingMap_ST;

			v2f vert (appdata_full v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.offset = v.color.ar;
				o.offset *= 2;
				o.offset -= 1;
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				/*return float4(i.offset.xy, 0, 1);*/
				float2 uvShading = TRANSFORM_TEX(i.offset, _ShadingMap);
				return tex2D(_ShadingMap, uvShading);
			}

			ENDCG

		}

	}
}
