// Write by iMixBlue
// PBR and Utilities tools

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "iMixToonInput.hlsl"

// PBR
float3 mon2lin(float3 x)
{
	return float3(pow(x[0], 2.2), pow(x[1], 2.2), pow(x[2], 2.2));
}
float sqr(float x)
{
	return x * x;
}
///
/// PBR direct
///
float3 compute_F0(float eta)
{
	return pow((eta - 1) / (eta + 1), 2);
}
float3 F_fresnelSchlick(float VdotH, float3 F0)  // F

{
	return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
}
float3 F_SimpleSchlick(float HdotL, float3 F0)
{
	return lerp(exp2((-5.55473 * HdotL - 6.98316) * HdotL), 1, F0);
}
float SchlickFresnel(float u)
{
	float m = clamp(1 - u, 0, 1);
	float m2 = m * m;
	return m2 * m2 * m; // pow(m,5)

}
float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float roughness)
{
	return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}
float GTR1(float NdotH, float a)
{
	if (a >= 1) return 1 / PI;
	float a2 = a * a;
	float t = 1 + (a2 - 1) * NdotH * NdotH;
	return (a2 - 1) / (PI * log(a2) * t);
}
float D_GTR2(float NdotH, float a)    // D

{
	float a2 = a * a;
	float t = 1 + (a2 - 1) * NdotH * NdotH;
	return a2 / (PI * t * t);
}
// X: tangent
// Y: bitangent
// ax: roughness along x-axis
float GTR2_aniso(float NdotH, float HdotX, float HdotY, float ax, float ay)
{
	return 1 / (PI * ax * ay * sqr(sqr(HdotX / ax) + sqr(HdotY / ay) + NdotH * NdotH));
}
float smithG_GGX(float NdotV, float alphaG)
{
	float a = alphaG * alphaG;
	float b = NdotV * NdotV;
	return 1 / (NdotV + sqrt(a + b - a * b));
}
float GeometrySchlickGGX(float NdotV, float k)
{
	float nom = NdotV;
	float denom = NdotV * (1.0 - k) + k;
	
	return nom / denom;
}

