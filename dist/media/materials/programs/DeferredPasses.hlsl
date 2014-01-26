#include "defines.hlsl"
#include "NormalEncoding.cg"

#if !TEXTURE_ATLAS
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
  float4 worldPosition : TEXCOORD0;
  float4 textureAtlasOffset : TEXCOORD1;
  float3 viewDirectionWorld : TEXCOORD2;
};
#elif TEXTURE_ATLAS
struct VS_IN
{
  float4 position : POSITION;
  float4 colour : COLOR0;
  float4 uv1 : TEXCOORD0;
  float4 normal : NORMAL0;
  float4 tangent : TANGENT0;
};

struct PS_IN
{
  float4 position : SV_POSITION;
  float4 colour : COLOR0;
  float4 worldPosition : TEXCOORD0;
  float4 textureAtlasOffset : TEXCOORD1;
  float3 viewDirectionWorld : TEXCOORD2;

};

#endif


SamplerState GBufferMap
{
  AddressU = Wrap;
  AddressV = Wrap;
};


PS_IN main_vp(
	       VS_IN input,
#if HARDWARE
	       float4 mat14 : TEXCOORD1,
	       float4 mat24 : TEXCOORD2,
	       float4 mat34 : TEXCOORD3,
#endif    
	       uniform float4x4 worldViewProj,
	       uniform float4 lightPosition,
	       uniform float3 eyePosition,
	       uniform float4x4 texWorldViewProjMatrix0,
	       uniform float4x4 texWorldViewProjMatrix1,
	       uniform float4x4 texWorldViewProjMatrix2,
	       uniform float4 depthRange0,
	       uniform float4 depthRange1,
	       uniform float4 depthRange2
#if CUBEMAP
	       , uniform float4x4 worldMat
#endif
#if HARDWARE
	       , uniform float4x4 vpMat
#endif

	      )
{
  PS_IN output = (PS_IN)0;

#if TEXTURE_ATLAS
  
  output.position = mul(worldViewProj, input.position);
  output.colour = input.colour;
  output.worldPosition = input.position + float4(0.5, 0.5, 0.5, 0.5);
  output.textureAtlasOffset = float4(input.uv1.x * 255.0, 0, 0, 0);
  //output.textureAtlasOffset.z = output.position.z;

#elif HARDWARE
  float3x4 worldMatrix;
  worldMatrix[0] = mat14;
  worldMatrix[1] = mat24;
  worldMatrix[2] = mat34;

  output.position = mul(vpMat, float4(mul(worldMatrix, input.position).xyz, 1.0f));
//output.colour = mul(wvMat, input.position); //store view position in colour.
  //output.worldPosition = mul(wvMat, float4(input.normal, 0.0));
  //ouput.textureAtlasOffset = input.uv1;

#else

  output.position = mul(worldViewProj, input.position);
  output.colour = float4(1.0, 1.0, 1.0, 1.0);
  output.worldPosition = float4(input.normal, 1.0);
  output.textureAtlasOffset = input.uv1;

#if CUBEMAP
  float4 worldPos = mul(worldMat, input.position);
  output.viewDirectionWorld = normalize(worldPos.xyz - eyePosition);
#endif

#endif
  
  return output;
}

SamplerState TextureArrayMap 
{
};

