//This is a fragment that computes a single jacobi iteration.
uniform float alpha;
uniform float rbeta;
uniform sampler2D x; //x in Ax=b
uniform sampler2D b; //b in Ax=b

void jacobi(in vec2 coords, //texture coords
	    out vec4 xNew, //output computed values.
	    in float alpha, //alpha, see derivation of Possion equations
	    in float rbeta, //reciprocal of beta
	    in sampler2D x, //x vector in Ax=b
	    in sampler2D b); //b bector in Ax=b

void main()
{
  jacobi(gl_TexCoord[0].st,gl_FragColor,alpha,rbeta,x,b);
}
