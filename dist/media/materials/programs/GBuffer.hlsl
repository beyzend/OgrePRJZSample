#include "defines.hlsl"
#include "NormalEncoding.cg"

#if (SIMPLE)
struct VS_IN
{
  float4 position : POSITION;
  float4 uv1 : TEXCOORD0;
  float4 uv2 : TEXCOORD1;
  float3 normal : NORMAL;
};

struct PS_IN
{
  float4 position : SV_POSITION;
  float4 viewPosition : TEXCOORD0;
  float3 normal : TEXCOORD1;
  float4 uv : TEXCOORD2;
};

#elif (CHARACTER)

struct VS_IN
{
  float4 position : POSITION;
  float4 uv1 : TEXCOORD0;
  float4 uv2 : TEXCOORD1;
  float3 tangent : TANGENT0;
  float3 normal : NORMAL;
};

struct PS_IN
{
  float4 position : SV_POSITION;
  float4 viewPosition : TEXCOORD0;
  float3 normal : TEXCOORD1;
  float4 uv : TEXCOORD2;
  float3 viewTangent : TEXCOORD3;
  float3 viewBiTangent : TEXCOORD4;
};

#elif (CHARACTER_HARDWARE_BASIC)

struct VS_IN
{
  float4 position : POSITION;
  float4 uv1 : TEXCOORD0;
  float4 mat14 : TEXCOORD1;
  float4 mat24 : TEXCOORD2;
  float4 mat34 : TEXCOORD3;
  float3 tangent : TANGENT0;
  float3 normal : NORMAL;
};

struct PS_IN
{
  float4 position : SV_POSITION;
  float4 viewPosition : TEXCOORD0;
  float3 normal : TEXCOORD1;
  float4 uv : TEXCOORD2;
  float3 viewTangent : TEXCOORD3;
  float3 viewBiTangent : TEXCOORD4;
};

#elif (BLOCKS) //this is blocks
struct VS_IN
{
  float4 position : POSITION;
  float4 uv1 : TEXCOORD0;
  float4 uv2 : TEXCOORD1;
  float3 normal : NORMAL;
};

struct PS_IN
{
  float4 position : SV_POSITION;
  float4 viewPosition : TEXCOORD0;
  float3 normal : TEXCOORD1;
  float4 worldPosition : TEXCOORD2;
  float4 textureAtlasOffset : TEXCOORD3;
  float2 realUv : TEXCOORD4;
};

#endif

SamplerState GBufferMap
{
  AddressU = Wrap;
  AddressV = Wrap;
};

PS_IN GBuffer_vs(
		 VS_IN input,
		 uniform float3 camPos,
#if (SIMPLE)
		 uniform float4x4 wvMat2,
			
#elif (CHARACTER_HARDWARE_BASIC)
		uniform float4x4 vpMat,
		uniform float4x4 vMat,
#else
		uniform float4x4 wMat,
		uniform float4x4 invtransWvMat,
#endif
		uniform float4x4 wvpMat,
		uniform float4x4 wvMat
		
		)
{
  PS_IN output = (PS_IN)0;
#if (SIMPLE)
  output.position = mul(wvpMat, input.position);
  float4 viewPos = mul(wvMat, input.position);
  output.viewPosition = mul(wvMat, input.position);
  output.normal = input.normal;
  output.uv = input.uv1;
#elif (CHARACTER)
  output.position = mul(wvpMat, input.position);
  output.viewPosition = mul(wvMat, input.position);
  output.normal = mul(wvMat, float4(input.normal, 0.0)).xyz;
  //output.normal = mul(invtransWvMat, float4(input.normal, 0.0)).xyz;
  
  output.uv = input.uv1;
  output.viewTangent = mul(wvMat, float4(input.tangent, 0.0)).xyz;
  //output.viewTangent = mul(invtransWvMat, float4(input.tangent, 0.0)).xyz;
  output.viewBiTangent = cross(output.viewTangent, output.normal);
#elif (CHARACTER_HARDWARE_BASIC)
  float3x4 worldMatrix;
  worldMatrix[0] = input.mat14;
  worldMatrix[1] = input.mat24;
  worldMatrix[2] = input.mat34;

  float4 worldPosition = float4(mul(worldMatrix, input.position).xyz, 1.0);
  output.position = mul(vpMat, worldPosition);
  output.viewPosition = mul(vMat, worldPosition);
  output.normal = mul(vMat, float4(mul(worldMatrix, input.normal).xyz, 0.0)).xyz;
  output.uv = input.uv1;
  output.viewTangent = mul(wvMat, float4(mul(worldMatrix, input.tangent), 0.0)).xyz;
  output.viewBiTangent = cross(output.viewTangent, output.normal);

#elif (BLOCKS) //not character
  output.position = mul(wvpMat, input.position);
  output.viewPosition = mul(wvMat, input.position);
  float2 blockCoords;
  ComputeBlockXY(input.uv1.x, blockCoords);
  //shift by 0.25 because texture in texture atlas are shifted by 0.25. 
  //also scale normalized texture space.
  output.textureAtlasOffset = float4(blockCoords.x + 0.25, 
			      blockCoords.y + 0.25,
			      0, 0) * eOffset;

  output.worldPosition = input.position + float4(0.5, 0.5, 0.5, 0.5);
  output.realUv = input.uv2.xy;
  //oViewPos.xyz = viewPos.xyz + camPos.xyz;
#endif
  return output;
}