float4 main_fp(
	       PS_IN input,
	       //SH coeffs.
	       uniform float SHC_R_0,
	       uniform float SHC_R_1,
	       uniform float SHC_R_2,
	       uniform float SHC_R_3,
	       uniform float SHC_R_4,
	       uniform float SHC_R_5,
	       uniform float SHC_R_6,
	       uniform float SHC_R_7,
	       uniform float SHC_R_8, 
#if FULLBAND
	       uniform float SHC_R_9, 
	       uniform float SHC_R_10,
	       uniform float SHC_R_11, 
	       uniform float SHC_R_12, 
	       uniform float SHC_R_13, 
	       uniform float SHC_R_14, 
	       uniform float SHC_R_15, 
	       uniform float SHC_R_16, 
	       uniform float SHC_R_17,
#endif
	       uniform float SHC_G_0,
	       uniform float SHC_G_1,
	       uniform float SHC_G_2,
	       uniform float SHC_G_3,
	       uniform float SHC_G_4,
	       uniform float SHC_G_5,
	       uniform float SHC_G_6,
	       uniform float SHC_G_7,
	       uniform float SHC_G_8, 
#if FULLBAND
	       uniform float SHC_G_9, 
	       uniform float SHC_G_10, 
	       uniform float SHC_G_11, 
	       uniform float SHC_G_12, 
	       uniform float SHC_G_13, 
	       uniform float SHC_G_14, 
	       uniform float SHC_G_15, 
	       uniform float SHC_G_16, 
	       uniform float SHC_G_17,
#endif
	       uniform float SHC_B_0,
	       uniform float SHC_B_1,
	       uniform float SHC_B_2,
	       uniform float SHC_B_3,
	       uniform float SHC_B_4,
	       uniform float SHC_B_5,
	       uniform float SHC_B_6,
	       uniform float SHC_B_7,
	       uniform float SHC_B_8,
#if FULLBAND 
	       uniform float SHC_B_9, uniform float SHC_B_10, uniform float SHC_B_11, uniform float SHC_B_12, uniform float SHC_B_13, uniform float SHC_B_14, uniform float SHC_B_15, uniform float SHC_B_16, uniform float SHC_B_17,
#endif
	       uniform float uLightY,
	       uniform float4 invShadowMapSize0,
	       uniform float4 invShadowMapSize1,
	       uniform float4 invShadowMapSize2,
	       uniform float4 pssmSplitPoints,
	       uniform float4 texelOffsets,
	       uniform float4 texDim,
#if !TEXTURE_ATLAS
	       uniform Texture2D diffuseMap : register(t3),
#elif TEXTURE_ATLAS
	       uniform Texture2DArray diffuseMapArray : register(t3),
#endif
	       uniform float4x4 inverseViewMat, 
	       uniform Texture2D gBuffer : register(t4),
	       uniform Texture2D lBuffer : register(t5),
	       uniform Texture2D ssaoBuffer : register(t6),
	       uniform Texture2D hfaoBuffer : register(t7),
	       uniform TextureCube cubeMap : register(t8)
	       ) : SV_Target0
{
  
  
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

 
 
 float2 texCoord = input.position.xy / texDim.xy;
 float3 normal2;
 float3 texArrayCoords;
 float4 dxdy;

#if TEXTURE_ATLAS
 texArrayCoords = ComputeBlockUV2(input.worldPosition);
#endif

 normal2 = decode(gBuffer.Sample(GBufferMap, texCoord));
 normal2 = mul(inverseViewMat, float4(normal2, 0.0)).xyz;

#if CUBEMAP

 //texCoord = input.position.xy / texDim.xy;

 //use normal2 which is now in world space and also derive view dir in world space.
 float3 reflectVec = reflect(input.viewDirectionWorld, normal2);
 float4 texCubemap = cubeMap.Sample(GBufferMap, reflectVec);

#endif

#if TEXTURE_ATLAS  
 float3 n = float3(-normal2.z, -normal2.x, normal2.y);
#else
 float3 n = float3(-normal2.z, -normal2.x, normal2.y);
#endif

  float4 diffuseColor = float4(1.0, 1.0, 1.0, 1.0);

  diffuseColor.xyz =  C1 * L22 * (n.x * n.x - n.y * n.y) +
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

  float4 diffuseColor2;
  diffuseColor2.xyz = C1 * L22a * (n.x * n.x - n.y * n.y) +
                      C3 * L20a * n.z * n.z +
                      C4 * L00a -
                      C5 * L20a +
                      2.0 * C1 * L2m2a * n.x * n.y +
                      2.0 * C1 * L21a  * n.x * n.z +
                      2.0 * C1 * L2m1a * n.y * n.z +
                      2.0 * C2 * L11a  * n.x +
                      2.0 * C2 * L1m1a * n.y +
    2.0 * C2 * L10  * n.z;

#if TEXTURE_ATLAS

  float4 lPixel = lBuffer.Sample(GBufferMap, texCoord);
  float hfaoFactor = hfaoBuffer.Sample(GBufferMap, texCoord).x;

#else
  float4 lPixel = lBuffer.Sample(GBufferMap, texCoord);
  float hfaoFactor = hfaoBuffer.Sample(GBufferMap, texCoord);
  float ssaoFactor = ssaoBuffer.Sample(GBufferMap, texCoord).x;
#endif

#if TEXTURE_ATLAS
  //multiply by input.colour to color grass blocks. We're using greyscale grass textures so you need to color it in order to have: spring, winter colors.
  //float4 texDiffuse = diffuseMap.Sample(GBufferMap, texCoord.xy) * input.colour;
  float4 texDiffuse = diffuseMapArray.Sample(TextureArrayMap, float3(texArrayCoords.xy, 0));
  
#elif HARDWARE
  float4 texDiffuse = float4(1.0, 0.0, 0.0, 0.0);
#else
  //float4 texDiffuse = float4(1.0, 0.0, 1.0, 0.0);
  //float4 texDiffuse = diffuseMap.Sample(GBufferMap, float3(texCoord.xy, input.textureAtlasOffset.x));
  float4 texDiffuse = diffuseMap.Sample(GBufferMap, texCoord.xy) * input.colour;
#endif
  float3 specularColour = float3(1.0, 1.0, 1.0);

  float nightMulti;
  nightMulti = 1.0;
  
#if TEXTURE_ATLAS

  if(uLightY < 0.0)//was 0.007, 0.010
    {
      nightMulti = 1.0 / (1.0 + -uLightY) * 0.007;
    }
#else
  if(uLightY < 0.0)//was 0.007, 0.010
    {
      nightMulti = (1.0 / (1.0 + -uLightY) ) * 0.007;
    }
 
#endif

#if TEXTURE_ATLAS
  float shScale = 0.0001;
  float stepv = smoothstep(0.005, 0.05, hfaoFactor);
  //diffuseColor.xyz = (1.0 - stepv)*diffuseColor2.xyz + stepv*diffuseColor.xyz;
  
  diffuseColor.xyz = texDiffuse.xyz * diffuseColor.xyz * shScale * hfaoFactor * nightMulti + texDiffuse.xyz * (lPixel.xyz + lPixel.www);
  //diffuseColor *= shScale;
#else
  
  float shScale = 0.000015; 
 
  float stepv = smoothstep(0.005, 0.05, hfaoFactor); //was 0.2
 
  diffuseColor.xyz = (1.0 - stepv)*diffuseColor2.xyz * 0.00005 + stepv*diffuseColor.xyz * shScale; //note here 0.8 is shScale for diffuseColor2.
  //diffuseColor.xyz = (1.0 - stepv)*diffuseColor2.xyz * 0.000000 + stepv*diffuseColor.xyz * shScale; //note here 0.8 is shScale for diffuseColor2.
  //diffuseColor.xyz *= 0;
#if CUBEMAP
  //texDiffuse.xyz = lerp(texDiffuse.xyz, texCubemap.xyz, 0.1);
#endif
  diffuseColor.xyz = (texDiffuse.xyz * diffuseColor.xyz * hfaoFactor * nightMulti)
    + texDiffuse.xyz * (lPixel.xyz + lPixel.www);
#endif



  float4 vColor = float4(diffuseColor.xyz, 1.0);
  

  //float4 vColor = float4(1.0, 0.0, 1.0, 1.0);
  return vColor;
}

