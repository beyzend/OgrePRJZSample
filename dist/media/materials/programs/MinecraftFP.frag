#define SKY 1
#define FULLBAND 1

uniform sampler2D diffuseMap;
//SH stuff.

uniform float SHC_R_0;
uniform float SHC_R_1;uniform float SHC_R_2;uniform float SHC_R_3;uniform float SHC_R_4;uniform float SHC_R_5;uniform float SHC_R_6;uniform float SHC_R_7;uniform float SHC_R_8; 
uniform float SHC_R_9; uniform float SHC_R_10; uniform float SHC_R_11; uniform float SHC_R_12; uniform float SHC_R_13; uniform float SHC_R_14; uniform float SHC_R_15; 
uniform float SHC_R_16; uniform float SHC_R_17;
uniform float SHC_G_0;uniform float SHC_G_1;uniform float SHC_G_2;uniform float SHC_G_3;uniform float SHC_G_4;uniform float SHC_G_5;uniform float SHC_G_6;uniform float SHC_G_7;
uniform float SHC_G_8; 
uniform float SHC_G_9; uniform float SHC_G_10; uniform float SHC_G_11; uniform float SHC_G_12; uniform float SHC_G_13; uniform float SHC_G_14; uniform float SHC_G_15; 
uniform float SHC_G_16; 
uniform float SHC_G_17;
uniform float SHC_B_0;uniform float SHC_B_1;uniform float SHC_B_2;uniform float SHC_B_3;uniform float SHC_B_4;uniform float SHC_B_5;uniform float SHC_B_6;uniform float SHC_B_7;
uniform float SHC_B_8; uniform float SHC_B_9; uniform float SHC_B_10; uniform float SHC_B_11; uniform float SHC_B_12; 
uniform float SHC_B_13; uniform float SHC_B_14; uniform float SHC_B_15; uniform float SHC_B_16; uniform float SHC_B_17;

uniform float uLightY;

varying vec4 worldPos;
varying vec4 textureAtlasOffset;

const float ATLAS_WIDTH = 4096.0;
const float TEX_WIDTH = 256.0;
const float eOffset = TEX_WIDTH / ATLAS_WIDTH;

void main()
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
 vec3 L00 = vec3(SHC_R_0, SHC_G_0, SHC_B_0);
 vec3 L1m1 = vec3(SHC_R_1, SHC_G_1, SHC_B_1);
 vec3 L10 = vec3(SHC_R_2, SHC_G_2, SHC_B_2);
 vec3 L11 = vec3(SHC_R_3, SHC_G_3, SHC_B_3);
 vec3 L2m2 = vec3(SHC_R_4, SHC_G_4, SHC_B_4);
 vec3 L2m1 = vec3(SHC_R_5, SHC_G_5, SHC_B_5);
 vec3 L20 = vec3(SHC_R_6, SHC_G_6, SHC_B_6);
 vec3 L21 = vec3(SHC_R_7, SHC_G_7, SHC_B_7);
 vec3 L22 = vec3(SHC_R_8, SHC_G_8, SHC_B_8);
 vec3 L4m4 = vec3(SHC_R_9, SHC_G_9, SHC_B_9);
 vec3 L4m3 = vec3(SHC_R_10, SHC_G_10, SHC_B_10);
 vec3 L4m2 = vec3(SHC_R_11, SHC_G_11, SHC_B_11);
 vec3 L4m1 = vec3(SHC_R_12, SHC_G_12, SHC_B_12);
 vec3 L40 = vec3(SHC_R_13, SHC_G_13, SHC_B_13);
 vec3 L41 = vec3(SHC_R_14, SHC_G_14, SHC_B_14);
 vec3 L42 = vec3(SHC_R_15, SHC_G_15, SHC_B_15);
 vec3 L43 = vec3(SHC_R_16, SHC_G_16, SHC_B_16);
 vec3 L44 = vec3(SHC_R_17, SHC_G_17, SHC_B_17);

 vec3 normal = cross(dFdx(worldPos.xyz), dFdy(worldPos.xyz));
 normal = normalize(normal);

 vec3 n = vec3(-normal.z, -normal.x, normal.y);
 //vec3 n = normal;
 vec4 diffuseColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);

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
#endif

  //diffuseColor *= 0.000035f;
  
  vec2 uv0 = vec2(1.0, 1.0);
  if(normal.x > 0.5)
    {
      uv0 = fract(vec2(-worldPos.z, worldPos.y));
    }
  
  if(normal.x < -0.5)
    {
      uv0 = fract(vec2(worldPos.z, worldPos.y));
      }
  //top
  
  if(normal.y > 0.5)
    {
      uv0 = fract(vec2(worldPos.x, -worldPos.z));
    }
  
  //bottom
  if(normal.y < -0.5)
    {
      uv0 = fract(vec2(worldPos.x, worldPos.z));
    }
  
  if(normal.z > 0.5)
    {
      uv0 = fract(vec2(worldPos.x, worldPos.y));
      //uv0 = float2(worldPos.x, -worldPos.y);
    }
  if(normal.z < -0.5)
    {
      uv0 = fract(vec2(-worldPos.x,worldPos.y));
    }
  vec4 texAtlasOffset = textureAtlasOffset;
  texAtlasOffset += vec4(uv0 * 0.5f, 0.0, 0.0) * eOffset;
  vec4 texDiffuse = texture(diffuseMap, texAtlasOffset.xy);
  
  float nightMulti;

  nightMulti = 1.0;
  if(uLightY < 0.0)
  nightMulti = mix(0.05, 0.1, -uLightY);
  gl_FragColor = vec4(texDiffuse.xyz * diffuseColor.xyz * nightMulti,texDiffuse.w);
  //gl_FragColor = vec4(texDiffuse.xyz * diffuseColor.xyz, 1.0);
  //gl_FragColor = vec4(, 0.0, 1.0);
}
