Shader "Custom/Cel Shaded" {

	Properties {
		_ShadingMap ("Shading Map", 2D) = "white" {}
		_ShadingOffsetMap ("Shading Offset Map", 2D) = "bump" {}
		_NormalMap ("Normal Map", 2D) = "bump" {}
		_TransparencyMap ("Transparency Map", 2D) = "white" {}
		_TransparencyCutoff ("Transparency Cutoff", Range (0, 1)) = 0.5
		_ShadowFactor ("Shadow Factor", Float) = 0.5
		[Toggle] _Dither ("Dither", Float) = 0
		[PowerSlider(3)] _DitherSpread ("Dither Radius", Range(0, 1)) = 0.0
	}
	SubShader {

		Tags { "RenderType" = "Opaque" }

		Pass {

			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma shader_feature _DITHER_ON

			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "CelShading.cginc"

			struct v2f {
				float4 pos : TEXCOORD0;
				float3 lightDirection : TEXCOORD1;
				float2 uvOffset : TEXCOORD2;
				float2 uvNorm : TEXCOORD3;
				float2 uvTrans : TEXCOORD4;
				LIGHTING_COORDS(5, 6)
			};

			sampler2D _ShadingMap; float4 _ShadingMap_ST;
			sampler2D _ShadingOffsetMap; float4 _ShadingOffsetMap_ST;
			sampler2D _NormalMap; float4 _NormalMap_ST;
			sampler2D _TransparencyMap; float4 _TransparencyMap_ST;
			half _TransparencyCutoff;
			float _ShadowFactor;
			float _ShadowOffset;
		#if defined(_DITHER_ON)
			float _DitherSpread;
		#endif

			v2f vert(appdata_full v, out float4 outpos : SV_POSITION) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				outpos = o.pos;
				TANGENT_SPACE_ROTATION;
				o.lightDirection = mul(rotation, ObjSpaceLightDir(v.vertex));
				o.uvOffset = TRANSFORM_TEX(v.texcoord, _ShadingOffsetMap);
				o.uvNorm = TRANSFORM_TEX(v.texcoord, _NormalMap);
				o.uvTrans = TRANSFORM_TEX(v.texcoord, _TransparencyMap);
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}

			fixed4 frag(v2f i
			#if defined(_DITHER_ON)
				, UNITY_VPOS_TYPE screenPos : VPOS
			#endif
				) : SV_Target {
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
			#if defined(_DITHER_ON)
				screenPos.xy = floor(screenPos.xy) / 2;
				float dither = frac(screenPos.x + screenPos.y) * 4;
				dither -= 1;
				uvShading += dither * _DitherSpread;
			#endif
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
