#include "iMixToonUtilities.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//StartRail Include
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
	float3 positionOS : POSITION;
	half3 normalOS : NORMAL;
	half4 tangentOS : TANGENT;
	float2 uv : TEXCOORD0;
	float4 uv7 : TEXCOORD7;
	float4 vertexColor : COLOR;
};

struct Varyings
{
	float4 vertexColor : TEXCOORD5;
	float2 uv : TEXCOORD0;
	float3 positionWS : TEXCOORD3;
	float fogFactor : TEXCOORD1;
	float3 normalDir : TEXCOORD6;
	int mainLightID : TEXCOORD8;
    float4 shadowCoord : TEXCOORD7;
	float4 positionCS : SV_POSITION;
};

Varyings vert(Attributes input)
{
	Varyings output = (Varyings)0;
    output.vertexColor = input.vertexColor;
	VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
	VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

	float width = _OutlineWidth;
	width *= GetOutlineCameraFovAndDistanceFixMultiplier(vertexPositionInput.positionVS.z);  // TODO:限定描边的最粗和最细值
	width *= input.vertexColor.r;  //根据顶点色粗细调整描边，一般是模型自带，如果没有就用blender自己画（修改原有模型这样就不用改
	//渲染了，然后也可以用unity编辑器创建顶点色编辑器，这是链接
	//https://zhuanlan.zhihu.com/p/384057363
	
    

	float3 positionWS = vertexPositionInput.positionWS;
	#if _OUTLINE_UV7_SMOOTH_NORMAL
		float3x3 tbn = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
		positionWS += mul(input.uv7.rgb, tbn) * width;
	#else
		positionWS += vertexNormalInput.normalWS * width;
	#endif
	output.positionWS = positionWS;
	output.positionCS = TransformWorldToHClip(positionWS);

	output.uv = TRANSFORM_TEX(input.uv, _MainTex);
	output.fogFactor = ComputeFogFactor(vertexPositionInput.positionCS.z);

	// [Read ZOffset mask texture]
	// we can't use tex2D() in vertex shader because ddx & ddy is unknown before rasterization,
	// so use tex2Dlod() with an explict mip level 0, put explict mip level 0 inside the 4th component of param uv)
	float outlineZOffsetMaskTexExplictMipLevel = 0;
	float outlineZOffsetMask = SAMPLE_TEXTURE2D_LOD(_OutlineZOffsetMaskTex, sampler_OutlineZOffsetMaskTex, input.uv, outlineZOffsetMaskTexExplictMipLevel).r; //we assume it is a Black/White texture

	// [Remap ZOffset texture value]
	// flip texture read value so default black area = apply ZOffset, because usually outline mask texture are using this format(black = hide outline)
	outlineZOffsetMask = 1 - outlineZOffsetMask;
	outlineZOffsetMask = invLerpClamp(_OutlineZOffsetMaskRemapStart, _OutlineZOffsetMaskRemapEnd, outlineZOffsetMask);// allow user to flip value or remap
    
	#if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
		#if SHADOWS_SCREEN
			output.shadowCoord = ComputeScreenPos(output.positionCS);
		#else
			output.shadowCoord = TransformWorldToShadowCoord(output.positionWS.xyz);
		#endif
		output.mainLightID = DetermineUTS_MainLightIndex(output.positionWS.xyz, output.shadowCoord, output.positionCS);
	#else
		output.mainLightID = DetermineUTS_MainLightIndex(output.positionWS.xyz, 0, output.positionCS);
	#endif
	// [Apply ZOffset, Use remapped value as ZOffset mask]
	// #if _AREA_FACE //no need , I can set _OutlineZOffset by myself
	// output.positionCS = iMixGetNewClipPosWithZOffset(output.positionCS, _OutlineZOffset * outlineZOffsetMask + 0.03);
	// #else
		output.positionCS = iMixGetNewClipPosWithZOffset(output.positionCS, _OutlineZOffset * outlineZOffsetMask);
		output.normalDir = UnityObjectToWorldNormal(input.normalOS);
	// #endif
    
	return output;
}