float G_Smith(float3 N, float3 V, float3 L, float roughness)
{
	float k = pow(roughness + 1, 2) / 8;
	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float ggx1 = GeometrySchlickGGX(NdotV, k);
	float ggx2 = GeometrySchlickGGX(NdotL, k);
	
	return ggx1 * ggx2;
}
float smithG_GGX_aniso(float NdotV, float VdotX, float VdotY, float ax, float ay)
{
	return 1 / (NdotV + sqrt(sqr(VdotX * ax) + sqr(VdotY * ay) + sqr(NdotV)));
}
float3 Diffuse_Burley_Disney(float3 DiffuseColor, float Roughness, float NoV, float NoL, float VoH)
{
	float FD90 = 0.5 + 2 * VoH * VoH * Roughness;
	float FdV = 1 + (FD90 - 1) * pow(1 - NoV, 5);
	float FdL = 1 + (FD90 - 1) * pow(1 - NoL, 5);
	return DiffuseColor * ((1 / PI) * FdV * FdL);
}
float3 Diffuse_Simple(float3 DiffuseColor, float3 F, float NdotL, float metallic)
{
	float3 KD = (1 - F) * (1 - metallic);
	return KD * DiffuseColor * GetMainLight().color * NdotL;
}
float SSS(float3 L, float3 V, float3 N, float3 baseColor, float metallic, float roughness, float litOrShadowArea)
{
	// float NdotL = dot(N,L);
	float NdotL = litOrShadowArea;
	float NdotV = dot(N, V);
	if (NdotL < 0 || NdotV < 0)
	{
		//NdotL = 0.15f;

	}
	float3 H = normalize(L + V);
	float LdotH = dot(L, H);

	float3 Cdlin = mon2lin(baseColor);
	if (NdotL < 0 || NdotV < 0)
	{
		return (1 / PI) * Cdlin * (1 - metallic);
	}

	float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
	float Fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
	float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);
	
	float Fss90 = LdotH * LdotH * roughness;
	float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
	float ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - .5) + .5);

	
	return (1 / PI) * lerp(Fd, ss, _subsurface) * Cdlin * (1 - metallic);
}
float3 BRDF_Simple(float3 L, float3 V, float3 N, float3 X, float3 Y, float3 baseColor, float metallic, float roughness, float litOrShadowArea)
{
	// float NdotL = dot(N,L);
	float NdotL = litOrShadowArea;
	float NdotV = dot(N, V);
	
	float3 H = normalize(L + V);
	float NdotH = dot(N, H);
	float LdotH = dot(L, H);
	float VdotH = dot(V, H);
	float HdotL = dot(H, L);

	float D;

	if (_anisotropic < 0.1f)
	{
		D = D_GTR2(NdotH, roughness);
	}
	else
	{
		float aspect = sqrt(1 - _anisotropic * .9);
		float ax = max(.001, sqr(roughness) / aspect);
		float ay = max(.001, sqr(roughness) * aspect);
		D = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
	}
	
	//float F = F_fresnelSchlick(VdotH, compute_F0(_ior));
	float3 F = F_SimpleSchlick(HdotL, compute_F0(_ior));
	float G = G_Smith(N, V, L, roughness);

	float3 brdf = D * F * G / (4 * NdotL * NdotV);

	float3 brdf_diff = Diffuse_Simple(baseColor, F, NdotL, metallic);
	
	return saturate(brdf * GetMainLight().color * NdotL * PI * _SpecularWeightPBR + brdf_diff * _DiffuseWeightPBR); //这里没要diffuse，只要了speculat //+brdf_diff
	// return brdf;

}
// float3 BRDF_Disney(float3 L, float3 V, float3 N, float3 X, float3 Y, float3 baseColor, float metallic, float roughness, float litOrShadowArea)
// {
// 	// float NdotL = dot(N, L);
// 	float NdotL = litOrShadowArea;
// 	float NdotV = dot(N, V);  //????这下面一行有一个不可见字符
// 	if (NdotL < 0 || NdotV < 0)
// 	{
// 		NdotL = 0.1f;
// 	}
// 	float3 H = normalize(L + V);
// 	float NdotH = dot(N, H);
// 	float LdotH = dot(L, H);
// 	float3 Cdlin = mon2lin(baseColor);
// 	float Cdlum = 0.3 * Cdlin.x + 0.6 * Cdlin.y + 0.1 * Cdlin.z; // luminance approx.
	
// 	float3 Ctint = Cdlum > 0 ? Cdlin / Cdlum : float3(1, 1, 1); // normalize lum. to isolate hue+sat
// 	float3 Cspec0 = lerp(_specular * 0.08 * lerp(float3(1, 1, 1), Ctint, _specularTint), Cdlin, metallic);
// 	float3 Csheen = lerp(float3(1, 1, 1), Ctint, _sheenTint);
	
// 	// Diffuse fresnel - go from 1 at normal incidence to .5 at grazing
// 	// and mix in diffuse retro-reflection based on roughness
// 	float FL = SchlickFresnel(NdotL), FV = SchlickFresnel(NdotV);
// 	float Fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
// 	float Fd = lerp(1.0, Fd90, FL) * lerp(1.0, Fd90, FV);
	
// 	// Based on Hanrahan-Krueger brdf approximation of isotropic bssrdf
// 	// 1.25 scale is used to (roughly) preserve albedo
// 	// Fss90 used to "flatten" retroreflection based on roughness
// 	float Fss90 = LdotH * LdotH * roughness;
// 	float Fss = lerp(1.0, Fss90, FL) * lerp(1.0, Fss90, FV);
// 	float ss = 1.25 * (Fss * (1 / (NdotL + NdotV) - 0.5) + 0.5);
	
