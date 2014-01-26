//This is a test
//const float4 CONST_COLOR = float4(1.0, 0.0, 0.0, 1.0);
#include "defines.hlsl"
#include "NormalEncoding.cg"

struct VS_IN
{
  float4 position : POSITION;
  float4 colour : COLOR0;
  float4 uv1 : TEXCOORD0;
  float3 normal : NORMAL0;
  float3 tangent : TANGENT0;
};
struct PS_IN
{
  float4 position : SV_POSITION;
  float4 colour : COLOR0;
#if BLOCKS
  float4 worldPosition : TEXCOORD0;
  float4 textureArrayIdx : TEXCOORD1;
  float4 worldPosition2 : TEXCOORD2;
  float4 viewPosition : TEXCOORD3;
  float4 shadow : TEXCOORD4;
  float4 shadow1 : TEXCOORD5;
  float4 shadow2 : TEXCOORD6;
  float camDepth : TEXCOORD7;
#elif CHARACTER
  float3 modelNormal : TEXCOORD0;
  float4 uv1 : TEXCOORD1;
  float3 viewDirectionWorld : TEXCOORD2;
  float3 viewPosition : TEXCOORD3;
  float4 shadow : TEXCOORD4;
  float4 shadow1 : TEXCOORD5;
  float4 shadow2 : TEXCOORD6;
  float camDepth : TEXCOORD7;
#elif HARDWARE
  float3 viewPosition : TEXCOORD0;
#endif
};


SamplerState TextureArrayMap
{
  //Filter=ANISOTROPIC;
  Filter=MIN_MAG_MIP_POINT;
  MipLODBias=8.0;
  MinLOD=0;
  MaxLOD=1;
};
SamplerState LBufferMap
{
  //Filter=ANISOTROPIC;
  Filter=MIN_MAG_MIP_POINT;
};
SamplerState GBufferMap
{
  //Filter=ANISOTROPIC;
  //MipLODBias=2.0;
  Filter=MIN_MAG_MIP_POINT;
};

SamplerState CubeMap
{
};

SamplerState ShadowSampler
{
  Filter=MIN_MAG_MIP_LINEAR;
};
SamplerComparisonState ShadowSamplerComp
{
  ComparisonFunc = GREATER_EQUAL;
  Filter=MIN_MAG_MIP_LINEAR;
};

SamplerState ColorMap
{
  Filter=ANISOTROPIC;
  MipLODBias=8.0;
  MinLOD=0;
  MaxLOD=1;
};

float shadowPCF(Texture2D shadowMap, float4 shadowMapPos, float2 offset, float bias)
{
  //return 1.0;
  //shadowMapPos.xyz = shadowMapPos.xyz / shadowMapPos.w;
  //return shadowMap.SampleCmpLevelZero(ShadowSamplerComp, shadowMapPos.xy, 
  //		      shadowMapPos.z - 0.0001);
  //return shadowMap.Gather(ShadowSampler, shadowMapPos.xy).r > 0 ? 1 : 0.5;
  
  //shadowMapPos = shadowMapPos / shadowMapPos.w;
  
  float2 uv = shadowMapPos.xy;
	
	float3 o = float3(offset, -offset.x) * 0.3f;
	//shadowMapPos.z = 0.0;
	//const float bias = 0.0001;
	shadowMapPos.z -= bias;
	// Note: We using 2x2 PCF. Good enough and is alot faster.
	float c=0;
	float depth = shadowMap.Sample(ShadowSampler, uv.xy - o.xy).r;// + bias;
	c = (depth >= 1 || depth >= shadowMapPos.z) ? 1.0 : 0.0;
	depth = shadowMap.Sample(ShadowSampler, uv.xy + o.xy).r;// + bias;
	c += (depth >= 1 || depth >= shadowMapPos.z) ? 1.0 : 0.0;
	depth = shadowMap.Sample(ShadowSampler, uv.xy + o.zy).r;// + bias;
	c += (depth >= 1 || depth >= shadowMapPos.z) ? 1.0 : 0.0;
	depth = shadowMap.Sample(ShadowSampler, uv.xy - o.zy).r;// + bias;
	c += (depth >= 1 || depth >= shadowMapPos.z) ? 1.0 : 0.0;
  
	
			 /*
	c +=		(shadowMapPos.z <= shadowMap.Sample(ShadowSampler, uv.xy + o.xy).r + bias)>0 ? 1 : 0; // bottom right
	c +=		(shadowMapPos.z <= shadowMap.Sample(ShadowSampler, uv.xy + o.zy).r + bias)>0 ? 1 : 0; // bottom left
	c +=		(shadowMapPos.z <= shadowMap.Sample(ShadowSampler, uv.xy - o.zy).r + bias)>0 ? 1 : 0; // top right
			 */
	//float c =	(shadowMapPos.z <= tex2Dlod(shadowMap, uv.xyyy - o.xyyy).r) ? 1 : 0; // top left
	//c +=		(shadowMapPos.z <= tex2Dlod(shadowMap, uv.xyyy + o.xyyy).r) ? 1 : 0; // bottom right
	//c +=		(shadowMapPos.z <= tex2Dlod(shadowMap, uv.xyyy + o.zyyy).r) ? 1 : 0; // bottom left
	//c +=		(shadowMapPos.z <= tex2Dlod(shadowMap, uv.xyyy - o.zyyy).r) ? 1 : 0; // top right
	return clamp((c / 4), 0.2, 1.0);
	//return c / 4.0;
}


