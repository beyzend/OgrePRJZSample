//#define BIAS 0
#if !defined(DEFINES_H_)
#define DEFINES_H_

#define PI 3.14159265f
#define ATLAS_WIDTH 4096.0
#define TEX_WIDTH 256.0
#define eOffset (TEX_WIDTH - 1) / ATLAS_WIDTH

void ComputeBlockXY(float uvX, out float2 blockCoords)
{
  float idx = uvX * 256.0 - 1;
  blockCoords.y = floor(idx / 16.0);
  blockCoords.x = (idx - blockCoords.y * 16.0);
}

float3 ComputeBlockUV2(float4 worldPos)
{
  float3 dx = ddx(worldPos.xyz);
  float3 dy = ddy(worldPos.xyz);
  float3 normal = normalize(cross(dy, dx));
  float3 uv0 = float3(1.0, 1.0, 0);
  if(normal.x > 0.5)
    {
      uv0.xy = float2(-worldPos.z, -worldPos.y);
    }
  
  if(normal.x < -0.5)
    {
      uv0.xy = float2(worldPos.z, -worldPos.y);
    }
  //top 
  if(normal.y > 0.5)
    {
      uv0.xy = worldPos.xz;
    }
  
  //bottom
  if(normal.y < -0.5)
    {
      uv0.xy = float2(-worldPos.x, worldPos.z);
    }
  
  if(normal.z > 0.5)
    {
      uv0.xy = float2(worldPos.x, -worldPos.y);
    }
  if(normal.z < -0.5)
    {
      uv0.xy = float2(-worldPos.x,-worldPos.y);
    }

  return uv0;
}

//This function will compute a block's UV given a block's normal in world coordinates and it's world position.
void ComputeBlockUV(inout float3 normal, float4 worldPos, out float3 uv0, out float4 dxdy)
{
  float3 dx = ddx(worldPos.xyz);
  float3 dy = ddy(worldPos.xyz);
  normal = normalize(cross(dy, dx));

  uv0 = frac(worldPos.xyz);

  if(normal.x > 0.5)
    {
      uv0.xy = frac(float2(-worldPos.z, -worldPos.y));
      //uv0 = frac(float2(-worldPos.z, -worldPos.y));
      //uv0.xy = uv0.zy;
      dxdy = float4(dx.zy, dy.zy);
    }
  
  if(normal.x < -0.5)
    {
      //uv0 = frac(float2(worldPos.z, -worldPos.y));
      uv0.xy = frac(float2(worldPos.z, -worldPos.y));
      //uv0.xy = uv0.zy;
      dxdy = float4(dx.zy, dy.zy);
    }
  //top
  
  if(normal.y > 0.5)
    {
      //uv0 = frac(worldPos.xz);
      uv0.xy = frac(worldPos.xz);
      //uv0.xy = uv0.xz;
      dxdy = float4(dx.xz, dy.xz);
    }
  
  //bottom
  if(normal.y < -0.5)
    {
      uv0.xy = frac(float2(-worldPos.x, worldPos.z));
      //uv0 = frac(float2(-worldPos.x, worldPos.z));
      //uv0.xy = uv0.xz;
      dxdy = float4(dx.xz, dy.xz);
    }
  
  if(normal.z > 0.5)
    {
      uv0.xy = frac(float2(worldPos.x, -worldPos.y));
      //uv0 = frac(float2(-worldPos.x, worldPos.z));
      //uv0.xy = uv0.xz;
      dxdy = float4(dx.xy, dy.xy);
      //uv0 = float2(In.worldPos.x, -In.worldPos.y);
    }
  if(normal.z < -0.5)
    {
      uv0.xy = frac(float2(-worldPos.x,-worldPos.y));
      //uv0 = frac(float2(-worldPos.x,-worldPos.y));
      //uv0.xy = uv0.xy;
      dxdy = float4(dx.xy, dy.xy);
    }
  //dxdy *= 16.0;
  //clamp(uv0, 0.0, 1.0);
}

#endif //!defined
