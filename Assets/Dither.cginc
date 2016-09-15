
#define DITHER_PROPERTIES \
sampler2D _DitherPattern; float4 _DitherPattern_TexelSize; \
float _DitherSpreadU; \
float _DitherSpreadV; \

#if defined(_DITHER_ON)
#define DITHER_FRAGIN , UNITY_VPOS_TYPE screenPos : VPOS
#define COMPUTE_DITHER tex2D(_DitherPattern, screenPos.xy * _DitherPattern_TexelSize.xy) * 2 - 1;

#else

#define DITHER_FRAGIN
#define COMPUTE_DITHER float4(0, 0, 0, 1)

#endif
