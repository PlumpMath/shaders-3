
Shader "Custom/Skybox" {

	Properties {
		_ShadingMap ("Shading Map", 2D) = "white" {}
	}


	SubShader {

		Tags { "RenderType" = "Opaque" }


		Pass {

			Tags { "Queue"="Background" }
			CGPROGRAM

			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _ShadingMap; float4 _ShadingMap_ST;

			v2f vert(appdata_base v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _ShadingMap);
				o.uv.y += 1;
				o.uv.y /= 2;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				return tex2D(_ShadingMap, i.uv);
			}

			ENDCG

		}
	}
}
