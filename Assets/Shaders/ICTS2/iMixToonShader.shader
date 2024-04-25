//iMix/Toon   mix from : UTS3/NiloToon/Genshin/StartRail/ZoneZero/BRDF
//imixgold@gmail.com

//Known Issues : Disabled "Depth Priming Mode" to support outline

Shader "iMix/ToonShader" // ver 0.1

{
	Properties
	{
		[KeywordEnum(None, Body, Hair, Face, Eyes, Others)] _Area ("Material area", float) = 0
		[HideInInspector] _HeadForward ("", Vector) = (0, 0, 1)
		[HideInInspector] _HeadRight ("", Vector) = (1, 0, 0)
		[Foldout(1, 1, 0, 0)]_LightingFoldout ("Lighting_Foldout", float) = 1
		
		[Header(albedo)]
		[Space(10)]
		[Tex(_BaseColor)]_MainTex ("BaseMap", 2D) = "white" { }
		[HideInInspector]_BaseMap ("FakeBaseMap", 2D) = "white" { }
		[HideInInspector]_BaseColor ("BaseColor", Color) = (1, 1, 1, 1)
		_Alpha ("Alpha (Default 1)", Range(0, 1)) = 1
		_AlphaClip ("Alpha clip (Default 0.333)", Range(0, 1)) = 0.333

		_Set_SystemShadowsToBase ("Receive Self Shadows", Range(0, 1)) = 0.65
		_Set_AL_SystemShadowsToBase ("Receive Additional Light Self Shadows", Range(0, 1)) = 1
		[Toggle]_LightingDirectionFix ("Lighting Direction Fix", Float) = 1
		_CelShadowBias ("Cel Shadow Bias", Range(-1, 1)) = 0
		_CelShadeMidPoint ("_CelShadeMidPoint", Range(-1, 1)) = -0.5
		_CelShadeSoftness ("_CelShadeSoftness", Range(0, 1)) = 0.05
		[Toggle(_)] _Is_Filter_HiCutPointLightColor ("PointLights HiCut_Filter (ForwardAdd Only)", Float) = 1

		[Header(Light Map)]
		[Space(10)]
		[Toggle]_UselightmapAO ("on/off lightmap AO completely)", Float) = 0
		_LightMapStrength ("_LightMapStrength", Range(0.0, 1.0)) = 1.0
		_LightMapChannelMask_AO ("LightMap AO ChannelMask", Vector) = (1, 0, 0, 0)
		_LightMapRemapStart ("_LightMapRemapStart", Range(0, 1)) = 0
		_LightMapRemapEnd ("_LightMapRemapEnd", Range(0, 1)) = 1
		[Tex][NoScaleOffset] _BodyLightMap ("Body light map (Default black)", 2D) = "black" { }
		[Tex][NoScaleOffset] _HairLightMap ("Hair light map (Default black)", 2D) = "black" { }

		[Header(Ramp Map)]
		[Space(10)]
		[Tex][NoScaleOffset] _CoolRamp ("Body cool ramp {Default white}", 2D) = "white" { }
		[Tex][NoScaleOffset] _WarmRamp ("Body warm ramp (Default white)", 2D) = "white" { }
		[Tex][NoScaleOffset] _PBRMask ("PBR Mask (Default white)", 2D) = "white" { }

		_MainLightColorUsage ("Main light color usage (Default 1)", Range(0, 1)) = 1
		_ShadowRampOffset ("Shadow ramp offset (Default 0.75)", Range(0, 1)) = 0.75
		[Toggle(_)] _UseRampShadow ("On/Off Ramp Shadow Completely", Float) = 1
		_ShadowMapColor ("_ShadowMapColor", Color) = (1, 0.825, 0.78)
		
		[Header(NormalMap)]
		[Space(10)]
		_NormalMap ("NormalMap", 2D) = "bump" { }
		_BumpScale ("Normal Scale", Range(0, 1)) = 1
		[Toggle(_)] _Is_NormalMapToBase ("Is_NormalMapToBase", Float) = 0
		
		
		[Foldout(2, 2, 0, 0)]_ITSFaceFoldout ("FaceSDF_Foldout", float) = 1
		[Header(Face)]
		[Space(10)]
		[NoScaleOffset] _FaceMap ("Face SDF map (Default black)", 2D) = "black" { }
		[Toggle]_EnableFaceSDF ("on/off Face SDF completely", Float) = 0
		_LightMapChannelMask_Face ("FaceMap SDF ChannelMask", Vector) = (1, 0, 0, 0)
		_FaceShadowOffset ("Face shadow offset (Default -0.01)", Range(-1, 1)) = -0.01
		_FaceShadowTransitionSoftness ("Face shadow transition softness (Default 0.05)", Range(0, 1)) = 0.05

		[Foldout(2, 2, 0, 0)]_ITSEyesFoldout ("Eyes_Foldout", float) = 1
		[Header(Eyes)]
		[Space(10)]
		_ParallaxScale ("Eye UV Scale (Default 0.2)", Range(-1, 10)) = 0.2
		_ParallaxMaskEdge ("Eye UV Mask Edge(Default 0)", Range(-1, 1)) = 0
		_ParallaxMaskEdgeOffset ("Eye UV Mask Edge Offset (Default 1)", Range(-1, 1)) = 1
		
		//Specular
		[Foldout(1, 1, 0, 0)]_SperularFoldout ("Specular_Foldout", float) = 1
		//UTSSpecular
		[Foldout(2, 2, 0, 0)]_UTSSperularFoldout ("UTSSpecular_Foldout", float) = 1
		_HighColor ("HighColor", Color) = (0, 0, 0, 1)
		[Tex][NoScaleOffset]_HighColor_Tex ("HighColor_Tex", 2D) = "white" { }
		[Toggle(_)] _Is_LightColor_HighColor ("Is_LightColor_HighColor", Float) = 1
		[Toggle(_)] _Is_NormalMapToHighColor ("Is_NormalMapToHighColor", Float) = 0
		_HighColor_Power ("HighColor_Power", Range(0, 1)) = 0
		[Toggle(_)] _Is_SpecularToHighColor ("Is_SpecularToHighColor", Float) = 0
		[Toggle(_)] _Is_BlendAddToHiColor ("Is_BlendAddToHiColor", Float) = 0
		[Toggle(_)] _Is_UseTweakHighColorOnShadow ("Is_UseTweakHighColorOnShadow", Float) = 0
		_TweakHighColorOnShadow ("TweakHighColorOnShadow", Range(0, 1)) = 0

		[Foldout(2, 2, 0, 0)]_StartrailSperularFoldout ("StartRailSpecular_Foldout", float) = 1
		//StartRailSpecular
		_SpecularExpon ("Specular exponent (Default 50)", Range(1, 128)) = 50
		_SpecularKsNonMetal ("Specular Ks non-metal (Default 0.04)", Range(0, 1)) = 0.04
		_SpecularKsMetal ("Specular Ks metal (Default 1)", Range(0, 1)) = 1
		_SpecularBrightness ("Specular brightness (Default 1)", Range(0, 10)) = 1
		
		
		[Foldout(1, 1, 0, 0)]_RimlightFoldout ("RimLight_Foldout", float) = 1
		[Toggle(_)] _RimLight ("Use RimLight", Float) = 0
		[Foldout(2, 2, 0, 0)]_UTS3RimlightFoldout ("UTS3 RimLight_Foldout", float) = 1
		//UTS3 RimLight
		[Tex][NoScaleOffset]_Set_HighColorMask ("Set_HighColorMask", 2D) = "white" { }
		_Tweak_HighColorMaskLevel ("Tweak_HighColorMaskLevel", Range(-1, 1)) = 0
		_RimLightColor ("RimLightColor", Color) = (1, 1, 1, 1)
		[Toggle(_)] _Is_LightColor_RimLight ("Is_LightColor_RimLight", Float) = 1
		[Toggle(_)] _Is_NormalMapToRimLight ("Is_NormalMapToRimLight", Float) = 0
		_RimLight_Power ("RimLight_Power", Range(0, 1)) = 0.1
		_RimLight_InsideMask ("RimLight_InsideMask", Range(0.0001, 1)) = 0.0001
		[Toggle(_)] _RimLight_FeatherOff ("RimLight_FeatherOff", Float) = 0
		[Toggle(_)] _LightDirection_MaskOn ("LightDirection_MaskOn", Float) = 0
		_Tweak_LightDirection_MaskLevel ("Tweak_LightDirection_MaskLevel", Range(0, 0.5)) = 0
		[Toggle(_)] _Add_Antipodean_RimLight ("Add_Antipodean_RimLight", Float) = 0
		_Ap_RimLightColor ("Ap_RimLightColor", Color) = (1, 1, 1, 1)
		[Toggle(_)] _Is_LightColor_Ap_RimLight ("Is_LightColor_Ap_RimLight", Float) = 1
		_Ap_RimLight_Power ("Ap_RimLight_Power", Range(0, 1)) = 0.1
		[Toggle(_)] _Ap_RimLight_FeatherOff ("Ap_RimLight_FeatherOff", Float) = 0
		//RimLightMask
		[Tex][NoScaleOffset]_Set_RimLightMask ("Set_RimLightMask", 2D) = "white" { }
		_Tweak_RimLightMaskLevel ("Tweak_RimLightMaskLevel", Range(-1, 1)) = 0
		
		[Foldout(2, 2, 0, 0)]_StartRailRimlightFoldout ("StartRail RimLight_Foldout", float) = 1
		//StartRail RimLight
		[Toggle(_StartRailRimlight_ON)] _UseStartRailRimlight ("Use Start Rail Rimlight (Default NO)", float) = 0
		_RimLightWidth ("Rim light width (Default 1)", Range(0, 10)) = 1
		_RimLightThreshold ("Rim light threshold (Default 0.05)", Range(-1, 1)) = 0.05
		_RimLightFadeout ("Rim light fadeout (Default 1)", Range(0.01, 1)) = 1
		[HDR] _RimLightFrontColor ("Rim light Front color (Default white)", Color) = (1, 1, 1)
		[HDR] _RimLightBackColor ("Rim light Back color (Default white)", Color) = (1, 1, 1)
		_RimLightBrightness ("Rim light brightness (Default 1)", Range(0, 10)) = 1
		_RimLightMixAlbedo ("Rim light mix albedo (Default 0.9)", Range(0, 1)) = 0.9
		
		
		[Foldout(1, 1, 0, 0)]_MatCapFoldout ("MatCap_Foldout", float) = 1
		//MatCap
		[Toggle(_)] _MatCap ("Use MatCap", Float) = 0
		_MatCap_Sampler ("MatCap_Sampler", 2D) = "black" { }
		
		_BlurLevelMatcap ("Blur Level of MatCap_Sampler", Range(0, 10)) = 0
		_MatCapColor ("MatCapColor", Color) = (1, 1, 1, 1)
		[Toggle(_)] _Is_LightColor_MatCap ("Is_LightColor_MatCap", Float) = 1
		[Toggle(_)] _Is_BlendAddToMatCap ("Is_BlendAddToMatCap", Float) = 1
		_Tweak_MatCapUV ("Tweak_MatCapUV", Range(-0.5, 0.5)) = 0
		_Rotate_MatCapUV ("Rotate_MatCapUV", Range(-1, 1)) = 0
		
		[Toggle(_)] _CameraRolling_Stabilizer ("Activate CameraRolling_Stabilizer", Float) = 0
		[Toggle(_)] _Is_NormalMapForMatCap ("Is_NormalMapForMatCap", Float) = 0
		_NormalMapForMatCap ("NormalMapForMatCap", 2D) = "bump" { }
		_BumpScaleMatcap ("Scale for NormalMapforMatCap", Range(0, 1)) = 1
		_Rotate_NormalMapForMatCapUV ("Rotate_NormalMapForMatCapUV", Range(-1, 1)) = 0
		[Toggle(_)] _Is_UseTweakMatCapOnShadow ("Is_UseTweakMatCapOnShadow", Float) = 0
		_TweakMatCapOnShadow ("TweakMatCapOnShadow", Range(0, 1)) = 0
		//MatcapMask
		[Tex][NoScaleOffset]_Set_MatcapMask ("Set_MatcapMask", 2D) = "white" { }
		_Tweak_MatcapMaskLevel ("Tweak_MatcapMaskLevel", Range(-1, 1)) = 0
		[Toggle(_)] _Inverse_MatcapMask ("Inverse_MatcapMask", Float) = 0
		
		[Toggle(_)] _Is_Ortho ("Orthographic Projection for MatCap", Float) = 0
		
		[Foldout(1, 1, 0, 0)]_StockingFoldout ("Stocking_Foldout", float) = 1
		[Foldout(1, 1, 0, 0)]_AngelRingFoldout ("Angel Ring_Foldout", float) = 1
		// Angel Ring start rail
		[Toggle(_)] _AngelRing ("Enbele/Disable AngelRing", Float) = 0
		_HairSpecularRange ("_HairSpecularRange", Range(0, 1)) = 0
		_HairSpecularViewRange ("_HairSpecularViewRange", Range(0, 1)) = 0
		_HairSpecularIntensity ("_HairSpecularIntensity / in gf2 is min Intensity", Range(0, 50)) = 0
		_AngelRing_Color ("AngelRing_Color", Color) = (1, 1, 1, 1)
		[Toggle(_)] _Is_LightColor_AR ("Is_LightColor_AR", Float) = 1
		// Angel Ring gril frontline 2
		_AnisotropicSlide ("_gf2HairARSlide", Range(0, 5)) = 1
		_AnisotropicOffset ("_gf2HairAROffset", Range(-1, 1)) = 0
		

		[Foldout(1, 1, 0, 0)]_EmissiveFoldout ("Emissive_Foldout", float) = 1
		//Emissive
		[KeywordEnum(SIMPLE, ANIMATION)] _EMISSIVE ("EMISSIVE MODE", Float) = 0
		[Tex][NoScaleOffset]_Emissive_Tex ("Emissive_Tex", 2D) = "white" { }
		[HDR]_Emissive_Color ("Emissive_Color", Color) = (0, 0, 0, 1)
		_Base_Speed ("Base_Speed", Float) = 0
		_Scroll_EmissiveU ("Scroll_EmissiveU", Range(-1, 1)) = 0
		_Scroll_EmissiveV ("Scroll_EmissiveV", Range(-1, 1)) = 0
		_Rotate_EmissiveUV ("Rotate_EmissiveUV", Float) = 0
		[Toggle(_)] _Is_PingPong_Base ("Is_PingPong_Base", Float) = 0
		[Toggle(_)] _Is_ColorShift ("Activate ColorShift", Float) = 0
		[HDR]_ColorShift ("ColorSift", Color) = (0, 0, 0, 1)
		_ColorShift_Speed ("ColorShift_Speed", Float) = 0
		[Toggle(_)] _Is_ViewShift ("Activate ViewShift", Float) = 0
		[HDR]_ViewShift ("ViewSift", Color) = (0, 0, 0, 1)
		[Toggle(_)] _Is_ViewCoord_Scroll ("Is_ViewCoord_Scroll", Float) = 0


		[Foldout(1, 1, 0, 0)]_OutlineFoldout ("Outline_Foldout", float) = 1
		//Outline
		[Toggle(_OUTLINE_ON)] _UseOutline ("Use outline (Default YES)", float) = 1
		[Toggle(_OUTLINE_UV7_SMOOTH_NORMAL)] _OutlineUseUV7SmoothNormal ("Use UV7 smooth normal (Default NO)", Float) = 0
		_OutlineWidth ("Outline width (Default 1)", Range(0, 10)) = 1
		_OutlineGamma ("Outline gamma (Default 16)", Range(1, 255)) = 16
		_OutlineColor ("_OutlineColor", Color) = (0.5, 0.5, 0.5, 1)
		_OutlineZOffset ("_OutlineZOffset (View Space)", Range(0, 1)) = 0.0001
		_OutlineColorBlend ("_ColorBlend", Range(0, 1)) = 0.2
		[NoScaleOffset]_OutlineZOffsetMaskTex ("_OutlineZOffsetMask (black is apply ZOffset)", 2D) = "black" { }
		_OutlineZOffsetMaskRemapStart ("_OutlineZOffsetMaskRemapStart", Range(0, 1)) = 0
		_OutlineZOffsetMaskRemapEnd ("_OutlineZOffsetMaskRemapEnd", Range(0, 1)) = 1
		_test1 ("test1", Range(0, 1)) = 0
		_test2 ("test2", Range(0, 1)) = 0
		_test3 ("test3", Range(0, 1)) = 0


		[Foldout(1, 1, 0, 0)]_PBRFoldout ("PBR_Foldout", float) = 1
		//PBR
		_SSSWeightPBR ("PBR SSS Weight", Range(0, 1)) = 0
		_WeightBRDF ("BRDF Weight", Range(0, 1)) = 0
		// _WeightEnvLight ("PBR Env light Weight", Range(0, 1)) = 0 //env没啥效果，用UTS3的env了
		_DiffuseWeightPBR ("PBR Diffuse Weight", Range(0, 1)) = 0
		_SpecularWeightPBR ("PBR Specular Weight", Range(0, 1)) = 0
		_sssColor ("SSS Color", color) = (1, 1, 1, 1)
		_roughness ("Roughness", Range(0, 1)) = 0.555
		_metallic ("Metallic", Range(0, 1)) = 0.495
		_subsurface ("Subsurface", Range(0, 1)) = 0.467
		_anisotropic ("Anisotropic", Range(0, 1)) = 0
		_ior ("index of refraction", Range(0, 10)) = 1
		// _specular ("Specular", Range(0, 1)) = 1   //BRDF_Disney
		// _specularTint ("Specular Tint", Range(0, 1)) = 0.489
		// _sheenTint ("Sheen Tint", Range(0, 1)) = 0.5
		// _sheen ("Sheen", Range(0, 1)) = 0.5
		// _clearcoat ("Clearcoar", Range(0, 1)) = 0.5
		// _clearcoatGloss ("Clearcoat Gloss", Range(0, 1)) = 1
		_DirectOcclusion_PBR ("Direct Occlusion in PBR", Range(0, 1)) = 0

		

		[Foldout(2, 2, 0, 0)]_PBREnvLightFoldout ("Disney PBR_Env_Light_Foldout(useless now/v0.1)", float) = 1
		//PBR Env Light
		[NoScaleOffset] _Cubemap ("Envmap", cube) = "_Skybox" { }
		_CubemapMip ("Envmap Mip", Range(0, 7)) = 0
		[Tex]_IBL_LUT ("Precomputed integral LUT", 2D) = "white" { }
		_FresnelPow ("FresnelPow", Range(0, 5)) = 1
		_FresnelColor ("FresnelColor", Color) = (1, 1, 1, 1)
		// _EdgeColor ("Edge Color", Color) = (1, 1, 1, 1) //用于遮挡shader
		
		
		[Foldout(1, 1, 0, 0)]_GlobalIntensityFoldout ("GI Intensity_Foldout", float) = 1
		//GI Intensity
		_GI_Intensity ("GI_Intensity(Actually is the env light Intensity)", Range(0, 2)) = 1
		_AdditionalLightWeight ("Additional Light Influence", Range(0, 2)) = 0.25
		_EnvLerp ("Lerp from UTS PBR Env light to NPR Env light", Range(0, 1)) = 0
		_IndirectLightUsage ("NPR Env light Usage", Range(0, 1)) = 1 //that is because npr env light need more control , pbr light are real-time and realistic
		_IndirectLightMixBaseColor ("NPR Env light Mix Basecolor", Range(0, 1)) = 0
		_IndirectLightFlattenNormal ("NPR Env light Flat Normal", Range(0, 1)) = 1
		_FinalWeightPBR ("PBR final Weight", Range(0, 1)) = 0
		_FinalWeightNPR ("NPR final Weight", Range(0, 1)) = 1
		//For VR Chat under No effective light objects
		_Unlit_Intensity ("Unlit_Intensity", Range(0, 4)) = 0
		//
		[Toggle(_)] _Is_Filter_LightColor ("VRChat : SceneLights HiCut_Filter", Float) = 1
		//Built-in Light Direction
		[Toggle(_)] _Is_BLD ("Advanced : Activate Built-in Light Direction", Float) = 0
		_Offset_X_Axis_BLD (" Offset X-Axis (Built-in Light Direction)", Range(-1, 1)) = -0.05
		_Offset_Y_Axis_BLD (" Offset Y-Axis (Built-in Light Direction)", Range(-1, 1)) = 0.09
		[Toggle(_)] _Inverse_Z_Axis_BLD (" Inverse Z-Axis (Built-in Light Direction)", Float) = 1

		
		////////////////// Avoid URP srp batcher error ///////////////////////////////
		[HideInInspector]_Metallic ("_Metallic", Range(0.0, 1.0)) = 0
		[HideInInspector]_Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.5
		[HideInInspector][NoScaleOffset]_MaskMap ("MaskMap", 2D) = "white" { }
		////////////////// Avoid URP srp batcher error ///////////////////////////////


		[Foldout(1, 1, 0, 0)]_SurfaceOptionsFoldout ("Surface Options_Foldout", float) = 1
		[Header(Surface Options)]
		[Space(10)]
		[Enum(UnityEngine.Rendering.CullMode)] _Cull ("Cull (Default back)", Float) = 2
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendMode ("Src blend mode (Default One)", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlendMode ("Dst blend mode (Default Zero)", Float) = 0
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend operation (Default Add)", Float) = 0
		[Enum(Off, 0, On, 1)] _ZWrite ("Zwrite (Default On)", Float) = 1
		_StencilRef ("Stencil reference (Default 0)", Range(0, 255)) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil comparison (Default disabled)", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOp ("Stencil pass operation (Default keep)", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOp ("Stencil fail operation (Default keep)", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFailOp ("Stencil Z fail operation (Default keep)", Int) = 0

		// [Foldout(2, 2, 0, 0)]_DrawOverlayFoldout ("Draw Overlay_Foldout", float) = 1
		//Draw Overlay

		[Header(Draw Overlay)]
		[Space(10)]
		[Toggle(_DRAW_OVERLAY_ON)] _UseDrawOverlay ("Use draw overlay (Default NO)", float) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendModeOverlay ("Overlay pass src blend mode (Default One)", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlendModeOverlay ("Overlay pass dst blend mode (Default Zero)", Float) = 0
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOpOverlay ("Overlay pass blend operation (Default Add)", Float) = 0
		_StencilRefOverlay ("Overlay pass stencil reference (Default 0) ", Range(0, 255)) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilCompOverlay ("Overlay pass stencil comparison (Default disabled)", Int) = 0
	}

	SubShader
	{
		LOD 100

		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
		HLSLINCLUDE
		#pragma shader_feature_local _AREA_FACE
		#pragma shader_feature_local _AREA_HAIR
		#pragma shader_feature_local _AREA_BODY
		#pragma shader_feature_local _AREA_EYES
		#pragma shader_feature_local _AREA_OTHERS
		#pragma shader_feature_local _OUTLINE_ON
		#pragma shader_feature_local _OUTLINE_UV7_SMOOTH_NORMAL
		#pragma shader_feature_local _DRAW_OVERLAY_ON
		#pragma shader_feature_local _EMISSION_ON
		#pragma shader_feature_local _StartRailRimlight_ON
		ENDHLSL

		// Pass
		// {
		// 	Name "ShadowCaster"
		// 	Tags { "LightMode" = "ShadowCaster" }

		// 	ZWrite [_ZWrite]
		// 	ZTest LEqual
		// 	ColorMask 0
		// 	Cull[_Cull]

		// 	HLSLPROGRAM
		// 	#pragma target 2.0
		
		// 	// Required to compile gles 2.0 with standard srp library
		// 	#pragma prefer_hlslcc gles
		// 	#pragma exclude_renderers d3d11_9x


		// 	#pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

		// 	#pragma vertex ShadowPassVertex
		// 	#pragma fragment ShadowPassFragment

		// 	#include "iMixToonInput.hlsl"
		// 	#include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
		// 	ENDHLSL
		// }
		// Pass //built-in 偷过来的假阴影，因此TODO： 人物单独高精度投影
        // {
        //     Name "PlanarShadow"

        //     //用使用模板测试以保证alpha显示正确
        //     Stencil
        //     {
        //         Ref 0
        //         Comp equal
        //         Pass incrWrap
        //         Fail keep
        //         ZFail keep
        //     }

        //     Cull Off

        //     //透明混合模式
        //     Blend SrcAlpha OneMinusSrcAlpha

        //     //关闭深度写入
        //     ZWrite off

        //     //深度稍微偏移防止阴影与地面穿插
        //     Offset -1 , 0

        //     CGPROGRAM
        //     #pragma shader_feature _CLIPPING
        //     #pragma shader_feature _ALPHATEST_ON
        //     #pragma shader_feature _ALPHAPREMULTIPLY_ON

        //     #include "UnityCG.cginc"

        //     #pragma vertex vert
        //     #pragma fragment frag
            
        //     float _GroundHeight;
        //     float4 _ShadowColor;
        //     float _ShadowFalloff;
           
	
        //     float _Clipping;
        //     half _Cutoff;

        //     struct appdata
        //     {
        //         float4 vertex : POSITION;
        //         float2 uv : TEXCOORD0;
        //     };

        //     struct v2f
        //     {
        //         float4 vertex : SV_POSITION;
        //         float4 color : COLOR;
        //         float2 uv : TEXCOORD0;
        //     };

        //     float3 ShadowProjectPos(float4 vertPos)
        //     {
        //         float3 shadowPos;

        //         //得到顶点的世界空间坐标
        //         float3 worldPos = mul(unity_ObjectToWorld , vertPos).xyz;

        //         //灯光方向
        //         // float3 lightDir = normalize(_LightDir.xyz);
        //         float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);

        //         //阴影的世界空间坐标（低于地面的部分不做改变）
        //         shadowPos.y = min(worldPos .y , _GroundHeight);
        //         shadowPos.xz = worldPos .xz - lightDir.xz * max(0 , worldPos .y - _GroundHeight) / lightDir.y; 

        //         return shadowPos;
        //     }

        //     float GetAlpha (v2f i) {
        //         float alpha =  tex2D(_MainTex, i.uv.xy).a;
        //         return alpha;
        //     }

        //     v2f vert (appdata v)
        //     {
        //         v2f o;

        //         //得到阴影的世界空间坐标
        //         float3 shadowPos = ShadowProjectPos(v.vertex);

        //         //转换到裁切空间
        //         o.vertex = UnityWorldToClipPos(shadowPos);

        //         //得到中心点世界坐标
        //         float3 center = float3(unity_ObjectToWorld[0].w , _GroundHeight , unity_ObjectToWorld[2].w);
        //         //计算阴影衰减
        //         float falloff = 1-saturate(distance(shadowPos , center) * _ShadowFalloff);

        //         //阴影颜色
        //         o.color = _ShadowColor;
        //         o.color.a *= falloff;
                
        //         o.uv = TRANSFORM_TEX(v.uv, _MainTex);

        //         return o;
        //     }

        //     fixed4 frag (v2f i) : SV_Target
        //     {
        //         if (_Clipping)
        //         {
        //             float alpha = GetAlpha(i);
        //             i.color.a *= step(_Cutoff, alpha);
        //         }
        //         return i.color;
        //     }
        //     ENDCG
        // }
	
		Pass  // maybe solve the artifacts (by colin) but not srp batcher friendly

		{
			Name "ShadowCaster"

			Cull [_CullMode]

			Tags { "LightMode" = "ShadowCaster" }

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			// CBUFFER_START(UnityPerMaterial)
			float _Cutoff;
			// CBUFFER_END

			TEXTURE2D(_BaseMap);
			float4 _BaseMap_ST;

			#define textureSampler1 SamplerState_Point_Repeat
			SAMPLER(textureSampler1);

			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float2 uv : TEXCOORD0;
			};
			
			struct Varyings
			{
				float4 positionCS : SV_POSITION;
				float2 uv : TEXCOORD0;
			};
			float3 _LightDirection;
			float4 _ShadowBias; //
			half4 _MainLightShadowParams;

			float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
			{
				float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
				float scale = invNdotL * _ShadowBias.y;
				positionWS = lightDirection * _ShadowBias.xxx + positionWS;
				positionWS = normalWS * scale.xxx + positionWS;
				return positionWS;
			}

			Varyings vert(Attributes v)
			{
				Varyings o = (Varyings)0;
				float3 positionWS = TransformObjectToWorld(v.positionOS.xyz);
				half3 normalWS = TransformObjectToWorldNormal(v.normalOS);
				positionWS = ApplyShadowBias(positionWS, normalWS, _LightDirection);
				o.positionCS = TransformWorldToHClip(positionWS);
				#if UNITY_REVERSED_Z  // 好像就没有这个宏
					o.positionCS.z = min(o.positionCS.z, o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
				#else
					o.positionCS.z = max(o.positionCS.z, o.positionCS.w * UNITY_NEAR_CLIP_VALUE);
				#endif
				o.uv = v.uv;
				return o;
			}

			half4 frag(Varyings i) : SV_TARGET
			{
				float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, textureSampler1, i.uv);
				clip(baseMap.a - _Cutoff);
				return float4(0, 0, 0, 1);
			}

			ENDHLSL
		}
		
		Pass
		{
			Name "DepthOnly"
			Tags { "LightMode" = "DepthOnly" }

			ZWrite [_ZWrite]
			ColorMask 0
			Cull[_Cull]

			HLSLPROGRAM
			#pragma target 2.0
			
			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex DepthOnlyVertex
			#pragma fragment DepthOnlyFragment

			// -------------------------------------
			// Material Keywords
			#pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

			#include "iMixToonInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
			ENDHLSL
		}
		// This pass is used when drawing to a _CameraNormalsTexture texture
		Pass
		{
			Name "DepthNormals"
			Tags { "LightMode" = "DepthNormals" }

			ZWrite[_ZWrite]
			Cull[_Cull]

			HLSLPROGRAM
			#pragma target 2.0
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Version.hlsl"


			// Required to compile gles 2.0 with standard srp library
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex DepthNormalsVertex
			#pragma fragment DepthNormalsFragment

			// -------------------------------------
			// Material Keywords
			#pragma shader_feature_local _PARALLAXMAP
			#pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A



			#include "iMixToonInput.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/DepthNormalsPass.hlsl"

			ENDHLSL
		}

		//ToonCoreStart
		Pass
		{
			Name "DrawCore"
			Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
			Cull[_Cull]
			Stencil
			{
				Ref [_StencilRef]
				Comp [_StencilComp]
				Pass [_StencilPassOp]
				Fail [_StencilFailOp]
				ZFail [_StencilZFailOp]
			}
			Blend [_SrcBlendMode] [_DstBlendMode]
			BlendOp [_BlendOp]
			ZWrite [_ZWrite]

			HLSLPROGRAM
			#pragma target 2.0
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag
			// #ifndef DISABLE_RP_SHADERS
			// -------------------------------------
			// urp Material Keywords
			// -------------------------------------
			#pragma shader_feature_local _ALPHAPREMULTIPLY_ON
			#pragma shader_feature_local _EMISSION
			#pragma shader_feature_local _METALLICSPECGLOSSMAP
			#pragma shader_feature_local _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
			//            #pragma shader_feature _OCCLUSIONMAP

			#pragma shader_feature_local _SPECULARHIGHLIGHTS_OFF
			#pragma shader_feature_local _ENVIRONMENTREFLECTIONS_OFF
			#pragma shader_feature_local _SPECULAR_SETUP
			#pragma shader_feature_local _RECEIVE_SHADOWS_OFF
			// #endif

			// -------------------------------------
			// Lightweight Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT

			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fog

			#pragma shader_feature_local _ _SHADINGGRADEMAP


			// used in Shadow calculation
			#pragma shader_feature_local _ UTS_USE_RAYTRACING_SHADOW

			#pragma shader_feature _EMISSIVE_SIMPLE _EMISSIVE_ANIMATION
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			
			#include "iMixToonInput.hlsl"
			#include "iMixToonDrawCore.hlsl"
			ENDHLSL
		}
		//ToonCoreEnd

		

		Pass
		{
			Name "DrawOverlay"
			Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "LightMode" = "UniversalForward" }
			cull [_Cull]
			Stencil
			{
				Ref [_StencilRefOverlay]
				Comp [_StencilCompOverlay]
			}
			Blend [_SrcBlendModeOverlay] [_DstBlendModeOverlay]
			BlendOp [_BlendOpOverlay]
			ZWrite [_ZWrite]

			HLSLPROGRAM
			#pragma multi_compile _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _SHADOWS_SOFT

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fog

			#if _DRAW_OVERLAY_ON
				#include "iMixToonInput.hlsl"
				#include "iMixToonDrawCore.hlsl"
				// #include "StartRailCharacterInput.hlsl"
				// #include "StartRailCharacterDrawCorePass.hlsl"
			#else
				struct Attributes { };
				struct Varyings
				{
					float4 positionCS : SV_POSITION;
				};
				Varyings vert(Attributes input)
				{
					return (Varyings)0;
				}
				float4 frag(Varyings input) : SV_TARGET
				{
					return 0;
				}
			#endif
			ENDHLSL
		}

		Pass
		{
			Name "DrawOutline"
			Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "LightMode" = "UniversalForwardOnly" }
			cull front
			ZWrite [_ZWrite]

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fog
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT

			#if _OUTLINE_ON
				#include "iMixToonInput.hlsl"
				#include "iMixToonDrawOutline.hlsl"
			#else
				struct Attributes { };
				struct Varyings
				{
					float4 positionCS : SV_POSITION;
				};
				Varyings vert(Attributes input)
				{
					return (Varyings)0;
				}
				float4 frag(Varyings input) : SV_TARGET
				{
					return 0;
				}
			#endif
			
			ENDHLSL
		}
	}
	CustomEditor "iMix.SimpleShaderGUI"
}