void GBuffer_ps(
		PS_IN input,
		uniform float nearClip,
		uniform float farClip,
		uniform Texture2D diffuseMap : register(t0),
		uniform Texture2D normalMap : register(t1),
		uniform Texture2D specularMap : register(t2),
#if CUBEMAP
		uniform Texture2D cubeMap : register(t3),
#endif
		out float4 oColor0 : SV_Target0,
		out float4 oColor1 : SV_Target1
		)
{
  float3 diffuseSample;
  float clipDistance = farClip - nearClip;
#if SIMPLE
  float3 normal = input.normal;
  float4 textureCoords = input.uv;

#elif (BLOCKS)
  //Here we need to derive the TBN in view space. 
  //Because the geometry is a cube, we can do this.
  float3 T = normalize(ddx(input.viewPosition));

  float3 B = normalize(ddy(input.viewPosition));

  float3 vNormal = cross(B, T);

  B = cross(T, vNormal);
  float3x3 tbnToViewMat = float3x3(T, B, vNormal);

#else

  float3 T = input.viewTangent;
  float3 B = input.viewBiTangent;
  float3 vNormal = input.normal;
  float3x3 tbnToViewMat = float3x3(T, B, vNormal);
  float4 textureCoords = input.uv;

#endif


#if SIMPLE
  
#elif (BLOCKS) //blocks
  float3 normal;
  float3 uv0;
  float4 dxdy;

  ComputeBlockUV(normal, input.worldPosition, uv0, dxdy);
  input.textureAtlasOffset.xy += uv0.xy * eOffset;
  
#else //characters etc.

  float3 normal = float3(0, 0, 0);
  

#endif

#if SIMPLE
  float specularMod = 0.001;
  float4 tempDiffuseSample = diffuseMap.Sample(GBufferMap, textureCoords.xy);
  if(tempDiffuseSample.a < 0.9)
    discard;

  diffuseSample = tempDiffuseSample.xyz;

#elif (BLOCKS) 
  normal = normalMap.Sample(GBufferMap, input.textureAtlasOffset.xy).xyz * 2.0 - 1.0;
  normal.y = -normal.y;
  diffuseSample = diffuseMap.Sample(GBufferMap, input.textureAtlasOffset.xy).xyz;

  float specularMod = 1.0;
  specularMod = specularMap.Sample(GBufferMap, input.textureAtlasOffset.xy).xyz;

#elif (CHARACTER || CHARACTER_HARDWARE_BASIC)
  diffuseSample = diffuseMap.Sample(GBufferMap, input.uv).xyz;

  float specularMod = 0.0;

#if !NOSPECULAR
  //specularMod = tex2D(specularMap, textureAtlasOffset.xy).x;
  specularMod = specularMap.Sample(GBufferMap, input.uv).x;
#endif  
  //normal = tex2D(normalMap, textureAtlasOffset.xy).xyz * 2.0 - 1.0;//textureAtlasOffset.xy).xyz;
  normal = normalMap.Sample(GBufferMap, input.uv).xyz * 2.0 - 1.0;
  normal.y = -normal.y;

#endif //end if all

#if SIMPLE
  half2 encodedNormal = encode(normal);
#else
  half2 encodedNormal = encode(normalize(half3(mul(normal, tbnToViewMat))));
  //half2 encodedNormal = encode(normal);
#endif
  oColor0 = float4(encodedNormal, specularMod, input.viewPosition.z / farClip);
  //oColor0 = float4(1.0, 0.0, 0.0, 1.0);
  //oColor0 = float4(mul(normal, tbnToViewMat), inViewPos.z / farClip);
  oColor1 = float4(diffuseSample, 1.0);
  //oColor1 = float4(1.0, 0.0, 0.0, 1.0);
}
