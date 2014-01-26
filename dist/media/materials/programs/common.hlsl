void basic_vs_uv(
		  float4 position : POSITION,
		  float2 uv : TEXCOORD0,
		  out float2 oUv : TEXCOORD0,
		  out float4 oPosition : SV_POSITION,
		  uniform float4x4 wvp
		  )
{
  oPosition = mul(wvp, position);
  //oPosition = float4(9999, -9999, 9999, 1.0);
  oUv = uv;
}

void basic_vs(
	      float4 position : POSITION,
	      out float4 oPosition : SV_POSITION,
	      uniform float4x4 wvp
	      )
{
  oPosition = mul(wvp, position);
}

float4 basic_ps(
		) : SV_TARGET0
{
  return float4(1.0, 0.0, 0.0, 1.0);
}

SamplerState TexSampler : register(s0);

float4 basic_texture_ps(
			float2 uv : TEXCOORD0
			, uniform Texture2D tex : register(t0)
			) : SV_TARGET0
{
  return tex.Sample(TexSampler, uv);
}

void basicQuad_vs
(
 in float4 inPos : POSITION,
 out float4 pos : SV_POSITION,
 out float2 uv : TEXCOORD0,
 uniform float4x4 worldViewProj
 )
{
  pos = mul(worldViewProj, inPos);
  inPos.xy = sign(inPos.xy);
  uv = (float2(inPos.x, -inPos.y) + 1.0f) * 0.5;
}
