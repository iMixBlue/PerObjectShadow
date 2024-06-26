Shader "HighQualityHeroShadows/shadow receive plane"
{
	Properties
	{
		_Color("Color, Alpha for Shadow Strength", Color) = (0.5, 0.5, 0.5, 0.5)
	}
	SubShader
	{
		Tags { "Queue"="Transparent" }
		LOD 0

		Pass
		{
			Name "FORWARD"
			Tags{ "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" }
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

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
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 posWS :TEXCOORD0;
			};

			uniform half4 _Color;
#ifdef _HIGH_QUALITY_SHADOW_REVEIVE			
			matrix _LightVP;
			sampler2D _ShadowDepthTex;
			float4 _ShadowDepthTex_TexelSize;
#endif
			v2f vert (appdata v)
			{
				v2f o;
				// UNITY_INITIALIZE_OUTPUT(v2f, o);
				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
				o.pos =  vertexInput.positionCS;
				o.posWS = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 col = _Color;

#ifdef _HIGH_QUALITY_SHADOW_REVEIVE	
				float4 posLCS = mul(_LightVP, i.posWS);
				float4 posNDC = posLCS/posLCS.w;
				float2 uv0 = posNDC.xy * 0.5 + 0.5;

				float shadow = 0.0;
				float bias = 0.05;
				
	#ifdef UNITY_REVERSED_Z
				shadow += step(bias, tex2D(_ShadowDepthTex, uv0 + float2(0, 1) * _ShadowDepthTex_TexelSize.xy).r );
				shadow += step(bias, tex2D(_ShadowDepthTex, uv0 + float2(0, -1)* _ShadowDepthTex_TexelSize.xy).r );
				shadow += step(bias, tex2D(_ShadowDepthTex, uv0 + float2(1, 0) * _ShadowDepthTex_TexelSize.xy).r );
				shadow += step(bias, tex2D(_ShadowDepthTex, uv0 + float2(-1, 0)* _ShadowDepthTex_TexelSize.xy).r );
				shadow /= 4.0;	
				col.a = shadow;
	#else
				shadow += step(bias, 1-tex2D(_ShadowDepthTex, uv0 + float2(0, 1) * _ShadowDepthTex_TexelSize.xy).r );
				shadow += step(bias, 1-tex2D(_ShadowDepthTex, uv0 + float2(0, -1)* _ShadowDepthTex_TexelSize.xy).r );
				shadow += step(bias, 1-tex2D(_ShadowDepthTex, uv0 + float2(1, 0) * _ShadowDepthTex_TexelSize.xy).r );
				shadow += step(bias, 1-tex2D(_ShadowDepthTex, uv0 + float2(-1, 0)* _ShadowDepthTex_TexelSize.xy).r );
				shadow /= 4.0;
				col.a = shadow;
	#endif

#else
				col.a = 0.0;
#endif
				return col;
			}
			ENDHLSL
		}
	}
}