// 	// specular
// 	float aspect = sqrt(1 - _anisotropic * 0.9);
// 	float ax = max(0.001, sqr(roughness) / aspect);
// 	float ay = max(0.001, sqr(roughness) * aspect);
// 	float Ds = GTR2_aniso(NdotH, dot(H, X), dot(H, Y), ax, ay);
// 	float FH = SchlickFresnel(LdotH);
// 	float3 Fs = lerp(Cspec0, float3(1, 1, 1), FH);
// 	float Gs;
// 	Gs = smithG_GGX_aniso(NdotL, dot(L, X), dot(L, Y), ax, ay);
// 	Gs *= smithG_GGX_aniso(NdotV, dot(V, X), dot(V, Y), ax, ay);
	
// 	// sheen
// 	float3 Fsheen = FH * _sheen * Csheen;
	
// 	// clearcoat (ior = 1.5 -> F0 = 0.04)
// 	float Dr = GTR1(NdotH, lerp(0.1, 0.001, _clearcoatGloss));
// 	float Fr = lerp(0.04, 1.0, FH);
// 	float Gr = smithG_GGX(NdotL, 0.25) * smithG_GGX(NdotV, 0.25);
	
// 	return saturate(((1 / PI) * lerp(Fd, ss, _subsurface) * Cdlin + Fsheen)
// 	* (1 - metallic)
// 	+ Gs * Fs * Ds + 0.25 * _clearcoat * Gr * Fr * Dr);
// }
///
/// PBR indirect
///
float3 F_Indir(float NdotV, float3 F0, float roughness)
{
	float Fre = exp2((-5.55473 * NdotV - 6.98316) * NdotV);
	return F0 + Fre * saturate(1 - roughness - F0);
}
// sample spherical harmonics
float3 Env_Diffuse(float3 N)
{
	real4 SHCoefficients[7];
	SHCoefficients[0] = unity_SHAr;
	SHCoefficients[1] = unity_SHAg;
	SHCoefficients[2] = unity_SHAb;
	SHCoefficients[3] = unity_SHBr;
	SHCoefficients[4] = unity_SHBg;
	SHCoefficients[5] = unity_SHBb;
	SHCoefficients[6] = unity_SHC;
	
	return max(float3(0, 0, 0), SampleSH9(SHCoefficients, N));
}
// sample reflection probe
float3 Env_SpecularProbe(float3 N, float3 V, float roughness)
{
	float3 reflectWS = reflect(-V, N);
	float mip = roughness * (1.7 - 0.7 * roughness) * 6;

	float4 specColorProbe = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectWS, mip);
	float3 decode_specColorProbe = DecodeHDREnvironment(specColorProbe, unity_SpecCube0_HDR);
	return decode_specColorProbe;
}
float3 BRDF_Indirect_Simple(float3 L, float3 V, float3 N, float3 X, float3 Y, float3 baseColor)
{
	float3 relfectWS = reflect(-V, N);
	float3 env_Cubemap = texCUBElod(_Cubemap, float4(relfectWS, _CubemapMip)).rgb;
	float fresnel = pow(max(0.0, 1.0 - dot(N, V)), _FresnelPow);
	float3 env_Fresnel = env_Cubemap * fresnel + _FresnelColor * fresnel;

	return env_Fresnel;
}
float3 BRDF_Indirect(float3 L, float3 V, float3 N, float3 X, float3 Y, float3 baseColor, float metallic, float roughness)
{
	// diff
	float3 F = F_Indir(dot(N, V), compute_F0(_ior), roughness);
	float3 env_diff = Env_Diffuse(N) * (1 - F) * (1 - metallic) * baseColor;

	// specular
	float3 env_specProbe = Env_SpecularProbe(N, V, roughness);
	float3 Flast = fresnelSchlickRoughness(max(dot(N, V), 0.0), compute_F0(_ior), roughness);
	float2 envBDRF = SAMPLE_TEXTURE2D(_IBL_LUT, sampler_IBL_LUT, float2(dot(N, V), roughness)).rg;
	float3 env_specular = env_specProbe * (Flast * envBDRF.r + envBDRF.g);

	return saturate(env_diff + env_specular);
}

