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
		[KeywordEnum(None, Breath)] _Motion ("Motion Type", Float) = 0
		_MotionAmount ("Motion Amount", Float) = 1
		_MotionMap ("Motion Map", 2D) = "white"
	}


	SubShader {

		Tags { "RenderType" = "Opaque" }

		CGINCLUDE

		#pragma shader_feature _MOTION_NONE _MOTION_BREATH

		#include "UnityCG.cginc"

		sampler2D _TransparencyMap; float4 _TransparencyMap_ST;
		half _TransparencyCutoff;


	#if !defined(_MOTION_NONE)

		float _MotionAmount;
		sampler2D _MotionMap; float4 _MotionMap_ST;

		inline appdata_full vertexmotion(appdata_full v) {
			float4 uv;
			uv.xy = TRANSFORM_TEX(v.texcoord, _MotionMap);
			uv.zw = 0;
			float amount = _MotionAmount * tex2Dlod(_MotionMap, uv);
		#if defined(_MOTION_BREATH)
			float t = _SinTime.w;
			t += 1;
			t /= 2;
			v.vertex.xyz = v.vertex.xyz + (v.normal.xyz * (t * amount));
		#endif
			return v;
		}

		#define APPLY_MOTION(v) v = vertexmotion(v)

	#else

		#define APPLY_MOTION(v)

	#endif

		#define DISCARD_CUTOUT(i) if (tex2D(_TransparencyMap, i.uvTrans).r < _TransparencyCutoff) discard

		ENDCG


		Pass {

			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM

			#pragma shader_feature _DITHER_ON

			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "AutoLight.cginc"

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
			float _ShadowFactor;
			float _ShadowOffset;
		#if defined(_DITHER_ON)
			float _DitherSpread;
		#endif

			v2f vert(appdata_full v, out float4 outpos : SV_POSITION) {
				APPLY_MOTION(v);
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
				DISCARD_CUTOUT(i);
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
				float2 uvTrans : TEXCOORD0;
				V2F_SHADOW_CASTER;
			};

			v2f vert(appdata_full v) {
				APPLY_MOTION(v);
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				o.uvTrans = TRANSFORM_TEX(v.texcoord, _TransparencyMap);
				return o;
			}

			float4 frag(v2f i) : SV_Target {
				DISCARD_CUTOUT(i);
				SHADOW_CASTER_FRAGMENT(i)
			}
			ENDCG
		}
	}
}