PS_IN main_vp(
	      VS_IN input
	      
#if BLOCKS
	      , uniform float4x4 worldViewProj
	      , uniform float4x4 wMat
#elif HARDWARE
	      , float4 mat14 : TEXCOORD1
	      , float4 mat24 : TEXCOORD2
	      , float4 mat34 : TEXCOORD3
	      , uniform float4x4 vpMat
#elif CHARACTER
	      , uniform float4x4 worldViewProj
	      , uniform float4x4 worldMat
	      , uniform float3 eyePosition

#endif

#if BLOCKS || CHARACTER
	      , uniform float4 depthRange0
	      , uniform float4 depthRange1
	      , uniform float4 depthRange2
	      , uniform float4x4 texMatrix0
	      
	      , uniform float4x4 shadow
	      , uniform float4x4 shadow1
	      , uniform float4x4 shadow2
	      
#endif

	      , uniform float4x4 wvMat
)
{
  PS_IN output = (PS_IN)0;
  
#if BLOCKS
  output.position = mul(worldViewProj, input.position);
  output.colour = input.colour;
  output.worldPosition = input.position + float4(0.5, 0.5, 0.5, 0.5);
  output.textureArrayIdx = input.uv1.x * 256.0 - 1; //expand into [0, 255] so it becomes an index
  float4 worldP = mul(wMat, input.position);
  output.worldPosition2 = worldP;
 
  //output.textureArrayIdx = 1; //expand into [0, 255] so it becomes an index
#elif HARDWARE
  float3x4 worldMatrix;
  worldMatrix[0] = mat14;
  worldMatrix[1] = mat24;
  worldMatrix[2] = mat34;
  output.position = mul(vpMat, float4(mul(worldMatrix, input.position).xyz, 1.0f));
  output.viewPosition = output.position.xyz;
#elif CHARACTER
  output.position = mul(worldViewProj, input.position);
  output.colour = float4(1.0, 1.0, 1.0, 1.0);
  output.uv1 = input.uv1;
  float4 worldP = mul(worldMat, input.position);
  output.viewDirectionWorld = normalize(worldP.xyz - eyePosition);
  output.viewPosition = mul(wvMat, input.position);
#endif

#if BLOCKS || CHARACTER
  
  //output.shadow = texMatrix0[0];
  //output.shadow = mul(texMatrix0, worldP);
  //output.shadow = mul(texMatrix0, worldP);
  //output.shadow = mul(shadow, input.position);
  //output.shadow1 = mul(shadow1, input.position);
  //output.shadow2 = mul(shadow2, input.position);


  output.shadow = mul(texMatrix0, worldP);
  //output.shadow.z = (output.shadow.z - depthRange0.x) * depthRange0.w;

  //output.shadow.z = (output.shadow.z - depthRange0.x) * depthRange0.w;
  //output.shadow1.z = (output.shadow1.z - depthRange1.x) * depthRange1.w;
  //output.shadow2.z = (output.shadow2.z - depthRange2.x) * depthRange2.w;

  output.camDepth = output.position.z;

#endif


  
  return output;

}

