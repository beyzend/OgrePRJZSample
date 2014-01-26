uniform mat4 wvpMat;
uniform mat4 wvMat;

attribute vec4 vertex;
attribute vec4 uv0;

varying vec4 vertexPos;

void main(void)
{
  //this needs to be checked.
  gl_Position = wvpMat * vertex;  
  vertexPos = wvMat * vertex;
}
