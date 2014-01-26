uniform mat4 viewProjectionMatrix;

attribute vec4 vertex;


void main(void)
{
  gl_Position = viewProjectionMatrix * vertex;
}
