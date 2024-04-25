//iMix/Toon   mix from : UTS3/NiloToon/Genshin/StartRail/ZoneZero/BRDF
//imixgold@gmail.com
//TODO : mix Start Rail render in FORWARD +

//TODO:金属高光，眼睛，鼻子描边，移除嘴角描边，procedural angle ring, addition light solve face sdf, solve pbr(now just npr when in addition lights shading)
//TODO: calculate sdf data(etc. dot product value) in vertex shader, not fragment shader to optimize
//TODO : custom bloom(etc. rim bloom )
//reference code:
//  half3 worldNormal = normalize(i.worldNormal);
//     half3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
//     half NdotL = max(0, dot(worldNormal, worldLightDir));
//     half rimBloom = pow (f, _RimBloomExp) * _RimBloomMulti * NdotL;
//     col.a = rimBloom;
// 传入alpha后，再自定义一个后处理bloom，然后和这个alpha进行乘算，可以和《离岛之歌》CG中一样，只在边缘光照射的区域有独特的bloom，非常
//漂亮（siteki） //https://zhuanlan.zhihu.com/p/111633226  后处理实现：https://zhuanlan.zhihu.com/p/36076204
// #include "iMixToonInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

#include "iMixToonPBR.hlsl"
#include "iMixToonHead.hlsl"
#include "iMixToonUtilities.hlsl"

