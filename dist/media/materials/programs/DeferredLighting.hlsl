#include "defines.hlsl"
#include "NormalEncoding.cg"
#include "Shading.cg"

struct VS_IN
{
  float4 position : POSITION;
};

struct PS_IN
{
  float4 position : SV_POSITION;
  float4 lightPositionView : TEXCOORD0;
  float4 viewPosition : TEXCOORD1;
};

SamplerState LightBufferMap
{
  AddressU = Wrap;
  AddressV = Wrap;
  //Filter = MIN_MAG_MIP_POINT;
  Filter = ANISOTROPIC;
};

PS_IN LightBuffer_vs(
		     VS_IN input,
		     uniform float4 lightPosView,
		     uniform float4x4 vMat,
#if !DIRECTIONAL		    
		     uniform float4x4 vpMat,		    
		     uniform float4x4 wvpMat,
		     uniform float4x4 wvMat
#else
		     //directional
		     uniform float4x4 wvpMat,
		     uniform float4x4 wvMat,
		     uniform float4 dirLightWorld
#endif
		     )
{
  PS_IN output = (PS_IN)0;
#if !DIRECTIONAL
  
  output.position = mul(wvpMat, input.position);
  output.lightPositionView = mul(vMat, lightPosView);
  output.viewPosition = mul(wvMat, input.position);
#else
  output.position = mul(wvpMat, input.position);
  output.viewPosition = mul(wvMat, input.position);
  output.lightPositionView = dirLightWorld;
#endif
  return output;
}