float4 frag(Varyings input) : SV_TARGET
{

	float3 coolRamp = 0;
	float3 warmRamp = 0;
	
	#if _AREA_HAIR
		{
			float2 outlineUV = float2(0, 0.5);
			coolRamp = SAMPLE_TEXTURE2D(_CoolRamp, sampler_CoolRamp, outlineUV).rgb;
			warmRamp = SAMPLE_TEXTURE2D(_WarmRamp, sampler_WarmRamp, outlineUV).rgb;
		}
	#elif _AREA_BODY
		{
			float4 lightMap = SAMPLE_TEXTURE2D(_BodyLightMap, sampler_BodyLightMap, input.uv);

			float materialEnum = lightMap.a;
			float materialEnumOffset = materialEnum + 0.0425;
			float outlineUVy = lerp(materialEnumOffset, materialEnumOffset +0.5 < 1 ? materialEnumOffset +0.5 : materialEnumOffset +0.5 - 1, fmod((round(materialEnumOffset / 0.0625) - 1) / 2, 2));
			float2 outlineUV = float2(0, outlineUVy - 0.5); // -0.5是没有任何道理的trick
			coolRamp = SAMPLE_TEXTURE2D(_CoolRamp, sampler_CoolRamp, outlineUV).rgb;
			warmRamp = SAMPLE_TEXTURE2D(_WarmRamp, sampler_WarmRamp, outlineUV).rgb;
		}
	#elif _AREA_FACE
		{
			float2 outlineUV = float2(0, 0.0625);
			coolRamp = SAMPLE_TEXTURE2D(_CoolRamp, sampler_CoolRamp, outlineUV).rgb;
			warmRamp = SAMPLE_TEXTURE2D(_WarmRamp, sampler_WarmRamp, outlineUV).rgb;
		}
	#endif

	float3 ramp = lerp(coolRamp, warmRamp, 0.5);
	float3 albedo = pow(saturate(ramp == 0 ? 1 : ramp), _OutlineGamma);

	albedo = lerp(albedo.rgb, _OutlineColor.rgb, _OutlineColorBlend);

	float alpha = 1;
	Light mainLight = GetMainLight();

    float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - input.positionWS.xyz);

	float3 shadowTestPosWS = input.positionWS.xyz ;// + mainLight.direction * (_ReceiveShadowMappingPosOffset + _IsFace);
	float3 pointLightColor = 0;
	#ifdef _ADDITIONAL_LIGHTS
		int pixelLightCount = GetAdditionalLightsCount();

		// USE_FORWARD_PLUS Start  USE_FORWARD_PLUS = Forward +.
		#if USE_FORWARD_PLUS
			for (uint loopCounter = 0; loopCounter < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); loopCounter++)
			{
				int iLight = loopCounter;
				// if (iLight != i.mainLightID)
				{
					float notDirectional = 1.0f; //_WorldSpaceLightPos0.w of the legacy code.
					UtsLight additionalLight = GetUrpMainUtsLight(0, 0);
					additionalLight = GetAdditionalUtsLight(loopCounter, inputData.positionWS, input.positionCS);
					half3 additionalLightColor = GetLightColor(additionalLight);

					float3 lightDirection = additionalLight.direction;
					//
					float3 addPassLightColor = (0.5 * dot(input.normalDir, lightDirection) + 0.5) * additionalLightColor.rgb;
					float pureIntencity = max(0.001, (0.299 * additionalLightColor.r + 0.587 * additionalLightColor.g + 0.114 * additionalLightColor.b));
					float3 lightColor = max(float3(0.0, 0.0, 0.0), lerp(addPassLightColor, lerp(float3(0.0, 0.0, 0.0), min(addPassLightColor, addPassLightColor / pureIntencity), notDirectional), _Is_Filter_LightColor));
					float3 halfDirection = normalize(viewDirection + lightDirection); // has to be recalced here.

					float NdotAL = dot(input.normalDir, normalize(lightDirection));

					float3 finalColor = lightColor * floatLerp(1, additionalLight.shadowAttenuation, _Set_AL_SystemShadowsToBase);

					finalColor = SATURATE_IF_SDR(finalColor);
					// finalColor = saturate(finalColor);

					pointLightColor += finalColor * _AdditionalLightWeight;
				}
			}
		#endif
		// USE_FORWARD_PLUS End
		// determine main light inorder to apply light culling properly
		
		// when the loop counter start from negative value, MAINLIGHT_IS_MAINLIGHT = -1, some compiler doesn't work well.
		// for (int iLight = MAINLIGHT_IS_MAINLIGHT; iLight < pixelLightCount ; ++iLight)
		UTS_LIGHT_LOOP_BEGIN(pixelLightCount - MAINLIGHT_IS_MAINLIGHT)
		#if USE_FORWARD_PLUS
			int iLight = lightIndex;
		#else
			int iLight = loopCounter + MAINLIGHT_IS_MAINLIGHT;
			if (iLight != input.mainLightID)
		#endif
		{
			float notDirectional = 1.0f; //_WorldSpaceLightPos0.w of the legacy code.
			UtsLight additionalLight = GetUrpMainUtsLight(0, 0);
			if (iLight != MAINLIGHT_IS_MAINLIGHT)
			{
				additionalLight = GetAdditionalUtsLight(iLight, input.positionWS, input.positionCS);
			}
			half3 additionalLightColor = GetLightColor(additionalLight);

			float3 lightDirection = additionalLight.direction;
			
			float3 addPassLightColor = (0.5 * dot(input.normalDir, lightDirection)+0.5) * additionalLightColor.rgb;
			float pureIntencity = max(0.001, (0.299 * additionalLightColor.r + 0.587 * additionalLightColor.g + 0.114 * additionalLightColor.b));
			float3 lightColor = max(float3(0.0, 0.0, 0.0), lerp(addPassLightColor, lerp(float3(0.0, 0.0, 0.0), min(addPassLightColor, addPassLightColor / pureIntencity), notDirectional), _Is_Filter_LightColor));
			float3 halfDirection = normalize(viewDirection + lightDirection); // has to be recalced here.

			float NdotAL = dot(input.normalDir, normalize(lightDirection));

			float3 finalColor = lightColor * floatLerp(1, additionalLight.shadowAttenuation, _Set_AL_SystemShadowsToBase);

			finalColor = SATURATE_IF_SDR(finalColor);
 
			pointLightColor += finalColor  * _AdditionalLightWeight;

		}
		UTS_LIGHT_LOOP_END

	#endif
    // #endif
	//多光源描边


	float3 defaultLightDirection = normalize(UNITY_MATRIX_V[2].xyz + UNITY_MATRIX_V[1].xyz);
	float3 lightDirVS = normalize(mul((float3x3)UNITY_MATRIX_V, mainLight.direction));
	
	float lightMask = 1 - smoothstep(0.5, 0.8, abs(lightDirVS.z));
	float NdotL = max(0,dot(normalize(input.normalDir), defaultLightDirection));

	// float outLineLightResult = step(0.8, NdotL * NdotL) * lightMask;
	// #if defined(_DIRECTIONAL) //走的else
	// 	return half4(mainLight.color * outLineLightResult, 1);
	// #else
		// outLineLightResult = step(0.8, pow(NdotL, 3));
		//real return 
		if(pointLightColor.r > 0){
		    return half4(pointLightColor * lightMask, 1);
			// * lightMask
		}
		else{
			return half4(albedo, 1);
		}
		//end
		// return half4(lerp(albedo,pointLightColor,pointLightColor.r) * lightMask, 1);
		// return pointLightColor.r;
		// return lightMask;
		// return input.vertexColor;
		// return input.vertexColor.r;


	// return color;
}