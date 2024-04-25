Shader "Custom/iMixHairFringe" //Fringe = hair shadow

{
	Properties
	{
		_Color ("Color", Color) = (1, 1, 1, 1)
		_OffsetX ("_ScreenOffsetScaleX", Range(-1, 1)) = 0.1
		_OffsetY ("_ScreenOffsetScaleY", Range(-10, 10)) = 0.1
		[Header(Stencil)]
		_StencilRef ("_StencilRef", Range(0, 255)) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("_StencilComp", float) = 0
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" }

		HLSLINCLUDE
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

		CBUFFER_START(UnityPerMaterial)
			float4 _Color;
			float _OffsetX;
			float _OffsetY;
			float4 _LightDirSS;
		CBUFFER_END
		ENDHLSL

		Pass
		{
			Name "HairShadow"
			Tags { "LightMode" = "UniversalForward" }

			Stencil
			{
				Ref [_StencilRef]
				Comp [_StencilComp]
				Pass Zero
			}

			ZTest LEqual
			ZWrite Off
			ColorMask 0

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

			struct a2v
			{
				float4 positionOS : POSITION;
				float4 color : COLOR;
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float4 color : COLOR;
			};

			v2f vert(a2v v)
			{
				//https://zhuanlan.zhihu.com/p/416577141
				//https://zhuanlan.zhihu.com/p/663968812  Danbaidong的刘海投影做的不好，没有考虑相机远近，只为了他的demo视角（因为相机不动）所以看不出来，而且
				//在裁剪空间下做本身就不存在俯视角还能看到刘海的问题
				v2f o;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
                o.positionCS = positionInputs.positionCS;

                float2 lightOffset = normalize(_LightDirSS.xy);
                //乘以_ProjectionParams.x是考虑裁剪空间y轴是否因为DX与OpenGL的差异而被翻转
                //参照https://docs.unity3d.com/Manual/SL-PlatformDifferences.html
                //"Similar to Texture coordinates, the clip space coordinates differ between Direct3D-like and OpenGL-like platforms"
                lightOffset.y = lightOffset.y * _ProjectionParams.x;

				o.positionCS.x += 0.004 * lightOffset.x * _OffsetX;
				o.positionCS.y += 0.007 * lightOffset.y * _OffsetY;

				o.color = v.color;
				return o;
			}

			half4 frag(v2f i) : SV_Target
			{
				return _Color;
			}
			ENDHLSL
		}
		Pass
		{
			Name "HairShadow_Face"
			Tags { "LightMode" = "UniversalForward" }

			Stencil
			{
				Ref 0
				Comp [_StencilComp]
				Pass keep
			}

			ZTest LEqual
			ZWrite Off

			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			struct a2v
			{
				float4 positionOS : POSITION;
				float4 color : COLOR;
				float2 uv : TEXCOORD;
			};

			struct v2f
			{
				float4 positionCS : SV_POSITION;
				float4 color : COLOR;
				float2 uv : TEXCOORD0;
			};


			v2f vert(a2v v)
			{
				v2f o;

				VertexPositionInputs positionInputs = GetVertexPositionInputs(v.positionOS.xyz);
				o.positionCS = positionInputs.positionCS;

				o.color = v.color;
				o.uv = v.uv;
				return o;
			}

			TEXTURE2D(_FaceTex);
			SAMPLER(sampler_FaceTex);

			half4 frag(v2f i) : SV_Target
			{
				return SAMPLE_TEXTURE2D(_FaceTex, sampler_FaceTex, i.uv) * _Color;
			}
			ENDHLSL
		}
	}
}