PS_IN zpass_vp(
	       VS_IN input,
	       uniform float4x4 wvpMat
	       )
{
  PS_IN output = (PS_IN)0;
  output.position = mul(wvpMat, input.position);
  return output;
}


float4 zpass_fp(
		PS_IN input
		) : SV_TARGET0
{
  return float4(0, 0, 0, 0);
}



float getFresnelTerm(float3 normal, float3 view, float fnaught)
{
  return fnaught + (1.0 - fnaught)*pow(1.0 - saturate(dot(normal, view)), 5.0);
}

float3 getSpecularColor(float4 diffuseSpec, float fnaught, float3 normal, float3 viewPosition)
{
  float fresnelTerm = getFresnelTerm(normal, viewPosition, fnaught);
  
  //float3 fresnelTerm = float3(0.549585,0.556114,0.554256);
  const float3 lumVec = float3(0.2126, 0.7152, 0.0722);
  //lPixel.w *= fresnelTerm;
  float lum = dot(lumVec, diffuseSpec.xyz) + 0.0001;

  float3 temp = fresnelTerm * diffuseSpec.xyz * (diffuseSpec.w / lum);
  return temp;
}

float4 main_fp(
	       PS_IN input
	     	       //SH coeffs.
	       , uniform float SHC_R_0
	       , uniform float SHC_R_1
	       , uniform float SHC_R_2
	       , uniform float SHC_R_3
	       , uniform float SHC_R_4
	       , uniform float SHC_R_5
	       , uniform float SHC_R_6
	       , uniform float SHC_R_7
	       , uniform float SHC_R_8 
#if FULLBAND
	       , uniform float SHC_R_9 
	       , uniform float SHC_R_10
	       , uniform float SHC_R_11 
	       , uniform float SHC_R_12 
	       , uniform float SHC_R_13 
	       , uniform float SHC_R_14 
	       , uniform float SHC_R_15 
	       , uniform float SHC_R_16 
	       , uniform float SHC_R_17
#endif
	       , uniform float SHC_G_0
	       , uniform float SHC_G_1
	       , uniform float SHC_G_2
	       , uniform float SHC_G_3
	       , uniform float SHC_G_4
	       , uniform float SHC_G_5
	       , uniform float SHC_G_6
	       , uniform float SHC_G_7
	       , uniform float SHC_G_8 
#if FULLBAND
	       , uniform float SHC_G_9 
	       , uniform float SHC_G_10 
	       , uniform float SHC_G_11 
	       , uniform float SHC_G_12 
	       , uniform float SHC_G_13 
	       , uniform float SHC_G_14 
	       , uniform float SHC_G_15 
	       , uniform float SHC_G_16 
	       , uniform float SHC_G_17
#endif
	       , uniform float SHC_B_0
	       , uniform float SHC_B_1
	       , uniform float SHC_B_2
	       , uniform float SHC_B_3
	       , uniform float SHC_B_4
	       , uniform float SHC_B_5
	       , uniform float SHC_B_6
	       , uniform float SHC_B_7
	       , uniform float SHC_B_8
#if FULLBAND 
	       , uniform float SHC_B_9
	       , uniform float SHC_B_10
	       , uniform float SHC_B_11
	       , uniform float SHC_B_12
	       , uniform float SHC_B_13
	       , uniform float SHC_B_14
	       , uniform float SHC_B_15
	       , uniform float SHC_B_16
	       , uniform float SHC_B_17
#endif
	       , uniform float4 gBufferMapDimension
	       , uniform float4x4 inverseViewMat
	       , uniform float uLightY
#if BLOCKS
	       //, uniform SamplerState TextureArrayMap : register(s0)
	       , uniform float3 playerPosition
#elif CHARACTER
	       , uniform SamplerState TextureMap : register(s0)
#endif
	       //, uniform SamplerState GBufferMap : register(s1)
	       //, uniform SamplerState LBufferMap : register(s2)
	       , uniform SamplerState HFAOBufferMap : register(s3)
	       , uniform SamplerState CubeMap : register(s4)
#if BLOCKS
	       , uniform Texture2DArray textureArray : register(t0)
#elif CHARACTER
	       , uniform Texture2D tex2D : register(t0)
	       , uniform float4x4 inverseTransViewMatrix
#endif
#if BLOCKS || CHARACTER
	       , uniform float4 invShadowMapSize0
	       , uniform float4 invShadowMapSize1
	       , uniform float4 invShadowMapSize2
	       , uniform float4 pssmSplitPoints
#endif
	       , uniform Texture2D gBuffer : register(t1)
	       , uniform Texture2D lBuffer : register(t2)
	       , uniform Texture2D hfaoBuffer : register(t3)
	       , uniform TextureCube cubeTexture : register(t4)
	       , uniform Texture2D ssaoBuffer : register(t5)
	       , uniform Texture2D shadowTex0 : register(t6)
	       , uniform Texture2D shadowTex1 : register(t7)
	       , uniform Texture2D shadowTex2 : register(t8)
	       , uniform Texture2D colormap : register(t9)

) : SV_TARGET0
{
  //SH constants
  const float C1 = 0.429043;
  const float C2 = 0.511664;
  const float C3 = 0.743125;
  const float C4 = 0.886227;
  const float C5 = 0.247708;
  const float d1 = -0.081922;
  const float d2 = -0.231710;
  const float d3 = -0.061927;
  const float d4 = -0.087578;
  const float d5 = -0.013847;
  const float d6 = -0.123854;
  const float d7 = -0.231710;
  const float d8 = -0.327688;
  const float3 L00 = float3(SHC_R_0, SHC_G_0, SHC_B_0);
  const float3 L1m1 = float3(SHC_R_1, SHC_G_1, SHC_B_1);
  const float3 L10 = float3(SHC_R_2, SHC_G_2, SHC_B_2);
  const float3 L11 = float3(SHC_R_3, SHC_G_3, SHC_B_3);
  const float3 L2m2 = float3(SHC_R_4, SHC_G_4, SHC_B_4);
  const float3 L2m1 = float3(SHC_R_5, SHC_G_5, SHC_B_5);
  const float3 L20 = float3(SHC_R_6, SHC_G_6, SHC_B_6);
  const float3 L21 = float3(SHC_R_7, SHC_G_7, SHC_B_7);
  const float3 L22 = float3(SHC_R_8, SHC_G_8, SHC_B_8);

  const float3 L00a  = float3( 0.78908,  0.43710,  0.54161);
  const float3 L1m1a = float3( 0.39499,  0.34989,  0.60488);
  const float3 L10a  = float3(-0.33974, -0.18236, -0.26940);
  const float3 L11a  = float3(-0.29213, -0.05562,  0.00944);
  const float3 L2m2a = float3(-0.11141, -0.05090, -0.12231);
  const float3 L2m1a = float3(-0.26240, -0.22401, -0.47479);
  const float3 L20a  = float3(-0.15570, -0.09471, -0.14733);
  const float3 L21a  = float3( 0.56014,  0.21444,  0.13915);
  const float3 L22a  = float3( 0.21205, -0.05432, -0.30374);

#if FULLBAND
  const float3 L4m4 = float3(SHC_R_9, SHC_G_9, SHC_B_9);
  const float3 L4m3 = float3(SHC_R_10, SHC_G_10, SHC_B_10);
  const float3 L4m2 = float3(SHC_R_11, SHC_G_11, SHC_B_11);
  const float3 L4m1 = float3(SHC_R_12, SHC_G_12, SHC_B_12);
  const float3 L40 = float3(SHC_R_13, SHC_G_13, SHC_B_13);
  const float3 L41 = float3(SHC_R_14, SHC_G_14, SHC_B_14);
  const float3 L42 = float3(SHC_R_15, SHC_G_15, SHC_B_15);
  const float3 L43 = float3(SHC_R_16, SHC_G_16, SHC_B_16);
  const float3 L44 = float3(SHC_R_17, SHC_G_17, SHC_B_17);
#endif
  
  float alpha = 1.0;
  float shadowT = 1.0;

#if BLOCKS || CHARACTER



  float3 shadowIn;
  float dist = input.camDepth;
  float shadowS = 1.0;

  #if CHARACTER
  float bias=0.0001;
  #else
  float bias=0.0001;
#endif
  
  //if(dist <= pssmSplitPoints.y)
    
  if(1)
  //if(dist <= 25)
    {
      shadowT = shadowPCF(shadowTex0, input.shadow, invShadowMapSize0.xy, bias);
      //shadowT = shadowPCF(shadowTex0, input.shadow, invShadowMapSize0.xy);
      //shadowIn = shadowTex0.Sample(GBufferMap, input.shadow).xyz;
      //shadowT = (input.shadow.z < shadowIn.x) ? 0.1 : 1.0;
    }
  
  //else if(dist <= 55)
    else if(dist < pssmSplitPoints.z)
    {
      shadowT = shadowPCF(shadowTex1, input.shadow, invShadowMapSize1.xy, bias);
      //shadowIn = shadowTex1.Sample(GBufferMap, input.shadow1).xyz;
      //shadowT = (input.shadow1.z < shadowIn.x) ? 0.1 : 1.0;
    }
  else
    {
      shadowT = shadowPCF(shadowTex2, input.shadow, invShadowMapSize2.xy, bias);
      //shadowIn = shadowTex2.Sample(GBufferMap, input.shadow2).xyz;
      //shadowT = (input.shadow2.z < shadowIn.x) ? 0.1 : 1.0;
    }
  
  //shadowT = input.shadow.z;
  /*
  const float LIMIT = 128.0;
  float shadowTT, shadowSS;
  shadowTT = input.shadow.x;// / input.shadow.w;
  shadowTT = trunc(shadowTT*LIMIT + 0.5) / LIMIT;
  shadowSS = input.shadow.y;// / input.shadow.w;
  shadowSS = trunc(shadowSS*LIMIT + 0.5) / LIMIT;
  
  float m = 0.9;
  shadowTT = shadowTT * m + (1.0 - m)*shadowT;
  shadowSS = shadowSS * m + (1.0 - m)*shadowT;
  */
  //shadowT = input.shadow.z / input.shadow.w;
  
  //input.shadow.z -= 0.0005;
  
  //shadowT = shadowTex0.Sample(ShadowSampler, input.shadow.xy / input.shadow.w).r;
  
  //shadowT = max(0.0, shadowT - input.shadow.z/input.shadow.w) + 0.00001;
  
  //input.shadow = input.shadow / input.shadow.w;
  /*
  float pixelOffset = invShadowMapSize0.x;
  float4 depths = float4(
			 shadowTex0.Sample(ShadowSampler, input.shadow.xy + float2(-pixelOffset, 0)).x,
			 shadowTex0.Sample(ShadowSampler, input.shadow.xy + float2(+pixelOffset, 0)).x,
			 shadowTex0.Sample(ShadowSampler, input.shadow.xy + float2(0, -pixelOffset)).x,
			 shadowTex0.Sample(ShadowSampler, input.shadow.xy + float2(0, +pixelOffset)).x);

  float2 differences = abs(depths.yw - depths.xz);
  float gradient = min(0.098, max(differences.x, differences.y));
  float gradientFactor = gradient * 0;

  const float fixedDepthBias = 0.01;

  float centerDepth = shadowTex0.Sample(ShadowSampler, input.shadow.xy).x;
  float depthAdjust = gradientFactor + (fixedDepthBias * centerDepth);
  float finalCenterDepth = centerDepth + 0.0005;//depthAdjust;
  */
  
  //centerDepth += 0.000005;
  //shadowT = centerDepth + 0.005;
  //shadowT = (finalCenterDepth > input.shadow.z) ? 1.0 : 0.2;
  /*  
#if CHARACTER
  shadowT = (finalCenterDepth > input.shadow.z) ? 1.0 : 0.2;
  //shadowT = finalCenterDepth;
  //shadowT = centerDepth - 0.001;
#else
  shadowT = (finalCenterDepth > input.shadow.z) ? 1.0 : 0.2;
  //shadowT = abs(finalCenterDepth);
  #endif
  //shadowT = centerDepth;
  */

  //shadowT *= 0.9;
  /*
  if(input.shadow.z > shadowT)
    shadowT = 0.2;
  else
    shadowT = 1.0;
  */
#endif
#if BLOCKS
  
  const float yOffset = 0.0;
  const float xOffset = 5.0;
  const float zOffset = 5.0;
  const float zOffset2 = 2.0;
  if (input.worldPosition2.y >= playerPosition.y + yOffset)
    {
      if(input.worldPosition2.x <= playerPosition.x + xOffset && input.worldPosition2.x > playerPosition.x - xOffset)
	{
	  if(input.worldPosition2.z <= playerPosition.z + zOffset && input.worldPosition2.z > playerPosition.z - zOffset2)
	    {
	      discard;
	      //alpha = 0.2;
	    }
	}
    }
  
#endif


  float2 screenCoord = input.position.xy / gBufferMapDimension.xy; //figure out screen-space uv.

  float4 gBufferNormal; 

  gBufferNormal.xyz = gBuffer.Sample(GBufferMap, screenCoord).xyz;
  //gBufferNormal.xyz = shadowTex0.Sample(GBufferMap, screenCoord).xyz;
  gBufferNormal.xyz = normalize(decode(gBufferNormal));
 
  //  #if !CHARACTER 
  //gBufferNormal.xyz = mul(inverseViewMat, float4(gBufferNormal.xyz, 0.0)).xyz; //transform gBufferNormal from view-space into world-space. Note this a transformation of normal.
  gBufferNormal.xyz = mul(float4(gBufferNormal.xyz, 0.0), inverseViewMat).xyz;

  //  #else
  //gBufferNormal.xyz = mul(inverseTransViewMatrix, float4(gBufferNormal.xyz, 0.0)).xyz;
  //gBufferNormal.xyz = mul(transpose(inverseTransViewMatrix), float4(gBufferNormal.xyz, 0.0)).xyz;
  //#endif
  
  //gBufferNormal.xyz = (gBufferNormal.xyz = 1.0) * 0.5;
  //float3 n = float3(-gBufferNormal.z, -gBufferNormal.x, gBufferNormal.y);
  float3 n = gBufferNormal;
  float4 shColor = float4(1.0, 1.0, 1.0, 1.0);
  
  //Do the SH inner product to derive sh radiance. This is a lambertian expansion. See SH environment map paper for the derivation (ex: the N.L Lambertian term).
  //We do a 5th order expansion. See Stupid SH tricks for the 4th and 5th order coeffs (that doesn't appear in SH environment map paper). Note: I manually derived the 4th
  //and 5th order terms, so they may be wrong. Need to double check against Stupid SH tricks paper.
  shColor.xyz =  C1 * L22 * (n.x * n.x - n.y * n.y) +
                      C3 * L20 * n.z * n.z +
                      C4 * L00 -
                      C5 * L20 +
                      2.0 * C1 * L2m2 * n.x * n.y +
                      2.0 * C1 * L21  * n.x * n.z +
                      2.0 * C1 * L2m1 * n.y * n.z +
                      2.0 * C2 * L11  * n.x +
                      2.0 * C2 * L1m1 * n.y +
    2.0 * C2 * L10  * n.z
#if FULLBAND
+
    d1 * L4m4 * (n.x*n.x*(n.x*n.x-3.0*n.y*n.y) - n.y*n.y * (3.0*n.x*n.x-n.y*n.y)) +
    d2 * L4m3 * (n.x*n.z*(n.x*n.x-3.0*n.y*n.y)) +
    d3 * L4m2 * ((n.x*n.x-n.y*n.y)*(7.0*n.z*n.z-1.0)) + 
    d4 * L4m1 * ((n.x*n.z*(7.0*n.z*n.z-3.0))) + 
    d5 * L40 * (35.0*n.z*n.z*n.z*n.z - 30.0*n.z*n.z + 3.0) + 
    d4 * L41 * (n.y*n.z*(7.0*n.z*n.z-3.0)) + 
    d6 * L42 * (n.x*n.y*(7.0*n.z*n.z-1.0)) + 
    d7 * L43 * (n.y*n.z*(3.0*n.x*n.x-n.y*n.y)) + 
    d8 * L44 * (n.x*n.y*(n.x*n.x-n.y*n.y));
#else
  ;
#endif

  float4 shColor2; //This is SH for a 2nd lighting environment. The first is from dynamic sky. We mix the two.
  shColor2.xyz = C1 * L22a * (n.x * n.x - n.y * n.y) +
    C3 * L20a * n.z * n.z +
    C4 * L00a -
    C5 * L20a +
    2.0 * C1 * L2m2a * n.x * n.y +
    2.0 * C1 * L21a  * n.x * n.z +
    2.0 * C1 * L2m1a * n.y * n.z +
    2.0 * C2 * L11a  * n.x +
    2.0 * C2 * L1m1a * n.y +
    2.0 * C2 * L10a  * n.z;

  float4 lPixel;
  float hfaoFactor = 1.0;
  float ssaoFactor = 1.0;
  float4 texDiffuse;
  float nightFactor = 1.0;
  //0.04
  
  lPixel = lBuffer.Sample(LBufferMap, screenCoord);
  //lPixel = shadowTex0.Sample(LBufferMap, screenCoord);
  //lPixel.xyz *= (1.0 - fnaught);
  

  //lPixel.xyz = (1.0 - lPixel.w)*lPixel.xyz;
  

#if BLOCKS
  float3 texCoord = ComputeBlockUV2(input.worldPosition);
  
  float4 texDiffuseTemp = textureArray.Sample(TextureArrayMap, float3(texCoord.xy, input.textureArrayIdx.x));
  float3 color = colormap.Sample(ColorMap, float2(texDiffuseTemp.x, (input.textureArrayIdx.x + 7.0)/256.0)).xyz; //sample at (x, halfTexture) texture is 8 height
  //texDiffuse.xyzw = texDiffuseTemp.xxxw;
  //const float4 bottom = float4(0.0, 0.6, 0.6, 1);
  //const float4 top = float4(0.0, 0.99, 1.0, 1);
  //texDiffuse = lerp(bottom, top, texDiffuseTemp.x);
  //texDiffuse.xyz = texDiffuse.xyz; //glow factor
  //texDiffuse.xyz *= input.colour.xyz;
  texDiffuse.xyz = color;
  float3 temp = getSpecularColor(lPixel, texDiffuseTemp.y, gBufferNormal, normalize(input.viewPosition));
  lPixel.xyz *= (1.0 - texDiffuseTemp.y); //y is fnaught
  //texDiffuse = textureArray.Sample(TextureArrayMap, float3(texCoord.xy, 1));
  //texDiffuse = testMap.Sample(GBufferMap, texCoord.xy);
  //lPixel = lBuffer.Sample(LBufferMap, screenCoord);

  hfaoFactor = hfaoBuffer.Sample(HFAOBufferMap, screenCoord).x;
  ssaoFactor = ssaoBuffer.Sample(HFAOBufferMap, screenCoord).x;

 

  if(uLightY < 0.0)
    {
      nightFactor = 1.0 / (1.0 - uLightY) * 0.007;
    }
  // float shScale = 0.00005;
  float shScale = 0.00005;
  float shScale2 = 0.3;
  //stepv 0.105, 0.12
  float stepv = smoothstep(0.01, 0.02, hfaoFactor);
  //float stepv = step(0.05, hfaoFactor);
  //shColor2.xyz *= shScale;
  shColor.xyz = (1.0 - stepv)*shColor2.xyz *shScale2
    + stepv*shColor.xyz * nightFactor * shScale;
  //shColor.xyz *= nightFactor * shScale;
  //shColor.xyz *= shScale;
  //shColor *= ssaoFactor;
  //shColor2.xyz *= shScale;
  
  
  //shColor.xyz = texDiffuse.xyz * shColor.xyz * hfaoFactor * ssaoFactor + texDiffuse.xyz * (1.0 - temp) *lPixel.xyz + temp;
  shColor.xyz = float3(1, 0.84, 0)*texDiffuseTemp.z + (texDiffuse.xyz * shColor.xyz * hfaoFactor * ssaoFactor + texDiffuse.xyz * lPixel.xyz*ssaoFactor + temp)*(1.0 - texDiffuseTemp.z);
  shColor.xyz *= shadowT;
  //shColor.xyz = texDiffuse.xyz * shadowT;
#elif CHARACTER || HARDWARE
#if CHARACTER
  texDiffuse = tex2D.Sample(TextureMap, input.uv1);
  float fnaught = 0.24;
  
  float3 temp = getSpecularColor(lPixel, fnaught, gBufferNormal, normalize(input.viewPosition));
  lPixel.xyz *= (1.0 - fnaught);
#else
  texDiffuse = float4(0.8, 0.1, 0.1, 0);
#endif

  
  //lPixel.xyz = (1.0 - lPixel.w) * lPixel.xyz;
  
  //float lum = dot(float3(0.2126, 0.7152, 0.0722), lPixel.xyz);
  //lPixel.w = lPixel.w / (lum + 0.0001);

  hfaoFactor = hfaoBuffer.Sample(HFAOBufferMap, screenCoord).x;
  ssaoFactor = ssaoBuffer.Sample(HFAOBufferMap, screenCoord).x;

#if CUBEMAP
  //float3 reflectVec = reflect(input.viewDirectionWorld, gBufferNormal.xyz);
  //float3 texCubemap = cubeTexture.Sample(CubeMap, reflectVec);

  //texDiffuse.xyz = lerp(texDiffuse.xyz, texCubemap, 0.0);
  
#endif 
   
  if(uLightY < 0.0)
    {
      nightFactor = 1.0 / (1.0 - uLightY) * 0.007;
    }

  float shScale = 0.00005;
  float shScale2 = 0.003;
  //0.105, 0.12
  float stepv = smoothstep(0.04, 0.05, hfaoFactor); //select between shMaps.//was 0.05
  shColor.xyz = (1.0 - stepv)*shColor2.xyz * shScale2
  + stepv*shColor.xyz * shScale * nightFactor;
  //shColor.xyz *= 0.0005;
  //texDiffuse.xyz *= 0.5;
  
  //shColor.xyz = texDiffuse.xyz * shColor.xyz * hfaoFactor * ssaoFactor + texDiffuse.xyz * (1.0 - temp)*lPixel.xyz + temp;
  
  shColor.xyz = texDiffuse.xyz * shColor.xyz * hfaoFactor * ssaoFactor + texDiffuse.xyz *lPixel.xyz*ssaoFactor + temp;
  shColor.xyz *= shadowT;
#endif
 
#if BLOCKS
  //return float4(input.shadow.zzz / input.shadow.w, 1);
  //return float4(shadowT, shadowT, shadowT, 1.0);
  //return float4(shadowTT, shadowSS, 0, 1.0);
  return float4(shColor.xyz, alpha);
  //return float4(gBufferNormal.xyz, 1.0);
#else
  //return float4(input.shadow.xy,0, 1);
  //return float4(shadowT, shadowT, shadowT, 1.0);
  return float4(shColor.xyz, alpha);
#endif
  //return float4(ssaoFactor, ssaoFactor, ssaoFactor, 1.0);
  //return float4(stepv, stepv, stepv, 1.0);
  //return float4(gBufferNormal.xyz, 1.0);
  //return float4(gBufferNormal.xyz, 1.0);
}
