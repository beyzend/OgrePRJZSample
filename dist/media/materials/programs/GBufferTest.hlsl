#include "defines.hlsl"
#include "NormalEncoding.cg"



struct VS_IN
{
  float4 position : POSITION;
  float4 uv1 : TEXCOORD0;
  float4 uv2 : TEXCOORD1;
  float3 normal : NORMAL;
#if CHARACTER
  float3 tangent : TANGENT0;
#endif
};

struct PS_IN
{
  float4 position : SV_POSITION;
  float4 viewPosition : TEXCOORD0;
#if BLOCKS
  float4 worldPosition : TEXCOORD2; //used to compute UV in pixel shader.
  float4 textureArrayIdx : TEXCOORD3; //used for texture array access.
  float4 worldPosition2 : TEXCOORD4;
#endif
#if CHARACTER || SIMPLE
  float3 viewNormal : TEXCOORD1;
  float4 uv1 : TEXCOORD2;
#endif
#if CHARACTER
  float3 viewTangent : TEXCOORD3;
  float3 viewBiTangent : TEXCOORD4;
#endif

};


PS_IN GBuffer_vs(
		 VS_IN input
		 //defines
		 ,uniform float4x4 wvpMat
		 ,uniform float4x4 wvMat
#if BLOCKS
		 ,uniform float4x4 wMat
		 ,uniform float3 playerPosition
#endif
		 //#if CHARACTER
		 ,uniform float4x4 invWvMat
		 //#endif
		 )
{
  PS_IN output = (PS_IN)0;
  output.position = mul(wvpMat, input.position);
  output.viewPosition = mul(wvMat, input.position);
#if BLOCKS
  //offset by 0.5 to move into "block" space.
  output.worldPosition = input.position + float4(0.5, 0.5, 0.5, 0.5); 
  output.worldPosition2 = mul(wMat, input.position);
  output.textureArrayIdx = input.uv1.x * 256.0 - 1; //move into [0, 255] idx
  
  //output.textureArrayIdx = 1; //move into [0, 255] idx
#endif
#if SIMPLE
  output.viewNormal = mul(float4(input.normal, 0.0), invWvMat).xyz;
  //output.viewNormal = mul(wvMat, float4(input.normal, 0.0)).xyz;
  
  output.uv1 = input.uv1;
#endif
#if CHARACTER
  output.viewNormal = mul(float4(input.normal, 0.0), invWvMat).xyz;
  //output.viewNormal = mul(invWvMat, float4(input.normal, 0.0)).xyz;
  //output.viewTangent = mul(invWvMat, float4(input.tangent, 0.0)).xyz;
  output.viewTangent = mul(float4(input.tangent, 0.0), invWvMat).xyz;
  output.viewBiTangent = cross(output.viewTangent, output.viewNormal);

  output.uv1 = input.uv1;
#endif
  return output;
}

SamplerState NormalMap 
{
  Filter = ANISOTROPIC;
};

float4 GBuffer_ps(
		PS_IN input
		, uniform float nearClip 
		, uniform float farClip 
#if BLOCKS
		, uniform Texture2DArray normalMapArray : register(t0)
		, uniform Texture2DArray specularMapArray : register(t1)
		, uniform float3 playerPosition
		
#endif
#if CHARACTER 
		, uniform Texture2D normalMap : register(t0)
		, uniform Texture2D specularMap : register(t1)
#endif
		//, out float4 oColor0 : SV_Target0
		//, out float4 oColor1 : SV_Target1
			       ) : SV_Target0
{
  float4 oColor0 = float4(1.0, 0.0, 0.0, 1.0);
  half2 encodedNormal;
  float specularMod = 1.0;
#if BLOCKS
  
  const float yOffset = 2.0;
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
	    }
	}
    }
  
  //Derive TBN in view-space. We can do this because geometry is Cubic.
  float3 T = normalize(ddx(input.viewPosition.xyz));
  float3 B = normalize(ddy(input.viewPosition.xyz));
  float3 vNormal = normalize(cross(B, T));
  B = normalize(cross(T, vNormal));
  float3x3 tbnToViewMat = float3x3(T, B, vNormal);

  //generate UV
  float3 textureCoords = ComputeBlockUV2(input.worldPosition);
  //float3 normal = testMap.Sample(NormalMap, textureCoords.xy).xyz * 2.0 - 1.0;
  float4 normalSpec = normalMapArray.Sample(NormalMap, float3(textureCoords.xy, input.textureArrayIdx.x));
  float3 normal = normalSpec.xyz * 2.0 - 1.0;
  //float3 normal = normalMapArray.Sample(NormalMap, float3(textureCoords.xy, input.textureArrayIdx.x)).xyz * 2.0 - 1.0; //transform into [-1.0, 1.0]
  //float3 normal = normalMapArray.Sample(NormalMap, float3(textureCoords.xy, 1)).xyz * 2.0 - 1.0;  
  //specularMod = specularMapArray.Sample(NormalMap, float3(textureCoords.xy, input.textureArrayIdx.x)).x;
  //specularMod = min(1.0, specularMod / 0.9);
  specularMod = normalSpec.w;
  //specularMod = 0.4;
  //normal.y = -normal.y;
  //normal = vNormal;
#elif CHARACTER
  float3 T = input.viewTangent;
  float3 B = input.viewBiTangent;
  float3x3 tbnToViewMat = float3x3(T, B, input.viewNormal);
  float3 normal = normalize(normalMap.Sample(NormalMap, input.uv1).xyz * 2.0 - 1.0);
  specularMod = specularMap.Sample(NormalMap, input.uv1).x;
  normal.y = -normal.y;
  //transform normal from tangent-space into view space.
  //encodedNormal = encode(normalize(half3(mul(normal, tbnToViewMat))));
  //encodedNormal = mul(normal, tbnToViewMat);
  //encodedNormal = normalize(half3(mul(normal, tbnToViewMat)));
#elif SIMPLE
  float3 normal = input.viewNormal;
  
#endif 
  float clipDistance = farClip - nearClip;
  //normal = normalize(normal);
#if CHARACTER || BLOCKS
  //oColor0 = float4(encode(mul(normal, tbnToViewMat)), specularMod, length(input.viewPosition.xyz) / farClip); //output normal, specularMod, and linear depth.
  oColor0 = float4(encode(mul(normal, tbnToViewMat)), specularMod, input.viewPosition.z / farClip); //output normal, specularMod, and linear depth.
  return oColor0;
  //oColor0 = float4(normal, input.viewPosition.z / farClip);
#else 
  //oColor0 = float4(encode(normal), specularMod, length(input.viewPosition.xyz) / farClip);
  oColor0 = float4(encode(normal), specularMod, input.viewPosition.z / farClip);
  return oColor0;
#endif
}
