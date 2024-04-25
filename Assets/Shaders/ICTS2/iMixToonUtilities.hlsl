//iMix/Toon   mix from : UTS3/NiloToon/Genshin/StartRail/ZoneZero/BRDF
//imixgold@gmail.com

// RaytracedHardShadow
// This is global texture.  what to do with SRP Batcher.

#define UNITY_PROJ_COORD(a) a
#define UNITY_SAMPLE_SCREEN_SHADOW(tex, uv) tex2Dproj(tex, UNITY_PROJ_COORD(uv)).r
#include "iMixToonHead.hlsl"
#define TEXTURE2D_SAMPLER2D(textureName, samplerName) Texture2D textureName; SamplerState samplerName
TEXTURE2D_SAMPLER2D(_RaytracedHardShadow, sampler_RaytracedHardShadow);
float4 _RaytracedHardShadow_TexelSize;

//function to rotate the UV: RotateUV()
//float2 rotatedUV = RotateUV(i.uv0, (_angular_Verocity*3.141592654), float2(0.5, 0.5), _Time.g);
float2 RotateUV(float2 _uv, float _radian, float2 _piv, float _time)
{
	float RotateUV_ang = _radian;
	float RotateUV_cos = cos(_time * RotateUV_ang);
	float RotateUV_sin = sin(_time * RotateUV_ang);
	return (mul(_uv - _piv, float2x2(RotateUV_cos, -RotateUV_sin, RotateUV_sin, RotateUV_cos)) + _piv);
}
//
fixed3 DecodeLightProbe(fixed3 N)
{
	return ShadeSH9(float4(N, 1));
}

inline void InitializeStandardLitSurfaceDataUTS(float2 uv, out SurfaceData outSurfaceData)
{
	outSurfaceData = (SurfaceData)0;
	// half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
	half4 albedoAlpha = half4(1.0, 1.0, 1.0, 1.0);
	
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
half3 GlobalIlluminationUTS_Deprecated_Deprecated(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS)
{
	half3 reflectVector = reflect(-viewDirectionWS, normalWS);
	half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));

	half3 indirectDiffuse = bakedGI * occlusion;
	half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);

	return EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
}
half3 GlobalIlluminationUTS(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS, float3 positionWS, float2 normalizedScreenSpaceUV)
{
	half3 reflectVector = reflect(-viewDirectionWS, normalWS);
	half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));

	half3 indirectDiffuse = bakedGI * occlusion;
	#if USE_FORWARD_PLUS
		half3 irradiance = CalculateIrradianceFromReflectionProbes(reflectVector, positionWS, brdfData.perceptualRoughness, normalizedScreenSpaceUV);
		half3 indirectSpecular = irradiance * occlusion;
	#else
		half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);
	#endif
	return EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
}




// Abstraction over Light shading data.
struct UtsLight
{
	float3 direction;
	float3 color;
	float distanceAttenuation;
	float shadowAttenuation;
	int type;
};

///////////////////////////////////////////////////////////////////////////////
//                      Light Abstraction                                    //
/////////////////////////////////////////////////////////////////////////////
half MainLightRealtimeShadowUTS(float4 shadowCoord, float4 positionCS)
{
	#if !defined(MAIN_LIGHT_CALCULATE_SHADOWS)
		return 1.0;
	#endif
	ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
	half4 shadowParams = GetMainLightShadowParams();
	#if defined(UTS_USE_RAYTRACING_SHADOW)
		float w = (positionCS.w == 0) ? 0.00001 : positionCS.w;
		float4 screenPos = ComputeScreenPos(positionCS / w);
		return SAMPLE_TEXTURE2D(_RaytracedHardShadow, sampler_RaytracedHardShadow, screenPos);
	#elif defined(_MAIN_LIGHT_SHADOWS_SCREEN)
		return SampleScreenSpaceShadowmap(shadowCoord);
	#endif


	return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);
}

