//iMix/Toon   mix from : UTS3/NiloToon/Genshin/StartRail/ZoneZero/BRDF
//imixgold@gmail.com

//To make SRP Batcher Compitable, cant' use #if in CBUFFER

// #pragma once
#ifndef UNIVERSAL_TOON_INPUT_INCLUDED
#define UNIVERSAL_TOON_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

//StartRail Include
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

#define fixed half
#define fixed3 half3
#define fixed4 half4

CBUFFER_START(UnityPerMaterial)

	float4 _MainTex_ST;
	float4 _Color;
	float _Alpha;
	float _AlphaClip;
	float _UselightmapAO;
	half _LightMapStrength;
	half4 _LightMapChannelMask_AO;
	half _LightMapRemapStart;
	half _LightMapRemapEnd;


	float _MainLightColorUsage;
	fixed _UseRampShadow;

	float4 _1st_ShadeColor;
	float4 _NormalMap_ST;

	fixed _Is_NormalMapToBase;
	float _Set_SystemShadowsToBase;
	float _Set_AL_SystemShadowsToBase;

	//Colin Light Structure
	fixed _LightingDirectionFix;
	float _CelShadowBias;
	float _CelShadeMidPoint;
	float _CelShadeSoftness;

	float3 _ShadowMapColor;

	float4 _HighColor;
	float4 _HighColor_Tex_ST;
	fixed _Is_LightColor_HighColor;
	fixed _Is_NormalMapToHighColor;
	float _HighColor_Power;

	//StartRail Sperular
	// #if _AREA_HAIR || _AREA_BODY
	float _SpecularExpon;
	float _SpecularKsNonMetal;
	float _SpecularKsMetal;
	float _SpecularBrightness;
	// #endif

	//End

	fixed _Is_SpecularToHighColor;
	fixed _Is_BlendAddToHiColor;
	fixed _Is_UseTweakHighColorOnShadow;
	float _TweakHighColorOnShadow;

	float4 _Set_HighColorMask_ST;

	float _Tweak_HighColorMaskLevel;

	//RimLight
	fixed _RimLight;
	float4 _RimLightColor;
	fixed _Is_LightColor_RimLight;
	fixed _Is_NormalMapToRimLight;
	float _RimLight_Power;
	float _RimLight_InsideMask;
	fixed _RimLight_FeatherOff;
	fixed _LightDirection_MaskOn;
	float _Tweak_LightDirection_MaskLevel;
	fixed _Add_Antipodean_RimLight;
	float4 _Ap_RimLightColor;
	fixed _Is_LightColor_Ap_RimLight;
	float _Ap_RimLight_Power;
	fixed _Ap_RimLight_FeatherOff;
	float4 _Set_RimLightMask_ST;
	float _Tweak_RimLightMaskLevel;

	//StartRailRimLight
	float _RimLightWidth;
	float _RimLightThreshold;
	float _RimLightFadeout;
	float3 _RimLightFrontColor;
	float3 _RimLightBackColor;
	float _RimLightBrightness;
	float _RimLightMixAlbedo;



	fixed _MatCap;

	float4 _MatCap_Sampler_ST;

	float4 _MatCapColor;
	fixed _Is_LightColor_MatCap;
	fixed _Is_BlendAddToMatCap;
	float _Tweak_MatCapUV;
	float _Rotate_MatCapUV;
	fixed _Is_NormalMapForMatCap;

	float4 _NormalMapForMatCap_ST;
	float _Rotate_NormalMapForMatCapUV;
	fixed _Is_UseTweakMatCapOnShadow;
	float _TweakMatCapOnShadow;
	//MatcapMask

	float4 _Set_MatcapMask_ST;
	float _Tweak_MatcapMaskLevel;

	fixed _Is_Ortho;

	float _CameraRolling_Stabilizer;
	fixed _BlurLevelMatcap;
	fixed _Inverse_MatcapMask;

	float _BumpScaleMatcap;

	float4 _Emissive_Tex_ST;
	float4 _Emissive_Color;

	uniform fixed _Is_ViewCoord_Scroll;
	float _Rotate_EmissiveUV;
	float _Base_Speed;
	float _Scroll_EmissiveU;
	float _Scroll_EmissiveV;
	fixed _Is_PingPong_Base;
	float4 _ColorShift;
	float4 _ViewShift;
	float _ColorShift_Speed;
	fixed _Is_ColorShift;
	fixed _Is_ViewShift;
	float3 emissive;


	float _Unlit_Intensity;

	fixed _Is_Filter_HiCutPointLightColor;
	fixed _Is_Filter_LightColor;

	fixed _Is_BLD;
	float _Offset_X_Axis_BLD;
	float _Offset_Y_Axis_BLD;
	fixed _Inverse_Z_Axis_BLD;


	float _GI_Intensity;
	float _AdditionalLightWeight;
	float _EnvLerp;
	float _IndirectLightUsage;
	float _IndirectLightMixBaseColor;
	float _IndirectLightFlattenNormal;

	//Angel Ring
	fixed _AngelRing;
	float4 _AngelRing_Color;
	fixed _Is_LightColor_AR;
	half _HairSpecularRange;
	half _HairSpecularViewRange;
	half _HairSpecularIntensity;
	half _AnisotropicSlide;
	half _AnisotropicOffset;



	// OUTLINE
	float _OutlineWidth;
	float _OutlineGamma;
	half3 _OutlineColor;
	float _OutlineZOffset;
	float _OutlineColorBlend;
	float _OutlineZOffsetMaskRemapStart;
	float _OutlineZOffsetMaskRemapEnd;

	float _test1;
	float _test2;
	float _test3;


	// #if _AREA_FACE
	float _FaceShadowOffset;
	float _FaceShadowTransitionSoftness;
	half4 _LightMapChannelMask_Face;
	fixed _EnableFaceSDF;
	// #endif

	//Eyes
	float _ParallaxScale;
	float _ParallaxMaskEdge;
	float _ParallaxMaskEdgeOffset;


	float4 _BaseMap_ST;
	half4 _BaseColor;
	float _ShadowRampOffset;
	half4 _SpecColor;
	half4 _EmissionColor;

	half _Cutoff;  // for shadow caster pass

	half _Smoothness;
	half _Metallic;
	half _BumpScale;
	half _OcclusionStrength;
	half _Surface;

	//PBR
	float _SSSWeightPBR;
	float _WeightBRDF;
	float _DiffuseWeightPBR;
	float _SpecularWeightPBR;
	float _FinalWeightPBR;
	float _FinalWeightNPR;
	// float _ShadowStrength;

	float4 _sssColor;
	float _roughness;
	// float _specular;
	// float _specularTint;
	// float _sheenTint;
	float _metallic;
	float _anisotropic;
	// float _sheen;
	// float _clearcoatGloss;
	float _subsurface;
	// float _clearcoat;
	float _ior;
	float _DirectOcclusion_PBR; // custom


	//EnvLight
	samplerCUBE _Cubemap;
	float _CubemapMip;
	float _FresnelPow;
	float4 _FresnelColor;
	// float4 _EdgeColor //用于遮挡shader
    float3 _HeadForward;
    float3 _HeadRight;

