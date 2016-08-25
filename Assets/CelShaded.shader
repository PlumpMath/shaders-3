Shader "Custom/Cel Shaded" {

	Properties {
		_ShadingMap ("Shading Map", 2D) = "white" {}
		_ShadingOffsetMap ("Shading Offset Map", 2D) = "bump" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_TransparencyMap ("Transparency Map", 2D) = "white" {}
		_TransparencyCutoff ("Transparency Cutoff", Range (0, 1)) = 0.5
		_ShadowFactor ("Shadow Factor", Float) = 0.5
	}
	SubShader {

		Tags { "RenderType" = "Opaque" }

		Pass {

			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"

			struct v2f {
				float4 pos : SV_POSITION;
				float3 lightDirection : TEXCOORD0;
				float2 uvOffset : TEXCOORD1;
				float2 uvNorm : TEXCOORD2;
				float2 uvTrans : TEXCOORD3;
				LIGHTING_COORDS(4, 5)
			};

			sampler2D _ShadingMap; float4 _ShadingMap_ST;
			sampler2D _ShadingOffsetMap; float4 _ShadingOffsetMap_ST;
			sampler2D _NormalMap; float4 _NormalMap_ST;
			sampler2D _TransparencyMap; float4 _TransparencyMap_ST;
			half _TransparencyCutoff;
			float _ShadowFactor;
			float _ShadowOffset;

			v2f vert (appdata_full v) {
				v2f o;
				TANGENT_SPACE_ROTATION;
				o.lightDirection = mul(rotation, ObjSpaceLightDir(v.vertex));
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uvOffset = TRANSFORM_TEX(v.texcoord, _ShadingOffsetMap);
				o.uvNorm = TRANSFORM_TEX(v.texcoord, _NormalMap);
				o.uvTrans = TRANSFORM_TEX(v.texcoord, _TransparencyMap);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target {
				//alpha cutout
				if (tex2D(_TransparencyMap, i.uvTrans).r < _TransparencyCutoff) discard;
				//normal mapping
				float3 texNorm = UnpackNormal(tex2D(_NormalMap, i.uvNorm));// * _NormalWeight;
				//lighting
				float shading = dot(normalize(texNorm), normalize(i.lightDirection));
				shading = (shading + 1) / 2;
				//shadows
				float shadows = LIGHT_ATTENUATION(i);
				shadows = 1 - shadows;
				shadows *= _ShadowFactor;
				shadows = 1 - shadows;
				shading *= shadows;
				//shading offset mapping
				float2 shadingOffset = 0;
				float3 offset = tex2D(_ShadingOffsetMap, i.uvOffset);
				shadingOffset.xy = (offset.xy * 2) - 1;
				//shading mapping
				float2 uvShading = float2(shading * offset.z, 0);
				uvShading += shadingOffset;
				uvShading = TRANSFORM_TEX(uvShading, _ShadingMap);
				return tex2D(_ShadingMap, uvShading);
			}

			ENDCG

		}

		Pass {
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_shadowcaster

			#include "UnityCG.cginc"

			struct v2f {
				float2 uv : TEXCOORD0;
				V2F_SHADOW_CASTER;
			};

			sampler2D _TransparencyMap; float4 _TransparencyMap_ST;
			half _TransparencyCutoff;

			v2f vert(appdata_base v) {
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.uv = TRANSFORM_TEX(v.texcoord, _TransparencyMap);
				return o;
			}

			float4 frag(v2f i) : SV_Target {
				if (tex2D(_TransparencyMap, i.uv).r < _TransparencyCutoff) discard;
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}
