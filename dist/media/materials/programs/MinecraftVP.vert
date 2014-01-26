//This program defines a test shader for doing "Minecraft" voxel shading.

#define SKY 1
#define FULLBAND 1

//uniform sampler2D terrainTexture;
uniform mat4 worldViewProjMatrix;

attribute vec4 vertex;
attribute vec4 uv0;

varying vec4 worldPos;
varying vec4 textureAtlasOffset;
const float ATLAS_WIDTH = 4096.0;
const float TEX_WIDTH = 256.0;
const float eOffset = TEX_WIDTH / ATLAS_WIDTH;

void main(void)
{
  gl_Position = worldViewProjMatrix * vertex;
  //worldPos is in local space of the cubes. Since Cube center starts at 
  //0, thus we need to translate them left by 0.5 units (cube are length 1.0)
  //so everything is positive.
  worldPos = vertex + vec4(0.5f, 0.5f, 0.5f, 0.5f);
  
  float idx = uv0.x * 256.0 - 1.0;
  //idx = 240.0;
  float blocky = floor(idx / 16.0);
  float blockx = idx - blocky * 16.0;
  
  
  textureAtlasOffset = vec4(blockx + 0.25f, blocky + 0.25f, 0, 0) * eOffset; //translate to align center.
}