void LightBuffer_ps(
		    PS_IN input,
		    uniform float4 texDim,
		    uniform float farClip,
		    uniform Texture2D gBuffer : register(t0),
#if DIRECTIONAL
		    uniform Texture2D hfaoBuffer : register(t1),
		    uniform float uLightY,
#else
		    uniform float4 inLightColor,
#endif
		  
		    out float4 oColor0 : SV_Target0
		    )
{
#if DIRECTIONAL
  float lightPower = 1.0;
  //float4 lightColor = float4(0.9, 0.91, 1.0, 1.0);
  float4 lightColor = float4(0.98828, 0.71875, 0.07422, 1.0);
#else
  float lightPower = 1.0;
  //float4(0.89, 0.89, 0.9, 1.0)
  float4 lightColor =  inLightColor * lightPower;

#endif
  //const float4 attFactor = float4(1.0f, 10.8f, 10.8f, 0.0f);
  //const float4 attFactor = float4(1.0f, 50.8f, 50.8f, 0.0f);
  const float4 attFactor = float4(1.0f, 0.4f, 1.8f, 0.0f);
  //compute the G buffer position.
  float2 texCoord = input.position.xy / texDim.xy;
  float4 gBPixel = gBuffer.Sample(LightBufferMap, texCoord.xy);
  
  //float specularMod = 1.0;
  float specularMod = gBPixel.z;
  gBPixel.xyz = normalize(decode(gBPixel));
  
  //float4 realPos = gBuffer1.Sample(LightBufferMap, texCoord.xy);

#if DIRECTIONAL
  //float hfaoFactor = tex2D(hfaoBuffer, texCoord.xy).x;
  float hfaoFactor = hfaoBuffer.Sample(LightBufferMap, texCoord.xy);
#endif

  
  //specularMod = 1.0;
  float specularPower = exp2(10*specularMod + 1);
  //float specularPower = exp2(specularMod + 1);
  //float specularPower = specularMod;
  float3 viewRay = float3(input.viewPosition.xy * (farClip / input.viewPosition.z), farClip);
 
  float3 viewPos = viewRay * gBPixel.w;
  //float3 viewPos = realPos.xyz;
  //now compute light terms for point light
#if !DIRECTIONAL
  
  float3 lightDir = (input.lightPositionView.xyz - viewPos);
  //float3 lightDir = float3(0, 0, 0) - viewPos.xyz;
  float d = length(lightDir);
  //float C = 1.0 / (attFactor.x + attFactor.y * d + attFactor.z * d * d);
  float sqr = (lightPower * d / 2.0 + 1.0);
  float C = 1.0 / (sqr * sqr) * lightPower;
  //float C = 1.0 / (lightPower * (d * d));
#else
  float3 lightDir = input.lightPositionView.xyz;
  float C = 1.0;
#endif  

  lightDir = normalize(lightDir); 
 
#if !DIRECTIONAL
  
  float3 diffuse = float3(0, 0, 0);
  float specular = 0;

  //specular = SpecularBlinnPhong(gBPixel.xyz, lightDir, viewPos, lightColor.xyz, specularMod, specularPower, C);
  //diffuse = ComputeOrenNayar(gBPixel.xyz, lightDir, viewPos, lightColor.xyz, 1.0 - specularMod, C);
  oColor0 = ComputeTriaceShading(gBPixel.xyz, lightDir, viewPos, lightColor.xyz, specularMod, specularPower, C);
  //oColor0 = float4(diffuse.xyz, specular);
  //oColor0 = float4(0, 0, 0, 0);
  //oColor0 = ComputeBlinnPhongSpecular(gBPixel.xyz, lightDir, viewPos, lightColor.xyz, specularMod, specularPower, C);
  //oColor0.w += 1.0;
  //oColor0 = float4(gBPixel.xyz, 1.0);
  //oColor0 = float4(input.lightPositionView.xyz, 1.0);
  //oColor0 = float4(d, d, d, 1.0);
  //oColor0 = float4(realPos.xyz, 1.0);
  //oColor0 = float4(diffuse, 0.0) * lightPower;
  //oColor0 = float4(diffuse, 0.0) * lightPower;
  //oColor0 = float4(gBPixel.xyz, 1.0);
  //oColor0 = float4(1.0, 0.0, 0.0, 1.0);
#else
  float nightMulti = 1.0;
  float3 diffuse = float3(0, 0, 0);
  float specular = 0;
  float4 diffuseSpec;
  float stepv = smoothstep(0.01, 0.02,  hfaoFactor);
  if(uLightY <= 0.0f)
    {
      nightMulti = 0.01;
      
      lightColor.xyz = float3(0.3, 0.41, 0.53) * -uLightY;
      //specular = SpecularBlinnPhong(gBPixel.xyz, lightDir, viewPos, lightColor.xyz, specularMod, specularPower, 1.0);
      //diffuse = ComputeOrenNayar(gBPixel.xyz, lightDir, viewPos, lightColor.xyz, 1.0 - specularMod, 1.0);
      //diffuse *= 1.0;
      oColor0 = ComputeTriaceShading(gBPixel.xyz, lightDir, viewPos, lightColor.xyz, specularMod, specularPower, 1.0);
      //oColor0 = float4(diffuse, specular);
    }
  else
    {
      //lightColor.xyz *= lightPower * uLightY;
      //specular = SpecularBlinnPhong(gBPixel.xyz, lightDir, viewPos, lightColor.xyz, specularMod, specularPower, 1.0);
      //diffuse = ComputeOrenNayar(gBPixel.xyz, lightDir, viewPos, lightColor.xyz, 1.0 - specularMod, 1.0);
      //diffuse *= lightPower;
      oColor0 = ComputeTriaceShading(gBPixel.xyz, lightDir, viewPos, lightColor.xyz * lightPower, specularMod, specularPower, 1.0);
      //diffuse = float3(0, 0, 0);
      //oColor0 = float4(diffuse, specular);
      //oColor0.xyz *= 0;
    }
  
  if(stepv >= 1.0)
    //oColor0 = float4(diffuse,  specular) * nightMulti * hfaoFactor;// * stepv;
    oColor0 *= nightMulti * hfaoFactor;
  else 
    //oColor0 *= nightMulti * hfaoFactor * stepv;
    oColor0 = float4(diffuse,  specular) * nightMulti * hfaoFactor * stepv;    
    
  //color *= hfaoFactor;
  //oColor0 = float4(0, 0, 0, 0);
#endif

  //oColor0 = trunc(oColor0 + 0.5);
}