half AdditionalLightRealtimeShadowUTS(int lightIndex, float3 positionWS, float4 positionCS)
{
	#if  defined(UTS_USE_RAYTRACING_SHADOW)
		float w = (positionCS.w == 0) ? 0.00001 : positionCS.w;
		float4 screenPos = ComputeScreenPos(positionCS / w);
		return SAMPLE_TEXTURE2D(_RaytracedHardShadow, sampler_RaytracedHardShadow, screenPos);
	#endif // UTS_USE_RAYTRACING_SHADOW

	#if defined(ADDITIONAL_LIGHT_CALCULATE_SHADOWS)


		#if (SHADER_LIBRARY_VERSION_MAJOR >= 13 && UNITY_VERSION >= 202220)
			ShadowSamplingData shadowSamplingData = GetAdditionalLightShadowSamplingData(lightIndex);
		#else
			ShadowSamplingData shadowSamplingData = GetAdditionalLightShadowSamplingData();
		#endif

		#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
			lightIndex = _AdditionalShadowsIndices[lightIndex];

			// We have to branch here as otherwise we would sample buffer with lightIndex == -1.
			// However this should be ok for platforms that store light in SSBO.
			UNITY_BRANCH
			if (lightIndex < 0)
				return 1.0;

			float4 shadowCoord = mul(_AdditionalShadowsBuffer[lightIndex].worldToShadowMatrix, float4(positionWS, 1.0));
		#else
			float4 shadowCoord = mul(_AdditionalLightsWorldToShadow[lightIndex], float4(positionWS, 1.0));
		#endif

		half4 shadowParams = GetAdditionalLightShadowParams(lightIndex);
		return SampleShadowmap(TEXTURE2D_ARGS(_AdditionalLightsShadowmapTexture, sampler_AdditionalLightsShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, true);
	#else
		return 1.0h;
	#endif
}



UtsLight GetUrpMainUtsLight()
{
	UtsLight light;
	light.direction = _MainLightPosition.xyz;
	#if USE_FORWARD_PLUS
		#if defined(LIGHTMAP_ON)
			light.distanceAttenuation = _MainLightColor.a;
		#else
			light.distanceAttenuation = 1.0;
		#endif
	#else
		// unity_LightData.z is 1 when not culled by the culling mask, otherwise 0.
		light.distanceAttenuation = unity_LightData.z;
	#endif
	#if defined(LIGHTMAP_ON) || defined(_MIXED_LIGHTING_SUBTRACTIVE)
		// unity_ProbesOcclusion.x is the mixed light probe occlusion data
		light.distanceAttenuation *= unity_ProbesOcclusion.x;
	#endif
	light.shadowAttenuation = 1.0;
	light.color = _MainLightColor.rgb;
	light.type = _MainLightPosition.w;
	return light;
}

UtsLight GetUrpMainUtsLight(float4 shadowCoord, float4 positionCS)
{
	UtsLight light = GetUrpMainUtsLight();
	light.shadowAttenuation = MainLightRealtimeShadowUTS(shadowCoord, positionCS);
	return light;
}

// Fills a light struct given a perObjectLightIndex
UtsLight GetAdditionalPerObjectUtsLight(int perObjectLightIndex, float3 positionWS, float4 positionCS)
{
	// Abstraction over Light input constants
	#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
		float4 lightPositionWS = _AdditionalLightsBuffer[perObjectLightIndex].position;
		half3 color = _AdditionalLightsBuffer[perObjectLightIndex].color.rgb;
		half4 distanceAndSpotAttenuation = _AdditionalLightsBuffer[perObjectLightIndex].attenuation;
		half4 spotDirection = _AdditionalLightsBuffer[perObjectLightIndex].spotDirection;
		half4 lightOcclusionProbeInfo = _AdditionalLightsBuffer[perObjectLightIndex].occlusionProbeChannels;
	#else
		float4 lightPositionWS = _AdditionalLightsPosition[perObjectLightIndex];
		half3 color = _AdditionalLightsColor[perObjectLightIndex].rgb;
		half4 distanceAndSpotAttenuation = _AdditionalLightsAttenuation[perObjectLightIndex];
		half4 spotDirection = _AdditionalLightsSpotDir[perObjectLightIndex];
		half4 lightOcclusionProbeInfo = _AdditionalLightsOcclusionProbes[perObjectLightIndex];
	#endif

	// Directional lights store direction in lightPosition.xyz and have .w set to 0.0.
	// This way the following code will work for both directional and punctual lights.
	float3 lightVector = lightPositionWS.xyz - positionWS * lightPositionWS.w;
	float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

	half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
	half attenuation = DistanceAttenuation(distanceSqr, distanceAndSpotAttenuation.xy) * AngleAttenuation(spotDirection.xyz, lightDirection, distanceAndSpotAttenuation.zw);

	UtsLight light;
	light.direction = lightDirection;
	light.distanceAttenuation = attenuation;
	light.shadowAttenuation = AdditionalLightRealtimeShadowUTS(perObjectLightIndex, positionWS, positionCS);
	light.color = color;
	light.type = lightPositionWS.w;

	// In case we're using light probes, we can sample the attenuation from the `unity_ProbesOcclusion`
	#if defined(LIGHTMAP_ON) || defined(_MIXED_LIGHTING_SUBTRACTIVE)
		// First find the probe channel from the light.
		// Then sample `unity_ProbesOcclusion` for the baked occlusion.
		// If the light is not baked, the channel is -1, and we need to apply no occlusion.

		// probeChannel is the index in 'unity_ProbesOcclusion' that holds the proper occlusion value.
		int probeChannel = lightOcclusionProbeInfo.x;

		// lightProbeContribution is set to 0 if we are indeed using a probe, otherwise set to 1.
		half lightProbeContribution = lightOcclusionProbeInfo.y;

		half probeOcclusionValue = unity_ProbesOcclusion[probeChannel];
		light.distanceAttenuation *= max(probeOcclusionValue, lightProbeContribution);
	#endif

	return light;
}

// Fills a light struct given a loop i index. This will convert the i
// index to a perObjectLightIndex
UtsLight GetAdditionalUtsLight(uint i, float3 positionWS, float4 positionCS)
{
	#if USE_FORWARD_PLUS
		int perObjectLightIndex = i;
	#else
		int perObjectLightIndex = GetPerObjectLightIndex(i);
	#endif
	return GetAdditionalPerObjectUtsLight(perObjectLightIndex, positionWS, positionCS);
}

half3 GetLightColor(UtsLight light)
{
	return light.color * light.distanceAttenuation;
}


#define INIT_UTSLIGHT(utslight) \
            utslight.direction = 0; \
            utslight.color = 0; \
            utslight.distanceAttenuation = 0; \
            utslight.shadowAttenuation = 0; \
            utslight.type = 0


int DetermineUTS_MainLightIndex(float3 posW, float4 shadowCoord, float4 positionCS)
{
	UtsLight mainLight;
	INIT_UTSLIGHT(mainLight);

	int mainLightIndex = MAINLIGHT_NOT_FOUND;
	UtsLight nextLight = GetUrpMainUtsLight(shadowCoord, positionCS);
	if (nextLight.distanceAttenuation > mainLight.distanceAttenuation && nextLight.type == 0)
	{
		mainLight = nextLight;
		mainLightIndex = MAINLIGHT_IS_MAINLIGHT;
	}
	int lightCount = GetAdditionalLightsCount();
	for (int ii = 0; ii < lightCount; ++ii)
	{
		nextLight = GetAdditionalUtsLight(ii, posW, positionCS);
		if (nextLight.distanceAttenuation > mainLight.distanceAttenuation && nextLight.type == 0)
		{
			mainLight = nextLight;
			mainLightIndex = ii;
		}
	}

	return mainLightIndex;
}

UtsLight GetMainUtsLightByID(int index, float3 posW, float4 shadowCoord, float4 positionCS)
{
	UtsLight mainLight;
	INIT_UTSLIGHT(mainLight);
	if (index == MAINLIGHT_NOT_FOUND)
	{
		return mainLight;
	}
	if (index == MAINLIGHT_IS_MAINLIGHT)
	{
		return GetUrpMainUtsLight(shadowCoord, positionCS);
	}
	return GetAdditionalUtsLight(index, posW, positionCS);
}

//iMix
struct Gradient
{
	int colorsLength;
	float4 colors[8];
};

Gradient GradientConstruct()
{
	Gradient g;
	g.colorsLength = 2;
	g.colors[0] = float4(1, 1, 1, 0);
	g.colors[1] = float4(1, 1, 1, 1);
	g.colors[2] = float4(0, 0, 0, 0);
	g.colors[3] = float4(0, 0, 0, 0);
	g.colors[4] = float4(0, 0, 0, 0);
	g.colors[5] = float4(0, 0, 0, 0);
	g.colors[6] = float4(0, 0, 0, 0);
	g.colors[7] = float4(0, 0, 0, 0);
	return g;
}
float3 SampleGradient(Gradient Gradient, float Time)
{
	float3 color = Gradient.colors[0].rgb;
	for (int c = 1; c < Gradient.colorsLength; c++)
	{
		float colorPos = saturate((Time - Gradient.colors[c - 1].w) / (Gradient.colors[c].w - Gradient.colors[c - 1].w)) * step(c, Gradient.colorsLength - 1);
		color = lerp(color, Gradient.colors[c].rgb, colorPos);
	}
	#ifdef UNITY_COLORSPACE_GAMMA
		COLOR = LinearToSRGB(color);
	#endif
	return color;
}
float3 desaturation(float3 color)
{
	float3 grayXfer = float3(0.3, 0.59, 0.11);
	float grayf = dot(color, grayXfer);
	return float3(grayf, grayf, grayf);
}

//float version lerp
float3 float3Lerp(float3 a, float3 b, float c)
{
	return a * (1 - c) + b * c;
}

float floatLerp(float a, float b, float c)
{
	return a * (1 - c) + b * c;
}

//InvLerpRemap
// .......begin
float invLerp(float from, float to, float value)
{
	return (value - from) / (to - from);
}
float invLerpClamp(float from, float to, float value)
{
	return saturate(invLerp(from, to, value));
}
// full control remap, but slower
half remap(float origFrom, float origTo, float targetFrom, float targetTo, float value)
{
	float rel = invLerp(origFrom, origTo, value);
	return lerp(targetFrom, targetTo, rel);
}
// .......end

//ZOffset

float GetCameraFOV()
{
	//https://answers.unity.com/questions/770838/how-can-i-extract-the-fov-information-from-the-pro.html
	float t = unity_CameraProjection._m11;
	float Rad2Deg = 180 / 3.1415;
	float fov = atan(1.0f / t) * 2.0 * Rad2Deg;
	return fov;
}
float ApplyOutlineDistanceFadeOut(float inputMulFix)
{
	//make outline "fadeout" if character is too small in camera's view
	return saturate(inputMulFix);
}
float GetOutlineCameraFovAndDistanceFixMultiplier(float positionVS_Z)
{
	float cameraMulFix;
	if (unity_OrthoParams.w == 0)
	{
		////////////////////////////////
		// Perspective camera case
		////////////////////////////////

		// keep outline similar width on screen accoss all camera distance
		cameraMulFix = abs(positionVS_Z);

		// can replace to a tonemap function if a smooth stop is needed
		cameraMulFix = ApplyOutlineDistanceFadeOut(cameraMulFix);

		// keep outline similar width on screen accoss all camera fov
		cameraMulFix *= GetCameraFOV();
	}
	else
	{
		////////////////////////////////
		// Orthographic camera case
		////////////////////////////////
		float orthoSize = abs(unity_OrthoParams.y);
		orthoSize = ApplyOutlineDistanceFadeOut(orthoSize);
		cameraMulFix = orthoSize * 50; // 50 is a magic number to match perspective camera's outline width

	}

	return cameraMulFix * 0.00005; // mul a const to make return result = default normal expand amount WS

}


float4 iMixGetNewClipPosWithZOffset(float4 originalPositionCS, float viewSpaceZOffsetAmount)
{
	if (unity_OrthoParams.w == 0)
	{
		//Perspective camera case
		float2 ProjM_ZRow_ZW = UNITY_MATRIX_P[2].zw;
		float modifiedPositionVS_Z = -originalPositionCS.w + - viewSpaceZOffsetAmount; // push imaginary vertex
		float modifiedPositionCS_Z = modifiedPositionVS_Z * ProjM_ZRow_ZW[0] + ProjM_ZRow_ZW[1];
		originalPositionCS.z = modifiedPositionCS_Z * originalPositionCS.w / (-modifiedPositionVS_Z); // overwrite positionCS.z
		return originalPositionCS;
	}
	else
	{
		//Orthographic camera case
		originalPositionCS.z += -viewSpaceZOffsetAmount / _ProjectionParams.z; // push imaginary vertex and overwrite positionCS.z
		return originalPositionCS;
	}
}

float4 TransformHClipToViewPortPos(float4 positionCS)
{
	float4 o = positionCS * 0.5f;
	o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
	o.zw = positionCS.zw;
	return o / o.w;
}




