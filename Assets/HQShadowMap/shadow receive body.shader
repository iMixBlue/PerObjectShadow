Shader "HighQualityHeroShadows/shadow receive body"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "red" {}
		_Color("_Color", Color) = (1, 0, 0, 1)
		_Bias("_Bias", Range(0, 0.5)) = 0.03
	}
	SubShader
	{


		Pass
		{
			Tags{ "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }

			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile _ _HIGH_QUALITY_SHADOW_REVEIVE

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 posWS :TEXCOORD1;
			};

			uniform half4 _Color;
#ifdef _HIGH_QUALITY_SHADOW_REVEIVE			
			matrix _LightVP;
			sampler2D _ShadowDepthTex;
			float4 _ShadowDepthTex_TexelSize;
			float _Bias;
#endif
			v2f vert (appdata v)
			{
				v2f o;
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
				o.pos =  vertexInput.positionCS;
				o.uv = v.uv;
				o.posWS = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 col = _Color;
				float shadow = 0.0;
#ifdef _HIGH_QUALITY_SHADOW_REVEIVE	
				float4 posLCS = mul(_LightVP, i.posWS);
				float4 posNDC = posLCS/posLCS.w;
				float2 uv0 = posNDC.xy * 0.5 + 0.5;

	#ifdef UNITY_REVERSED_Z
				shadow += posNDC.z + _Bias < tex2D(_ShadowDepthTex, uv0 + float2(0, 1) * _ShadowDepthTex_TexelSize.xy).r ? 1.0 : 0.0;
				shadow += posNDC.z + _Bias < tex2D(_ShadowDepthTex, uv0 + float2(0, -1)* _ShadowDepthTex_TexelSize.xy).r ? 1.0 : 0.0;
				shadow += posNDC.z + _Bias < tex2D(_ShadowDepthTex, uv0 + float2(1, 0) * _ShadowDepthTex_TexelSize.xy).r ? 1.0 : 0.0;
				shadow += posNDC.z + _Bias < tex2D(_ShadowDepthTex, uv0 + float2(-1, 0)* _ShadowDepthTex_TexelSize.xy).r ? 1.0 : 0.0;
				shadow /= 4.0;
	#else
				posNDC.z = posNDC.z * 0.5 + 0.5;
				shadow += posNDC.z > _Bias + tex2D(_ShadowDepthTex, uv0 + float2(0, 1) * _ShadowDepthTex_TexelSize.xy).r ? 1.0 : 0.0;
				shadow += posNDC.z > _Bias + tex2D(_ShadowDepthTex, uv0 + float2(0, -1)* _ShadowDepthTex_TexelSize.xy).r ? 1.0 : 0.0;
				shadow += posNDC.z > _Bias + tex2D(_ShadowDepthTex, uv0 + float2(1, 0) * _ShadowDepthTex_TexelSize.xy).r ? 1.0 : 0.0;
				shadow += posNDC.z > _Bias + tex2D(_ShadowDepthTex, uv0 + float2(-1, 0)* _ShadowDepthTex_TexelSize.xy).r ? 1.0 : 0.0;
				shadow /= 4.0;
	#endif
#endif
				return col * (1-shadow);
			}
			ENDHLSL
		}
	}
}


				
				
				