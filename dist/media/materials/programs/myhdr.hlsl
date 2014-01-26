#include <hdrutils.hlsl>

SamplerState NoFilterMap
{
  Filter=MIN_MAG_MIP_POINT;
  AddressU=CLAMP;
  AddressV=CLAMP;
};

SamplerState FilterMap
{
  Filter=MIN_MAG_MIP_LINEAR;
  AddressU=CLAMP;
  AddressV=CLAMP;
};

/* Downsample a 2x2 area and convert to greyscale
*/
float4 downscale2x2Luminence(
			     float4 position : SV_POSITION,
	float2 uv : TEXCOORD0,
			     uniform float4 texDim,
	uniform float2 texelSize, // depends on size of source texture
	uniform Texture2D inRTT : register(t0)
    ) : SV_TARGET0
{
  //uv.xy = position.xy / texDim.xy;
	
  //float4 accum = float4(0.0f, 0.0f, 0.0f, 0.0f);
  float4 vColor = 0.0f;
  float fAvg = 0.0f;
  /* float2 texOffset[4] = { */
  /* 		-0.5, -0.5, */
  /* 		-0.5,  0.5,  */
  /* 		 0.5, -0.5, */
  /* 		 0.5, 0.5 }; */

   
    for(int y = -1; y < 1; ++y)
    {
      for(int x = -1; x < 1; ++x)
	{
	  // Get colour from source
	  vColor = inRTT.Sample(NoFilterMap, uv, int2(x, y));// + texelSize * texOffset[i]);
	  fAvg += dot(vColor, LUMINENCE_FACTOR);
	}
    }
	
	// Adjust the accumulated amount by lum factor
	// Cannot use float3's here because it generates dependent texture errors because of swizzle
	//float lum = dot(accum, LUMINENCE_FACTOR);
	// take average of 4 samples
	//lum *= 0.25;
    fAvg *= 0.25;
    
    return float4(fAvg, fAvg, fAvg, 1.0f);
    //return float4(uv.xy, 0.0, 1.0f);
}

/* Downsample a 3x3 area 
 * This shader is used multiple times on different source sizes, so texel size has to be configurable
*/
float4 downscale3x3(
		    float4 position : SV_POSITION,
	float2 uv : TEXCOORD0,
		    uniform float4 texDim,
	uniform float2 texelSize, // depends on size of source texture
	uniform Texture2D inRTT : register(s0)
    ) : SV_TARGET0
{
  //uv.xy = position.xy / texDim.xy;
	
    float4 accum = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float fAvg = 0.0f;
    for(int y = -1; y <= 1; y++)
    {
      for(int x = -1; x <= 1; x++)
	{
	  // Get colour from source
	  //accum += inRTT.Sample(NoFilterMap, uv, int2(x, y));// + texelSize * texOffset[i]);
	  accum = inRTT.Sample(NoFilterMap, uv, int2(x, y));
	  fAvg += accum.r;
	}
    }
    fAvg /= 9;
	// take average of 9 samples
	//accum *= 0.1111111111111111;
    //fAvg *= 0.1111111111111111;
    //return accum;
    //return inRTT.Sample(NoFilterMap, uv);
    return float4(fAvg, fAvg, fAvg, 1.0f);
    //return float4(1.0, 0.0, 0.0, 1.0);
    //return float4(uv.xy, 0.0, 1.0);
}

/* Downsample a 3x3 area from main RTT and perform a brightness pass
*/
float4 downscale3x3brightpass(
			      float4 position : SV_POSITION,
	float2 uv : TEXCOORD0,
	uniform float2 texelSize, // depends on size of source texture
	uniform Texture2D inRTT : register(s0),
	uniform Texture2D inLum : register(s1)
    ) : SV_TARGET0
{
	
    float4 accum = float4(0.0f, 0.0f, 0.0f, 0.0f);

/* 	float2 texOffset[9] = { */
/* 		-1.0, -1.0, */
/* 		 0.0, -1.0, */
/* 		 1.0, -1.0, */
/* 		-1.0,  0.0, */
/* 		 0.0,  0.0, */
/* 		 1.0,  0.0, */
/* 		-1.0,  1.0, */
/* 		 0.0,  1.0, */
/* 		 1.0,  1.0 */
/* 	}; */

    for( int y = -1; y <= 1; y++)
    {
      for(int x = -1; x <= 1; x++)
	{
        // Get colour from source
        //accum += tex2D(inRTT, uv + texelSize * texOffset[i]);
	  accum += inRTT.Sample(NoFilterMap, uv, int2(x, y));// + texelSize * texOffset[i]);
	}
    }
	accum.w = 0.0;
	// take average of 9 samples
	accum *= 0.1111111111111111;

    // Reduce bright and clamp
    accum = max(float4(0.0f, 0.0f, 0.0f, 0.0f), accum - BRIGHT_LIMITER);

	// Sample the luminence texture
    //float4 lum = tex2D(inLum, float2(0.5f, 0.5f));
    float4 lum = inLum.Sample(NoFilterMap, float2(0.5, 0.5));
	// Tone map result
    
    accum =  toneMap(accum, lum.r);
    return float4(accum.xyz, 1.0);
    
}

/* Gaussian bloom, requires offsets and weights to be provided externally
*/
float4 bloom(
	     float4 position : SV_POSITION,
		float2 uv : TEXCOORD0,
		uniform float2 sampleOffsets[15],
		uniform float4 sampleWeights[15],	
		uniform Texture2D inRTT : register(s0)
	     ) : SV_TARGET0
{
    float4 accum = float4(0.0f, 0.0f, 0.0f, 1.0f);
	float2 sampleUV;
    
    for( int i = 0; i < 15; i++ )
    {
        // Sample from adjacent points, 7 each side and central
        sampleUV = uv + sampleOffsets[i];
        //accum += sampleWeights[i] * tex2D(inRTT, sampleUV);
	accum += sampleWeights[i] * inRTT.Sample(NoFilterMap, sampleUV);
	
    }
    return accum;
	
}
		

/* Final scene composition, with tone mapping
*/
float4 finalToneMapping(
			float4 position : SV_POSITION,
	float2 uv : TEXCOORD0,
			uniform float4 texDim,
	uniform Texture2D inRTT : register(s0),
	uniform Texture2D inBloom : register(s1),
	uniform Texture2D inLum : register(s2)
    ) : SV_TARGET0
{
  // Get main scene colour
  //float4 sceneCol = tex2D(inRTT, uv);

  //uv.xy = position.xy / texDim.xy;

  float4 sceneCol = inRTT.Sample(NoFilterMap, uv);
  // Get luminence value
  //float4 lum = tex2D(inLum, float2(0.5f, 0.5f));
  float4 lum = inLum.Sample(NoFilterMap, float2(0.5, 0.5));
  // tone map this
  float4 toneMappedSceneCol = toneMap(sceneCol, lum.r);
	
  // Get bloom colour
  //float4 bloom = tex2D(inBloom, uv);// * 0.3;
  float4 bloom = inBloom.Sample(FilterMap, uv);

  //return debugC;
  //return sceneCol;
  return float4(toneMappedSceneCol.rgb + bloom.rgb * 0.6, 1.0);
  //return float4(sc,sc,sc, 1.0);
  //return float4(lum.rrr, 1.0);
  //return float4(uv.xy, 0.0, 1.0);
}