CBUFFER_END
///////////////CBURRER END///////////
/////////////////////////////////////


//Not in Shader Varient

// SAMPLER(sampler_LinearClamp) //gf2 AR (defined in other hlsl maybe..)

TEXTURE2D(_OutlineZOffsetMaskTex); SAMPLER(sampler_OutlineZOffsetMaskTex);
TEXTURE2D(_PBRMask); SAMPLER(sampler_PBRMask);

// #if _AREA_FACE
TEXTURE2D(_FaceMap); SAMPLER(sampler_FaceMap);
TEXTURE2D(_CoolRamp); SAMPLER(sampler_CoolRamp);
TEXTURE2D(_WarmRamp); SAMPLER(sampler_WarmRamp);
// #elif _AREA_HAIR
TEXTURE2D(_HairLightMap); SAMPLER(sampler_HairLightMap);
// #elif _AREA_BODY
TEXTURE2D(_BodyLightMap); SAMPLER(sampler_BodyLightMap);
// TEXTURE2D(_BodyCoolRamp); SAMPLER(sampler_BodyCoolRamp);
// TEXTURE2D(_BodyWarmRamp); SAMPLER(sampler_BodyWarmRamp);
// #endif

TEXTURE2D(_IBL_LUT); SAMPLER(sampler_IBL_LUT);

TEXTURE2D(_MainTex);  SAMPLER(sampler_linear_clamp_MainTex);
TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);

sampler2D _HighColor_Tex;
sampler2D _Set_HighColorMask;
sampler2D _Set_RimLightMask;
sampler2D _MatCap_Sampler;
sampler2D _NormalMapForMatCap;
sampler2D _Set_MatcapMask;
sampler2D _Emissive_Tex;
sampler2D _Outline_Sampler;
sampler2D _OutlineTex;
sampler2D _BakedNormal;



TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);


#ifdef _SPECULAR_SETUP
	#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
	#define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
	half4 specGloss;

	#ifdef _METALLICSPECGLOSSMAP
		specGloss = SAMPLE_METALLICSPECULAR(uv);
		#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			specGloss.a = albedoAlpha * _Smoothness;
		#else
			specGloss.a *= _Smoothness;
		#endif
	#else // _METALLICSPECGLOSSMAP
		#if _SPECULAR_SETUP
			specGloss.rgb = _SpecColor.rgb;
		#else
			specGloss.rgb = _Metallic.rrr;
		#endif

		#ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			specGloss.a = albedoAlpha * _Smoothness;
		#else
			specGloss.a = _Smoothness;
		#endif
	#endif

	return specGloss;
}

half SampleOcclusion(float2 uv)
{
	#ifdef _OCCLUSIONMAP
		// TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
		#if defined(SHADER_API_GLES)
			return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
		#else
			half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
			return LerpWhiteTo(occ, _OcclusionStrength);
		#endif
	#else
		return 1.0;
	#endif
}

inline void InitializeStandardLitSurfaceData(float2 uv, out SurfaceData outSurfaceData)
{
	half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
	outSurfaceData.alpha = Alpha(albedoAlpha.a, _BaseColor, _Cutoff);

	half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
	outSurfaceData.albedo = albedoAlpha.rgb * _BaseColor.rgb;

	#if _SPECULAR_SETUP
		outSurfaceData.metallic = 1.0h;
		outSurfaceData.specular = specGloss.rgb;
	#else
		outSurfaceData.metallic = specGloss.r;
		outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
	#endif

	outSurfaceData.smoothness = specGloss.a;
	outSurfaceData.normalTS = SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale);
	outSurfaceData.occlusion = SampleOcclusion(uv);
	outSurfaceData.emission = SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap));
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