struct VertexInput
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
	float2 texcoord0 : TEXCOORD0;
	float2 texcoord1 : TEXCOORD1; // 第二套UV
	float3 vertexColor : COLOR;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VertexOutput
{
	float3 vertexColor : TEXCOORD12; // 自定义的必须放在SV_POSITION之前 //可能和之后的某个宏有关，哇嘎奈
	float3 SH : TEXCOORD13;
	float4 pos : SV_POSITION;
	float2 uv0 : TEXCOORD0;
	float2 uv1 : TEXCOORD1;
	float4 posWorld : TEXCOORD2;
	float3 normalDir : TEXCOORD3;
	float3 tangentDir : TEXCOORD4;
	float3 bitangentDir : TEXCOORD5;
	
	float mirrorFlag : TEXCOORD6;

	DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 7);
	#if defined(_ADDITIONAL_LIGHTS_VERTEX) || (VERSION_LOWER(12, 0))
		half4 fogFactorAndVertexLight : TEXCOORD8; // x: fogFactor, yzw: vertex light
	#else
		half fogFactor : TEXCOORD8; // x: fogFactor, yzw: vertex light
	#endif
	#ifndef _MAIN_LIGHT_SHADOWS
		float4 positionCS : TEXCOORD9;
		int mainLightID : TEXCOORD10;
	#else
		float4 shadowCoord : TEXCOORD9;
		float4 positionCS : TEXCOORD10;
		int mainLightID : TEXCOORD11;
	#endif
	

	UNITY_VERTEX_INPUT_INSTANCE_ID
	UNITY_VERTEX_OUTPUT_STEREO
	// LIGHTING_COORDS(7, 8)
	// UNITY_FOG_COORDS(9)

};
VertexOutput vert(VertexInput v)
{
	VertexOutput o = (VertexOutput)0;

	UNITY_SETUP_INSTANCE_ID(v);
	UNITY_TRANSFER_INSTANCE_ID(v, o);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

	o.uv0 = v.texcoord0;
	o.uv1 = v.texcoord1;  //第二套uv，用于细节纹理等， 在gf2里我用于头发（第二套uv做上下移动的高光）
	o.vertexColor = v.vertexColor;

	//
	o.normalDir = UnityObjectToWorldNormal(v.normal);
	o.SH = SampleSH(lerp(o.normalDir, float3(0, 0, 0), _IndirectLightFlattenNormal));

	o.tangentDir = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz);
	o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
	o.posWorld = mul(unity_ObjectToWorld, v.vertex);

	o.pos = UnityObjectToClipPos(v.vertex);
	//Detection of the inside the mirror (right or left-handed) o.mirrorFlag = -1 then "inside the mirror".

	float3 crossFwd = cross(UNITY_MATRIX_V[0].xyz, UNITY_MATRIX_V[1].xyz);
	o.mirrorFlag = dot(crossFwd, UNITY_MATRIX_V[2].xyz) < 0 ? 1 : - 1;
	

	float3 positionWS = TransformObjectToWorld(v.vertex.xyz);
	float4 positionCS = TransformWorldToHClip(positionWS);
	half3 vertexLight = VertexLighting(o.posWorld.xyz, o.normalDir);
	half fogFactor = ComputeFogFactor(positionCS.z);

	OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
	#if UNITY_VERSION >= 202317
		OUTPUT_SH4(positionWS, o.normalDir.xyz, GetWorldSpaceNormalizeViewDir(positionWS), o.vertexSH);
	#elif UNITY_VERSION >= 202310
		OUTPUT_SH(positionWS, o.normalDir.xyz, GetWorldSpaceNormalizeViewDir(positionWS), o.vertexSH);
	#else
		OUTPUT_SH(o.normalDir.xyz, o.vertexSH);
	#endif

	#if defined(_ADDITIONAL_LIGHTS_VERTEX) || (VERSION_LOWER(12, 0))
		o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
	#else
		o.fogFactor = fogFactor;
	#endif
	
	o.positionCS = positionCS;
	#if defined(_MAIN_LIGHT_SHADOWS) && !defined(_RECEIVE_SHADOWS_OFF)
		#if SHADOWS_SCREEN
			o.shadowCoord = ComputeScreenPos(positionCS);
		#else
			o.shadowCoord = TransformWorldToShadowCoord(o.posWorld.xyz);
		#endif
		o.mainLightID = DetermineUTS_MainLightIndex(o.posWorld.xyz, o.shadowCoord, positionCS);
	#else
		o.mainLightID = DetermineUTS_MainLightIndex(o.posWorld.xyz, 0, positionCS);
	#endif
	return o;
	// 	Light mainLight = GetMainLight(); //gf2 some further face sdf optimize
	// float3 lightDirWS = mainLight.direction;
	// lightDirWS.xz = normalize(lightDirWS.xz);
	// _FaceRightDirWS.xz = normalize(_FaceRightDirWS.xz);
	// o.faceLightDot.x = dot(lightDirWS.xz, _FaceRightDirWS.xz);
	// o.faceLightDot.y = saturate(dot(-lightDirWS.xz, _FaceFrontDirWS.xz) * 0.5 + _ShadowOffset);

}
float4 frag(VertexOutput i, fixed facing : VFACE) : SV_TARGET
{
	i.normalDir = normalize(i.normalDir);
	float3x3 tangentTransform = float3x3(i.tangentDir, i.bitangentDir, i.normalDir);
	float3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWorld.xyz);

	float3 _NormalMap_var = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_linear_clamp_MainTex, TRANSFORM_TEX(i.uv0, _NormalMap)), _BumpScale);

	float3 normalLocal = _NormalMap_var.rgb;
	float3 normalDirection = normalize(mul(normalLocal, tangentTransform)); // Perturbed normals


	// todo. not necessary to calc gi factor in  shadowcaster pass.
	SurfaceData surfaceData;
	InitializeStandardLitSurfaceDataUTS(i.uv0, surfaceData);

	InputData inputData;
	Varyings  input = (Varyings)0;
	// todo.  it has to be cared more.
	// UNITY_SETUP_INSTANCE_ID(input);
	// UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
	#ifdef LIGHTMAP_ON
	#else
		input.vertexSH = i.vertexSH;
	#endif

	input.uv = i.uv0;
	input.positionCS = i.pos;
	#if defined(_ADDITIONAL_LIGHTS_VERTEX) || (VERSION_LOWER(12, 0))
		input.fogFactorAndVertexLight = i.fogFactorAndVertexLight;
	#else
		input.fogFactor = i.fogFactor;
	#endif

	#ifdef REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR  //useless
		input.shadowCoord = i.shadowCoord;
	#endif
	#ifdef REQUIRES_WORLD_SPACE_POS_INTERPOLATOR  //useless
		input.positionWS = i.posWorld.xyz;
	#endif

	#ifdef _NORMALMAP   //uselsee , valid for #else
		input.normalWS = half4(i.normalDir, viewDirection.x);      // xyz: normal, w: viewDir.x
		input.tangentWS = half4(i.tangentDir, viewDirection.y);        // xyz: tangent, w: viewDir.y
		#if (VERSION_LOWER(7, 5))
			input.bitangentWS = half4(i.bitangentDir, viewDirection.z);    // xyz: bitangent, w: viewDir.z
		#endif
	#else //valid
		input.normalWS = half3(i.normalDir);
		#if (VERSION_LOWER(12, 0))
			input.viewDirWS = half3(viewDirection);
		#endif //(VERSION_LOWER(12, 0))
	#endif

	InitializeInputData(input, surfaceData.normalTS, inputData);

	BRDFData brdfData;
	InitializeBRDFData(surfaceData.albedo,
	surfaceData.metallic,
	surfaceData.specular,
	surfaceData.smoothness,
	surfaceData.alpha, brdfData);

	half3 envColor = GlobalIlluminationUTS(brdfData, inputData.bakedGI, surfaceData.occlusion, inputData.normalWS, inputData.viewDirectionWS, i.posWorld.xyz, inputData.normalizedScreenSpaceUV);
	envColor *= 1.8f; // ??
	

	UtsLight mainLight = GetMainUtsLightByID(i.mainLightID, i.posWorld.xyz, inputData.shadowCoord, i.positionCS);
	half3 mainLightColor = GetLightColor(mainLight);

	float4 lightMap = 0;
	#if _AREA_HAIR || _AREA_BODY
		{
			#if _AREA_HAIR
				lightMap = SAMPLE_TEXTURE2D(_HairLightMap, sampler_HairLightMap, input.uv);
			#elif _AREA_BODY
				lightMap = SAMPLE_TEXTURE2D(_BodyLightMap, sampler_BodyLightMap, input.uv);
			#endif
		}
	#endif

	float shadowAttenuation = 1.0;

	#if defined(_MAIN_LIGHT_SHADOWS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE) || defined(_MAIN_LIGHT_SHADOWS_SCREEN)
		shadowAttenuation = mainLight.shadowAttenuation;
	#endif
	
	float4 startRailNormalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv);
	float4 pbrMask = SAMPLE_TEXTURE2D(_PBRMask, sampler_PBRMask, input.uv);


	//Begin
	float4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp_MainTex, TRANSFORM_TEX(i.uv0, _MainTex));
	float4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp_MainTex, TRANSFORM_TEX(i.uv0, _MainTex)) * _BaseColor;

	float3 defaultLightDirection = normalize(UNITY_MATRIX_V[2].xyz + UNITY_MATRIX_V[1].xyz);
	
	float3 defaultLightColor = saturate(max(half3(0.05, 0.05, 0.05) * _Unlit_Intensity, max(ShadeSH9(half4(0.0, 0.0, 0.0, 1.0)), ShadeSH9(half4(0.0, -1.0, 0.0, 1.0)).rgb) * _Unlit_Intensity));
	float3 customLightDirection = normalize(mul(unity_ObjectToWorld, float4(((float3(1.0, 0.0, 0.0) * _Offset_X_Axis_BLD * 10) + (float3(0.0, 1.0, 0.0) * _Offset_Y_Axis_BLD * 10) + (float3(0.0, 0.0, -1.0) * lerp(-1.0, 1.0, _Inverse_Z_Axis_BLD))), 0)).xyz);
	float3 lightDirection = normalize(lerp(defaultLightDirection, mainLight.direction.xyz, any(mainLight.direction.xyz)));
	lightDirection = lerp(lightDirection, customLightDirection, _Is_BLD);
	
	half3 originalLightColor = mainLightColor.rgb;
	float3 lightColor = lerp(max(defaultLightColor, originalLightColor), max(defaultLightColor, saturate(originalLightColor)), _Is_Filter_LightColor);


	// Lighting:
	float3 halfDirection = normalize(viewDirection + lightDirection);

	// float3 Set_LightColor = lightColor.rgb;
	float3 startRailMainLightColor = lerp(desaturation(lightColor.rgb), lightColor.rgb, _MainLightColorUsage); // 还没用，用的时候代替Set_LightColor
	float3 Set_LightColor = startRailMainLightColor;
	
	// Varients for PBR caclulation start
	float3 normal = normalize(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase));
	float3 tangent = normalize(i.tangentDir.xyz);
	float3 bitangent = normalize(i.bitangentDir.xyz);

	half lightmapAO_NPR = 1; //lightmapresult AO
	
	half lightmapValue_AO = dot(lightMap, _LightMapChannelMask_AO);
	lightmapValue_AO = floatLerp(1, lightmapValue_AO, _LightMapStrength);
	lightmapValue_AO = invLerpClamp(_LightMapRemapStart, _LightMapRemapEnd, lightmapValue_AO);
	lightmapAO_NPR = lerp(1, lightmapValue_AO, _UselightmapAO);

	int rampRowIndex = 0;
	int rampRowNum = 1;

	float4 faceMap = 0;

	//the value of shadowAttenuation is darker than legacy and it cuases noise in terminaters.
	#if !defined(UTS_USE_RAYTRACING_SHADOW)
		shadowAttenuation *= 2.0f;
		shadowAttenuation = saturate(shadowAttenuation);
	#endif

	
	float3 fixedLightDirection = normalize(float3Lerp(lightDirection, float3(lightDirection.x, 0, lightDirection.z), _LightingDirectionFix));
	float NdotFixL = dot(normal, fixedLightDirection);

	// float halfLambert = 0.5 * dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase), lightDirection) + 0.5; // 不是完全的Half Lambert,少了一个平方 by 柠檬养乐多
	float NdotFixLRemap = 0.5 * dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase), fixedLightDirection) + 0.5;

	half litOrShadowArea = smoothstep(_CelShadeMidPoint - _CelShadeSoftness, _CelShadeMidPoint + _CelShadeSoftness, NdotFixL - _CelShadowBias);
	litOrShadowArea *= lightmapAO_NPR;
    float noseSpecArea = 0;
	#if _AREA_FACE  // face ignore celshade if not enable SDF Face Shadow
		//这些计算放在vertex shader里更省
		float3 headForward = normalize(_HeadForward);
		float3 headRight = normalize(_HeadRight);
		float3 headUp = cross(headForward, headRight);

		float3 fixedLightDirectionWS = normalize(lightDirection - dot(lightDirection, headUp) * headUp); //光向量投影到头坐标系的水平面，否则人物倒过来阴影会是反的
		// float2 sdfUV = float2(sign(dot(fixedLightDirectionWS, headRight)), 1) * i.uv0 * float2(-1, 1); startrail  判断在脸左还是在脸右
		float2 sdfUV = float2(sign(dot(fixedLightDirectionWS, headRight)), 1) * i.uv1 * float2(-1, 1); //gf2 use uv1 for face sdf shadow ,是正面还是背面
		// faceMap = SAMPLE_TEXTURE2D_LOD(_FaceMap, sampler_FaceMap, sdfUV, 3); zone zero cause sdf texture is weired
		faceMap = SAMPLE_TEXTURE2D(_FaceMap, sampler_FaceMap, sdfUV); // gf2
		float sdfValue = dot(faceMap, _LightMapChannelMask_Face);
		// float sdfValue = faceMap.r;
		sdfValue += _FaceShadowOffset;
		float sdfThreshold = 1 - (dot(fixedLightDirectionWS, headForward) * 0.5 + 0.5); //这个点是光照还是阴影，从-1到1映射到0到1
		float sdf = smoothstep(sdfThreshold - _FaceShadowTransitionSoftness, sdfThreshold + _FaceShadowTransitionSoftness, sdfValue);
		// float sdf = step(sdfThreshold, sdfValue); //no smoothstep
		// litOrShadowArea = step(0.5, faceMap.a); //startrail
		litOrShadowArea = lerp(floatLerp(0.5, 1, litOrShadowArea), sdf * faceMap.a, _EnableFaceSDF) ; //faceMap.a = sdf area
		//这里我就不做channel mask了，一般的sdf图的a通道都是mask
		// return sdf; //return test step by step

		// float2 faceLightMapUV = UV1; //这是将来如果优化相关dot value计算放到vertex的话，那部分代码对应的frag内容，应该要和上面的做一些结合/替换。
		// faceLightMapUV.x = 1 - faceLightMapUV.x;
		// faceLightMapUV.x = i.faceLightDot.x < 0 ? 1 - faceLightMapUV.x : faceLightMapUV.x;
		// half4 faceLightMap = SAMPLE_TEXTURE2D(_FaceLightMap, sampler_FaceLightMap, faceLightMapUV);
		// half faceSDF = faceLightMap.r;
		// half faceShadowArea = faceLightMap.a;
		// float faceMapShadow = sigmoid(faceSDF, i.faceLightDot.y, _ShadowSmooth * 10) * faceShadowArea;
		// shadowArea = (1 - faceMapShadow) * _ShadowStrength;

		float faceSpecStep = 1 - sdfThreshold;
		// faceSpecStep += sign(dot(-fixedLightDirectionWS, headRight)) * _test1;
		float noseSpecArea1 = step(faceSpecStep + sign(dot(-fixedLightDirectionWS, headRight)) * 0.5, faceMap.g);
		float noseSpecArea2 = step(1 - faceSpecStep - sign(dot(-fixedLightDirectionWS, headRight)) * _test2, faceMap.b);
		noseSpecArea = noseSpecArea1 * noseSpecArea2;
		// noseSpecArea = noseSpecArea1;
		//alternative: 
		noseSpecArea *= smoothstep(0.42, 0.72, 1 - (saturate(dot(-lightDirection.xz, headForward.xz)) * 0.5 + 0.5));
		litOrShadowArea += noseSpecArea;
		rampRowIndex = 0;
		rampRowNum = 8; //sr
		// rampRowNum = 4; //gf2
		// return noseSpecArea ;
	#endif
	// Eye
	#if _AREA_EYES
		// Eye spec add 叠加高光
		// BlendOp [_BlendOp]// Add
		// Blend [_BlendSrc] [_BlendDst]// SrcAlpha One
		// Eye shadow blend 乘算眼上半阴影
		// BlendOp [_BlendOp]// Add
		// Blend [_BlendSrc] [_BlendDst]// SrcColor Zero //应该是写错了，_BlendSrc的值应该是DstColor，表示源颜色（阴影色）和缓冲区颜色相乘，然后把目标缓冲区颜色设置为0，再相加
		// Parallax
		float3 viewDirOS = TransformWorldToObjectDir(viewDirection);
		viewDirOS = normalize(viewDirOS);
		float2 parallaxOffset = viewDirOS.xy;
		parallaxOffset.y *= -1;
		float2 parallaxUV = i.uv0 + _ParallaxScale * parallaxOffset;
		// parallaxMask
		float2 centerVec = i.uv0 - float2(0.5, 0.5);
		half centerDist = dot(centerVec, centerVec);
		half parallaxMask = smoothstep(_ParallaxMaskEdge, _ParallaxMaskEdge + _ParallaxMaskEdgeOffset, 1 - centerDist);
		// Tex Sample
		half4 eyeTex = SAMPLE_TEXTURE2D(_MainTex, sampler_linear_clamp_MainTex, saturate(lerp(i.uv0, parallaxUV, parallaxMask))); //要saturate uv，不然侧面压缩后会出现两个眼睛
		// half4 eyeTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, lerp(i.uv0, parallaxUV, parallaxMask));
		return eyeTex;
	#endif

	#if _AREA_OTHERS
		litOrShadowArea = floatLerp(0.5, 1, litOrShadowArea);
	#endif
	
	// light's shadow map final calculate
	litOrShadowArea *= floatLerp(1, shadowAttenuation, _Set_SystemShadowsToBase);  //litOrShadowArea = NdotLRemapped
	half3 litOrShadowColor = float3Lerp(_ShadowMapColor, 1, litOrShadowArea);
    

	float3 Set_FinalBaseColor = albedo.rgb * litOrShadowColor * Set_LightColor;
	

	// Ramp start
	#if _AREA_HAIR
		rampRowIndex = 0;
		rampRowNum = 1; //sr
		// rampRowNum = 4; //gf2
	#elif _AREA_BODY
		int rawIndex = (round((lightMap.a + 0.0425) / 0.0625) - 1) / 2; //startail 的算法因为他由lightmap.a，gf2我这没有
		rampRowIndex = lerp(rawIndex, rawIndex + 4 < 8 ? rawIndex + 4 : rawIndex + 4 - 8, fmod(rawIndex, 2));
		// rampRowIndex = 1;
		rampRowNum = 8; //sr
		// rampRowNum = 4; //gf2
	#endif
	float rampUVx = litOrShadowArea* (1 - _ShadowRampOffset) + _ShadowRampOffset;  // 变化集中在3/4处，挤压一下(没什么吊用删了)
	// float rampUVx = litOrShadowArea;
	float rampUVy = (2 * rampRowIndex + 1) * (1.0 / (rampRowNum * 2)); 
	// float rampUVy = _test1;
	// float rampUVy = 0; //gf2 好像ramp有点问题，要么就是我有点问题 
	float2 rampUV = float2(rampUVx, rampUVy);
	float3 coolRamp = 1;
	float3 warmRamp = 1;
	#if _AREA_FACE || _AREA_BODY || _AREA_HAIR
		coolRamp = SAMPLE_TEXTURE2D(_CoolRamp, sampler_CoolRamp, rampUV);
		warmRamp = SAMPLE_TEXTURE2D(_WarmRamp, sampler_WarmRamp, rampUV);
	#endif
	float isDay = lightDirection.y * 0.5 + 0.5;
	float3 rampColor = lerp(coolRamp, warmRamp, isDay);
	// Set_FinalBaseColor = lerp(Set_FinalBaseColor, Set_FinalBaseColor * step(0.25, startRailNormalMap.b), _UseRampShadow); //startrail
	Set_FinalBaseColor = lerp(Set_FinalBaseColor, Set_FinalBaseColor * rampColor, _UseRampShadow);
    
	// #if _AREA_BODY
    // return float4(rampColor,1);
	// #endif

	//Specular
	float3 specularColor = 0;

	// #if _AREA_HAIR || _AREA_BODY //startrail
	#if _AREA_BODY //just npr body/(or if has weapons) need specular , skin/face/hair have its own specular defined.

		{
			float3 halfVectorWS = normalize(viewDirection + lightDirection);
			float NoH = dot(i.normalDir, halfVectorWS);
			float blinnPhong = pow(saturate(NoH), _SpecularExpon);

			float nonMetalSpecular = step(1.04 - blinnPhong, lightMap.b) * _SpecularKsNonMetal;
			float metalSpecular = blinnPhong * lightMap.b * _SpecularKsMetal;

			float metallic = 0;
			#if _AREA_BODY
				// metallic = saturate((abs(lightMap.a - _test1) - 0.1) / (0 - 0.1));
				metallic = lightMap.a;
			#endif
			specularColor = lerp(nonMetalSpecular, metalSpecular * albedo.rgb * Set_LightColor, metallic);
			specularColor *= mainLight.color;
			specularColor *= _SpecularBrightness;
		}
	#endif

	
	//UTS highcolor
	float4 _Set_HighColorMask_var = tex2D(_Set_HighColorMask, TRANSFORM_TEX(i.uv0, _Set_HighColorMask));

	float _Specular_var = 0.5 * dot(halfDirection, lerp(i.normalDir, normalDirection, _Is_NormalMapToHighColor)) + 0.5; // Specular
	float _TweakHighColorMask_var = (saturate((_Set_HighColorMask_var.g + _Tweak_HighColorMaskLevel)) * lerp((1.0 - step(_Specular_var, (1.0 - pow(abs(_HighColor_Power), 5)))), pow(abs(_Specular_var), exp2(lerp(11, 1, _HighColor_Power))), _Is_SpecularToHighColor));

	float4 _HighColor_Tex_var = tex2D(_HighColor_Tex, TRANSFORM_TEX(i.uv0, _HighColor_Tex));

	float3 _HighColor_var = (lerp((_HighColor_Tex_var.rgb * _HighColor.rgb), ((_HighColor_Tex_var.rgb * _HighColor.rgb) * Set_LightColor), _Is_LightColor_HighColor) * _TweakHighColorMask_var);
	//Composition: 3 Basic Colors and HighColor as Set_HighColor
	float3 Set_HighColor = (lerp(SATURATE_IF_SDR((Set_FinalBaseColor - _TweakHighColorMask_var)), Set_FinalBaseColor, lerp(_Is_BlendAddToHiColor, 1.0, _Is_SpecularToHighColor)) + lerp(_HighColor_var, (_HighColor_var * ((1.0 - litOrShadowArea) + (litOrShadowArea * _TweakHighColorOnShadow))), _Is_UseTweakHighColorOnShadow));
    //SATURATE_IF_SDR 换成saturate了

	//Rimlight
	//UTS Rimlight
	float4 _Set_RimLightMask_var = tex2D(_Set_RimLightMask, TRANSFORM_TEX(i.uv0, _Set_RimLightMask));

	float3 _Is_LightColor_RimLight_var = lerp(_RimLightColor.rgb, (_RimLightColor.rgb * Set_LightColor), _Is_LightColor_RimLight);
	float _RimArea_var = abs(1.0 - dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToRimLight), viewDirection));
	float _RimLightPower_var = pow(_RimArea_var, exp2(lerp(3, 0, _RimLight_Power)));
	float _Rimlight_InsideMask_var = saturate(lerp((0.0 + ((_RimLightPower_var - _RimLight_InsideMask) * (1.0 - 0.0)) / (1.0 - _RimLight_InsideMask)), step(_RimLight_InsideMask, _RimLightPower_var), _RimLight_FeatherOff));
	float _VertHalfLambert_var = 0.5 * dot(i.normalDir, lightDirection) + 0.5;
	float3 _LightDirection_MaskOn_var = lerp((_Is_LightColor_RimLight_var * _Rimlight_InsideMask_var), (_Is_LightColor_RimLight_var * saturate((_Rimlight_InsideMask_var - ((1.0 - _VertHalfLambert_var) + _Tweak_LightDirection_MaskLevel)))), _LightDirection_MaskOn);
	float _ApRimLightPower_var = pow(_RimArea_var, exp2(lerp(3, 0, _Ap_RimLight_Power)));
	float3 Set_RimLight = (saturate((_Set_RimLightMask_var.g + _Tweak_RimLightMaskLevel)) * lerp(_LightDirection_MaskOn_var, (_LightDirection_MaskOn_var + (lerp(_Ap_RimLightColor.rgb, (_Ap_RimLightColor.rgb * Set_LightColor), _Is_LightColor_Ap_RimLight) * saturate((lerp((0.0 + ((_ApRimLightPower_var - _RimLight_InsideMask) * (1.0 - 0.0)) / (1.0 - _RimLight_InsideMask)), step(_RimLight_InsideMask, _ApRimLightPower_var), _Ap_RimLight_FeatherOff) - (saturate(_VertHalfLambert_var) + _Tweak_LightDirection_MaskLevel))))), _Add_Antipodean_RimLight));
	//Composition: HighColor and RimLight as _RimLight_var
	float3 _RimLight_var = float3(1, 1, 1); //fix bug


	//StartRail RimLight
	float3 rimLightColorFront = _RimLightFrontColor; // 向光区域边缘光颜色
    float3 rimLightColorBack = _RimLightBackColor; // 背光区域边缘光颜色
    // 判断向光或背光，并选择相应的边缘光颜色
    float3 rimLightColor = lerp(rimLightColorBack, rimLightColorFront, saturate(litOrShadowArea));

	float linearEyeDepth = LinearEyeDepth(input.positionCS.z, _ZBufferParams);
	float3 normalVS = mul((float3x3)UNITY_MATRIX_V, inputData.normalWS);
	float2 uvOffset = float2(sign(normalVS.x), 0) * _RimLightWidth / (1 + linearEyeDepth) / 100;
	int2 loadTexPos = input.positionCS.xy + uvOffset * _ScaledScreenParams.xy;
	loadTexPos = min(max(loadTexPos, 0), _ScaledScreenParams.xy - 1);
	float offsetSceneDepth = LoadSceneDepth(loadTexPos);
	float offsetLinearEyeDepth = LinearEyeDepth(offsetSceneDepth, _ZBufferParams);
	float rimLightMask = saturate(offsetLinearEyeDepth - (linearEyeDepth + _RimLightThreshold)) / _RimLightFadeout;
	rimLightColor *= rimLightMask;
	rimLightColor *= _RimLightBrightness;

	#if _StartRailRimlight_ON
		// Set_RimLight = rimLightColor;
		Set_RimLight = rimLightColor * lerp(1, baseColor, _RimLightMixAlbedo);
		// Set_RimLight = rimLightColor;
	#endif

	// _RimLight_var = lerp(Set_HighColor, (Set_HighColor + Set_RimLight), _RimLight);
	_RimLight_var = lerp(Set_HighColor, (Set_HighColor + Set_RimLight), _RimLight);


	//Matcap
	//CameraRolling Stabilizer
	//Mirror Script Determination: if sign_Mirror = -1, determine "Inside the mirror".
	
	fixed _sign_Mirror = i.mirrorFlag;
	
	float3 _Camera_Right = UNITY_MATRIX_V[0].xyz;
	float3 _Camera_Front = UNITY_MATRIX_V[2].xyz;
	float3 _Up_Unit = float3(0, 1, 0);
	float3 _Right_Axis = cross(_Camera_Front, _Up_Unit);
	//Invert if it's "inside the mirror".
	if (_sign_Mirror < 0)
	{
		_Right_Axis = -1 * _Right_Axis;
		_Rotate_MatCapUV = -1 * _Rotate_MatCapUV;
	}
	else
	{
		_Right_Axis = _Right_Axis;
	}
	float _Camera_Right_Magnitude = sqrt(_Camera_Right.x * _Camera_Right.x + _Camera_Right.y * _Camera_Right.y + _Camera_Right.z * _Camera_Right.z);
	float _Right_Axis_Magnitude = sqrt(_Right_Axis.x * _Right_Axis.x + _Right_Axis.y * _Right_Axis.y + _Right_Axis.z * _Right_Axis.z);
	float _Camera_Roll_Cos = dot(_Right_Axis, _Camera_Right) / (_Right_Axis_Magnitude * _Camera_Right_Magnitude);
	float _Camera_Roll = acos(clamp(_Camera_Roll_Cos, -1, 1));
	fixed _Camera_Dir = _Camera_Right.y < 0 ? - 1 : 1;
	float _Rot_MatCapUV_var_ang = (_Rotate_MatCapUV * 3.141592654) - _Camera_Dir * _Camera_Roll * _CameraRolling_Stabilizer;
	
	float2 _Rot_MatCapNmUV_var = RotateUV(i.uv0, (_Rotate_NormalMapForMatCapUV * 3.141592654), float2(0.5, 0.5), 1.0);

	float3 _NormalMapForMatCap_var = UnpackNormalScale(tex2D(_NormalMapForMatCap, TRANSFORM_TEX(_Rot_MatCapNmUV_var, _NormalMapForMatCap)), _BumpScaleMatcap);

	//MatCap with camera skew correction
	float3 viewNormal = (mul(UNITY_MATRIX_V, float4(lerp(i.normalDir, mul(_NormalMapForMatCap_var.rgb, tangentTransform).rgb, _Is_NormalMapForMatCap), 0))).rgb;
	float3 NormalBlend_MatcapUV_Detail = viewNormal.rgb * float3(-1, -1, 1);
	float3 NormalBlend_MatcapUV_Base = (mul(UNITY_MATRIX_V, float4(viewDirection, 0)).rgb * float3(-1, -1, 1)) + float3(0, 0, 1);
	float3 noSknewViewNormal = NormalBlend_MatcapUV_Base * dot(NormalBlend_MatcapUV_Base, NormalBlend_MatcapUV_Detail) / NormalBlend_MatcapUV_Base.b - NormalBlend_MatcapUV_Detail;
	float2 _ViewNormalAsMatCapUV = (lerp(noSknewViewNormal, viewNormal, _Is_Ortho).rg * 0.5) + 0.5;
	
	float2 _Rot_MatCapUV_var = RotateUV((0.0 + ((_ViewNormalAsMatCapUV - (0.0 + _Tweak_MatCapUV)) * (1.0 - 0.0)) / ((1.0 - _Tweak_MatCapUV) - (0.0 + _Tweak_MatCapUV))), _Rot_MatCapUV_var_ang, float2(0.5, 0.5), 1.0);
	//If it is "inside the mirror", flip the UV left and right.

	if (_sign_Mirror < 0)
	{
		_Rot_MatCapUV_var.x = 1 - _Rot_MatCapUV_var.x;
	}
	else
	{
		_Rot_MatCapUV_var = _Rot_MatCapUV_var;
	}

	float4 _MatCap_Sampler_var = tex2Dlod(_MatCap_Sampler, float4(TRANSFORM_TEX(_Rot_MatCapUV_var, _MatCap_Sampler), 0.0, _BlurLevelMatcap));
	float4 _Set_MatcapMask_var = tex2D(_Set_MatcapMask, TRANSFORM_TEX(i.uv0, _Set_MatcapMask));

	//MatcapMask
	float _Tweak_MatcapMaskLevel_var = saturate(lerp(_Set_MatcapMask_var.g, (1.0 - _Set_MatcapMask_var.g), _Inverse_MatcapMask) + _Tweak_MatcapMaskLevel);
	float3 _Is_LightColor_MatCap_var = lerp((_MatCap_Sampler_var.rgb * _MatCapColor.rgb), ((_MatCap_Sampler_var.rgb * _MatCapColor.rgb) * Set_LightColor), _Is_LightColor_MatCap);
	//ShadowMask on Matcap in Blend mode : multiply
	float3 Set_MatCap = lerp(_Is_LightColor_MatCap_var, (_Is_LightColor_MatCap_var * ((1.0 - litOrShadowArea) + (litOrShadowArea * _TweakMatCapOnShadow)) + lerp(Set_HighColor * litOrShadowArea * (1.0 - _TweakMatCapOnShadow), float3(0.0, 0.0, 0.0), _Is_BlendAddToMatCap)), _Is_UseTweakMatCapOnShadow);

	//Composition: RimLight and MatCap as finalColor
	//Broke down finalColor composition
	float3 matCapColorOnAddMode = _RimLight_var + Set_MatCap * _Tweak_MatcapMaskLevel_var;
	float _Tweak_MatcapMaskLevel_var_MultiplyMode = _Tweak_MatcapMaskLevel_var * lerp(1, (1 - (litOrShadowArea) * (1 - _TweakMatCapOnShadow)), _Is_UseTweakMatCapOnShadow);
	float3 matCapColorOnMultiplyMode = Set_HighColor * (1 - _Tweak_MatcapMaskLevel_var_MultiplyMode) + Set_HighColor * Set_MatCap * _Tweak_MatcapMaskLevel_var_MultiplyMode + lerp(float3(0, 0, 0), Set_RimLight, _RimLight);
	float3 matCapColorFinal = lerp(matCapColorOnMultiplyMode, matCapColorOnAddMode, _Is_BlendAddToMatCap);
	
	float3 finalColor = float3(1, 1, 1);
	float3 _Is_LightColor_AR_var = float3(1, 1, 1);
	// Angle Ring = AR  (angel ring is a special specular on hair)
	float ndotH = max(0, dot(inputData.normalWS, normalize(viewDirection + normalize(lightDirection))));
	float ndotV = max(0, dot(i.normalDir, viewDirection));
	float SpecularRange = step(1 - _HairSpecularRange, saturate(ndotH));
	float ViewRange = step(1 - _HairSpecularViewRange, saturate(ndotV));

	finalColor = lerp(_RimLight_var, matCapColorFinal, _MatCap);
	float _AngelRing_var_startrail = lightMap.b * SpecularRange * ViewRange * _HairSpecularIntensity * _AngelRing_Color.rgb;
	// float3 _Is_LightColor_AR_var = lerp(_AngelRing_var_startrail, _AngelRing_var_startrail * Set_LightColor, _Is_LightColor_AR);  //startrail angel ring

	float anisotropicOffsetV = -viewDirection.y * _AnisotropicSlide + _AnisotropicOffset;  //gf2 angel ring(uv1)
	float3 hairARTex_gf2 = SAMPLE_TEXTURE2D(_HairLightMap, sampler_LinearClamp, float2(i.uv1.x, i.uv1.y + anisotropicOffsetV));
	//sampler_LinearClamp 这个表示采样过滤是linear,超过(0,1)用clamp方式采样   //SAMPLER(sampler_LinearClamp);在shader里这样声明变量

	float hairARStrength_gf2 = _HairSpecularIntensity + pow(ndotH, _SpecularExpon) * litOrShadowArea ; //_HairSpecularIntensity in gf2 = min strength
	float3 hairARColor_gf2 = hairARTex_gf2 * _AngelRing_Color.rgb * hairARStrength_gf2 * SpecularRange * ViewRange;
	_Is_LightColor_AR_var = lerp(hairARColor_gf2, hairARColor_gf2 * Set_LightColor, _Is_LightColor_AR);


	finalColor = lerp(finalColor, finalColor + _Is_LightColor_AR_var, _AngelRing); // Final Composition before Emissive
	
	

	
	#ifdef _EMISSIVE_SIMPLE
		float4 _Emissive_Tex_var = tex2D(_Emissive_Tex, TRANSFORM_TEX(i.uv0, _Emissive_Tex));
		float emissiveMask = _Emissive_Tex_var.a;
		emissive = _Emissive_Tex_var.rgb * _Emissive_Color.rgb * emissiveMask;
	#elif _EMISSIVE_ANIMATION
		//\Calculation View Coord UV for Scroll
		float3 viewNormal_Emissive = (mul(UNITY_MATRIX_V, float4(i.normalDir, 0))).xyz;
		float3 NormalBlend_Emissive_Detail = viewNormal_Emissive * float3(-1, -1, 1);
		float3 NormalBlend_Emissive_Base = (mul(UNITY_MATRIX_V, float4(viewDirection, 0)).xyz * float3(-1, -1, 1)) + float3(0, 0, 1);
		float3 noSknewViewNormal_Emissive = NormalBlend_Emissive_Base * dot(NormalBlend_Emissive_Base, NormalBlend_Emissive_Detail) / NormalBlend_Emissive_Base.z - NormalBlend_Emissive_Detail;
		float2 _ViewNormalAsEmissiveUV = noSknewViewNormal_Emissive.xy * 0.5 + 0.5;
		float2 _ViewCoord_UV = RotateUV(_ViewNormalAsEmissiveUV, - (_Camera_Dir * _Camera_Roll), float2(0.5, 0.5), 1.0);
		//鏡の中ならUV左右反転.
		if (_sign_Mirror < 0)
		{
			_ViewCoord_UV.x = 1 - _ViewCoord_UV.x;
		}
		else
		{
			_ViewCoord_UV = _ViewCoord_UV;
		}
		float2 emissive_uv = lerp(i.uv0, _ViewCoord_UV, _Is_ViewCoord_Scroll);
		//
		float4 _time_var = _Time;
		float _base_Speed_var = (_time_var.g * _Base_Speed);
		float _Is_PingPong_Base_var = lerp(_base_Speed_var, sin(_base_Speed_var), _Is_PingPong_Base);
		float2 scrolledUV = emissive_uv + float2(_Scroll_EmissiveU, _Scroll_EmissiveV) * _Is_PingPong_Base_var;
		float rotateVelocity = _Rotate_EmissiveUV * 3.141592654;
		float2 _rotate_EmissiveUV_var = RotateUV(scrolledUV, rotateVelocity, float2(0.5, 0.5), _Is_PingPong_Base_var);
		float4 _Emissive_Tex_var = tex2D(_Emissive_Tex, TRANSFORM_TEX(i.uv0, _Emissive_Tex));
		float emissiveMask = _Emissive_Tex_var.a;
		_Emissive_Tex_var = tex2D(_Emissive_Tex, TRANSFORM_TEX(_rotate_EmissiveUV_var, _Emissive_Tex));
		float _colorShift_Speed_var = 1.0 - cos(_time_var.g * _ColorShift_Speed);
		float viewShift_var = smoothstep(0.0, 1.0, max(0, dot(normalDirection, viewDirection)));
		float4 colorShift_Color = lerp(_Emissive_Color, lerp(_Emissive_Color, _ColorShift, _colorShift_Speed_var), _Is_ColorShift);
		float4 viewShift_Color = lerp(_ViewShift, colorShift_Color, viewShift_var);
		float4 emissive_Color = lerp(colorShift_Color, viewShift_Color, _Is_ViewShift);
		emissive = emissive_Color.rgb * _Emissive_Tex_var.rgb * emissiveMask;
	#endif
	

	float3 envLightColor = envColor.rgb * albedo.rgb;
	float envLightIntensity = 0.299 * envLightColor.r + 0.587 * envLightColor.g + 0.114 * envLightColor.b < 1 ? (0.299 * envLightColor.r + 0.587 * envLightColor.g + 0.114 * envLightColor.b) : 1;

	
	// _ADDITIONAL_LIGHTS Start
	float3 pointLightColor = 0;
	#ifdef _ADDITIONAL_LIGHTS

		int pixelLightCount = GetAdditionalLightsCount();

		// USE_FORWARD_PLUS Start
		#if USE_FORWARD_PLUS
			for (uint loopCounter = 0; loopCounter < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); loopCounter++)
			{
				int iLight = loopCounter;
				// if (iLight != i.mainLightID)

				{
					float notDirectional = 1.0f; //_WorldSpaceLightPos0.w of the legacy code.
					UtsLight additionalLight = GetUrpMainUtsLight(0, 0);
					additionalLight = GetAdditionalUtsLight(loopCounter, inputData.positionWS, i.positionCS);
					half3 additionalLightColor = GetLightColor(additionalLight);

					float3 lightDirection = additionalLight.direction;
					//
					float3 addPassLightColor = (0.5 * dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase), lightDirection) + 0.5) * additionalLightColor.rgb;
					float pureIntencity = max(0.001, (0.299 * additionalLightColor.r + 0.587 * additionalLightColor.g + 0.114 * additionalLightColor.b));
					float3 lightColor = max(float3(0.0, 0.0, 0.0), lerp(addPassLightColor, lerp(float3(0.0, 0.0, 0.0), min(addPassLightColor, addPassLightColor / pureIntencity), notDirectional), _Is_Filter_LightColor));
					float3 halfDirection = normalize(viewDirection + lightDirection); // has to be recalced here.

					//Filtering the high intensity zone of PointLights
					float3 Set_LightColor = lightColor;
					
					float halfLambert = 0.5 * dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase), lightDirection) + 0.5;
					
					float NdotAL = dot(i.normalDir, normalize(lightDirection));

					float litOrShadowArea_AL = smoothstep(_CelShadeMidPoint - _CelShadeSoftness, _CelShadeMidPoint + _CelShadeSoftness, NdotAL - _CelShadowBias);
					litOrShadowArea_AL *= lightmapAO_NPR;

					#if _AREA_FACE  // face ignore celshade
						if (!_EnableFaceSDF)
						{
							litOrShadowArea_AL = floatLerp(0.5, 1, litOrShadowArea);
						}
					#endif
					litOrShadowArea_AL *= floatLerp(1, additionalLight.shadowAttenuation, _Set_SystemShadowsToBase);
					half3 litOrShadowColor_AL = float3Lerp(_ShadowMapColor, 1, litOrShadowArea_AL);

					float3 finalColor = albedo * litOrShadowColor_AL * Set_LightColor;

					float4 _Set_HighColorMask_var = tex2D(_Set_HighColorMask, TRANSFORM_TEX(i.uv0, _Set_HighColorMask));
					float _Specular_var = 0.5 * dot(halfDirection, lerp(i.normalDir, normalDirection, _Is_NormalMapToHighColor)) + 0.5; //  Specular
					float _TweakHighColorMask_var = (saturate((_Set_HighColorMask_var.g + _Tweak_HighColorMaskLevel)) * lerp((1.0 - step(_Specular_var, (1.0 - pow(abs(_HighColor_Power), 5)))), pow(abs(_Specular_var), exp2(lerp(11, 1, _HighColor_Power))), _Is_SpecularToHighColor));

					float4 _HighColor_Tex_var = tex2D(_HighColor_Tex, TRANSFORM_TEX(i.uv0, _HighColor_Tex));

					float3 _HighColor_var = (lerp((_HighColor_Tex_var.rgb * _HighColor.rgb), ((_HighColor_Tex_var.rgb * _HighColor.rgb) * Set_LightColor), _Is_LightColor_HighColor) * _TweakHighColorMask_var);

					finalColor = finalColor + lerp(lerp(_HighColor_var, (_HighColor_var * ((1.0 - litOrShadowArea_AL) + (litOrShadowArea_AL * _TweakHighColorOnShadow))), _Is_UseTweakHighColorOnShadow), float3(0, 0, 0), _Is_Filter_HiCutPointLightColor);
					

					finalColor = SATURATE_IF_SDR(finalColor);
					// finalColor = saturate(finalColor);

					pointLightColor += finalColor;
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
			if (iLight != i.mainLightID)
		#endif
		{
			float notDirectional = 1.0f; //_WorldSpaceLightPos0.w of the legacy code.
			UtsLight additionalLight = GetUrpMainUtsLight(0, 0);
			if (iLight != MAINLIGHT_IS_MAINLIGHT)
			{
				additionalLight = GetAdditionalUtsLight(iLight, inputData.positionWS, i.positionCS);
			}
			half3 additionalLightColor = GetLightColor(additionalLight);

			float3 lightDirection = additionalLight.direction;
			
			float3 addPassLightColor = (0.5 * dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase), lightDirection) + 0.5) * additionalLightColor.rgb;
			float pureIntencity = max(0.001, (0.299 * additionalLightColor.r + 0.587 * additionalLightColor.g + 0.114 * additionalLightColor.b));
			float3 lightColor = max(float3(0.0, 0.0, 0.0), lerp(addPassLightColor, lerp(float3(0.0, 0.0, 0.0), min(addPassLightColor, addPassLightColor / pureIntencity), notDirectional), _Is_Filter_LightColor));
			float3 halfDirection = normalize(viewDirection + lightDirection); // has to be recalced here.

			//Filtering the high intensity zone of PointLights
			float3 Set_LightColor = lightColor;
			
			float halfLambert = 0.5 * dot(lerp(i.normalDir, normalDirection, _Is_NormalMapToBase), lightDirection) + 0.5;
			float NdotAL = dot(i.normalDir, normalize(lightDirection));
			
			float litOrShadowArea_AL = smoothstep(_CelShadeMidPoint - _CelShadeSoftness, _CelShadeMidPoint + _CelShadeSoftness, NdotAL - _CelShadowBias);
			litOrShadowArea_AL *= lightmapAO_NPR;
			#if _AREA_FACE  // face ignore celshade
				if (!_EnableFaceSDF)
				{
					litOrShadowArea_AL = floatLerp(0.5, 1, litOrShadowArea_AL);
				}
			#endif
			litOrShadowArea_AL *= floatLerp(1, additionalLight.shadowAttenuation, _Set_SystemShadowsToBase);
			half3 litOrShadowColor_AL = float3Lerp(_ShadowMapColor, 1, litOrShadowArea_AL);
			float3 finalColor = albedo * litOrShadowColor_AL * Set_LightColor;


			//Add HighColor if _Is_Filter_HiCutPointLightColor is False
			float4 _Set_HighColorMask_var = tex2D(_Set_HighColorMask, TRANSFORM_TEX(i.uv0, _Set_HighColorMask));
			float _Specular_var = 0.5 * dot(halfDirection, lerp(i.normalDir, normalDirection, _Is_NormalMapToHighColor)) + 0.5; //  Specular
			float _TweakHighColorMask_var = (saturate((_Set_HighColorMask_var.g + _Tweak_HighColorMaskLevel)) * lerp((1.0 - step(_Specular_var, (1.0 - pow(abs(_HighColor_Power), 5)))), pow(abs(_Specular_var), exp2(lerp(11, 1, _HighColor_Power))), _Is_SpecularToHighColor));

			float4 _HighColor_Tex_var = tex2D(_HighColor_Tex, TRANSFORM_TEX(i.uv0, _HighColor_Tex));

			float3 _HighColor_var = (lerp((_HighColor_Tex_var.rgb * _HighColor.rgb), ((_HighColor_Tex_var.rgb * _HighColor.rgb) * Set_LightColor), _Is_LightColor_HighColor) * _TweakHighColorMask_var);

			finalColor = finalColor + lerp(lerp(_HighColor_var, (_HighColor_var * ((1.0 - litOrShadowArea_AL) + (litOrShadowArea_AL * _TweakHighColorOnShadow))), _Is_UseTweakHighColorOnShadow), float3(0, 0, 0), _Is_Filter_HiCutPointLightColor);
			

			finalColor = SATURATE_IF_SDR(finalColor);
			// finalColor = saturate(finalColor);

			pointLightColor += finalColor;
			//	pointLightColor += lightColor;

		}
		UTS_LIGHT_LOOP_END

	#endif
	// _ADDITIONAL_LIGHTS End
    
	
	finalColor = SATURATE_IF_SDR(finalColor + emissive) * _FinalWeightNPR;
	//SATURATE_IF_SDR

	// finalColor = float3(lightMap.a,0,0);
	finalColor += pointLightColor * _AdditionalLightWeight; // 0.95 = addition lights final usage, no reason
	// finalColor += noseSpecArea;
	// finalColor += specularColor;  // startrail
	
	float3 finalNPR = 0;
	finalNPR = finalColor;

	//PBR begin
	float3 finalPBR = 0;
	half metallic = lerp(0, _metallic, 1 - pbrMask.r); //gril frontline2
	// half metallic = _metallic;
	half roughness = lerp(0, _roughness, pbrMask.g); //girl frontline2 (girl frontline = gf)
	// half roughness = _roughness;
	half directOcclusion_PBR = lerp(1 - _DirectOcclusion_PBR, 1, pbrMask.b); //gf2

	float3 brdf_simple = BRDF_Simple(lightDirection, viewDirection, normal, tangent, bitangent, baseColor, roughness, metallic, litOrShadowArea * 0.5 + 0.5);
	// float3 brdf_disney = BRDF_Disney(lightDirection, viewDirection, normal, tangent, bitangent, baseColor, roughness, metallic, litOrShadowArea);

	float3 sss = SSS(lightDirection, viewDirection, normal, albedo, roughness, metallic, litOrShadowArea);

	float3 pbr_result = brdf_simple;
	pbr_result *= directOcclusion_PBR;
	//  PBR Env Light
	float3 brdf_env_simple = BRDF_Indirect_Simple(lightDirection, viewDirection, normal, tangent, bitangent, baseColor);
	float3 brdf_env = BRDF_Indirect(lightDirection, viewDirection, normal, tangent, bitangent, baseColor, roughness, metallic);
	
	float3 env_result = brdf_env;

	//UTS的PBR Env不一定比一个卡通的indirectlight要好，会有写实感
	float3 indirectLightColor = i.SH.rgb * _IndirectLightUsage; //柠檬养乐多 startrail的做法
	// #if _AREA_HAIR || _AREA_UPPERBODY || _AREA_LOWERBODY
	// indirectLightColor *= lerp(1,lightMap.r, _IndirectLightOcclusionUsage);
	// #else
	// indirectLightColor *= lerp(1, lerp(faceMap.g,1,step(faceMap.r,0.5)),_IndirectLightOcclusionUsage);
	// #endif
	indirectLightColor *= lerp(1,albedo,_IndirectLightMixBaseColor); //so re de yi

	half3 envUTS = envLightColor * envLightIntensity * _GI_Intensity * smoothstep(1, 0, envLightIntensity / 2);
	half3 envResult = lerp(envUTS, indirectLightColor, _EnvLerp);

	// finalPBR = _WeightBRDF * pbr_result + _WeightEnvLight * env_result + sss * _sssColor * _SSSWeightPBR; //env没啥效果，用UTS3的env了
	finalPBR = _WeightBRDF * pbr_result + sss * _sssColor * _SSSWeightPBR;

	float alpha = _Alpha;
	#if _DRAW_OVERLAY_ON
		{
			float3 headForward = normalize(_HeadForward);
			alpha = lerp(1, alpha, saturate(dot(headForward, viewDirection)));
		}
	#endif


	float4 color = float4(finalNPR + finalPBR * _FinalWeightPBR + envResult, alpha);
	clip(color.a - _AlphaClip);
	color.rgb = MixFog(color.rgb, input.fogFactor);
	
	return color;
	// return float4(i.vertexColor,1);
	// return i.vertexColor.r;
	// return 0;
	// return float4(pointLightColor,1);
    // return litOrShadowArea;
}