struct SC_PS_IN
{
  float4 position : SV_POSITION;
  float4 depth : TEXCOORD0;
};


SC_PS_IN shadow_caster_vs(
	float4 position			: POSITION
	,uniform float4 depthRange
	,uniform float4x4 wvpMat
	,uniform float4x4 wvMat
	,uniform float4x4 pMat
	,uniform float4x4 texMatrix0
	,uniform float4 texelOffsets
)
{
  SC_PS_IN output = (SC_PS_IN)0;
  const float BIAS = 0.0;
	// this is the view space position
  output.position = mul(wvpMat, position);
  //output.position.xy += texelOffsets.zw * output.position.w;
  //oPosition = mul(texMatrix0, position);
  //oPosition = mul(pMat, oPosition);
	//oDepth.x = oPosition.z;
	//oDepth.y = oPosition.w;
	//output.depth.x = (BIAS + output.position.z - depthRange.x) * depthRange.w;
	//oDepth = oPosition.z;
	//oDepth.xy = oPosition.zw;
	//oDepth.xy = depthRange.xx;
	//oDepth.xyzw = texMatrix0[0];
	//oDepth.xyzw = wvpMat[1];
	output.depth.xy = output.position.zw;
	return output;
}

float4 shadow_caster_ps(
			SC_PS_IN input
			) : SV_TARGET0
{
  //oColour = depth;
  //float finalDepth = depth.x ;/// depth.y;
  //finalDepth = 0.2;
  //oColour = float4(finalDepth, finalDepth, finalDepth, 1);
  //depth = 5.0;
  float depth = input.depth.x;// / input.depth.y;
  return float4(depth, depth, depth, 1);
}

void HWBasic_vs(
		float4 position : POSITION,
		float3 normal : NORMAL,
		float2 uv0 : TEXCOORD0,
		float4 mat14 : TEXCOORD1,
		float4 mat24 : TEXCOORD2,
		float4 mat34 : TEXCOORD3,
		out float4 oPosition : SV_POSITION,
		out float2 oUv0 : TEXCOORD0,
		out float3 oNormal : TEXCOORD1,
		out float4 oViewPosition : TEXCOORD2, 
		uniform float4x4 vpMat
		, uniform float4x4 wvMat
		, uniform float4x4 vMat
		)
{
  float3x4 worldMatrix;
  worldMatrix[0] = mat14;
  worldMatrix[1] = mat24;
  worldMatrix[2] = mat34;
  float3 worldPos = mul(worldMatrix, position).xyz;
  normal = mul(worldMatrix, float4(normal, 0.0)).xyz;
  oPosition = mul(vpMat, float4(worldPos, 1.0f));
  oViewPosition = mul(vMat, float4(worldPos, 1.0f));
  oUv0 = uv0;
  oNormal = mul(vMat, float4(normal, 0.0)).xyz;
}

void HWBasic_ps(
		float2 inUv0 : TEXCOORD0,
		float3 inNormal : TEXCOORD1,
		float4 inViewPosition : TEXCOORD2,
		uniform float farClip,
		uniform Texture2D diffuseMap : register(t0),
		out float4 oColor0 : SV_TARGET0
		)
{
  //float4 tex = diffuseMap.Sample(GBufferMap, inUv0);
  oColor0 = float4(encode(inNormal), 1.0, inViewPosition.z / farClip);


  //oColor0 = float4(float3(1.0, 0.0, 0.0), 0.5);

  //oColor0 = float4(0.109 + colorDelta.x, 0.417, 0.625, 1.0);
}
