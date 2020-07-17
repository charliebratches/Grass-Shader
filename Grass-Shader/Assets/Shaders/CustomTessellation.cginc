// Tessellation programs based on this article by Catlike Coding:
// https://catlikecoding.com/unity/tutorials/advanced-rendering/tessellation/

struct vertexInput
{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct vertexOutput
{
	float4 vertex : SV_POSITION;
	float3 normal : NORMAL;
	float4 tangent : TANGENT;
};

struct TessellationFactors 
{
	float edge[3] : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

vertexInput vert(vertexInput v)
{
	return v;
}

vertexOutput tessVert(vertexInput v)
{
	vertexOutput o;
	// Note that the vertex is NOT transformed to clip
	// space here; this is done in the grass geometry shader.
	o.vertex = v.vertex;
	o.normal = v.normal;
	o.tangent = v.tangent;
	return o;
}

float _TessellationUniform;
float _TessellationBlending;
sampler2D _GrassMask;

float TessellationEdgeFactor(vertexInput cp0, vertexInput cp1)
{ 
    float3 p0 = mul(unity_ObjectToWorld, float4(cp0.vertex.xyz, 1)).xyz;
    float3 p1 = mul(unity_ObjectToWorld, float4(cp1.vertex.xyz, 1)).xyz;
    float edgeLength = distance(p0, p1);

	//very low setting:
	//float minDist = 10;
	//float maxDist = 50;


	//decent-looking low setting:
	//float minDist = 20;
	//float maxDist = 80;

	//medium:
	//float minDist = 50;
	//float maxDist = 100;

	//good-looking high setting:
	float minDist = 80;
	float maxDist = 220;

	//ultra:
	//float minDist = 120;
	//float maxDist = 2048;

	float _size = 1000;

    float3 edgeCenter = (p0 + p1) * 0.5;
    float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);

	float grassMask = tex2Dlod(_GrassMask,float4(p0.xz / _size,0,0));

    //return  clamp(1.0 - (viewDistance - minDist) / (maxDist - minDist), 0.01, 1.0) * _TessellationUniform;
	return  clamp(1.0 - (viewDistance - minDist) / (maxDist - minDist), 0.01, 1.0) * _TessellationUniform * smoothstep(1,_TessellationBlending,grassMask);
}

TessellationFactors patchConstantFunction (InputPatch<vertexInput, 3> patch)
{
	TessellationFactors f;
	f.edge[0] = TessellationEdgeFactor(patch[1], patch[2]);
	f.edge[1] = TessellationEdgeFactor(patch[2], patch[0]);
	f.edge[2] = TessellationEdgeFactor(patch[0], patch[1]);
	f.inside = (TessellationEdgeFactor(patch[1], patch[2]) +
		TessellationEdgeFactor(patch[2], patch[0]) +
		TessellationEdgeFactor(patch[0], patch[1])) * (1 / 3.0);
	return f;
}

[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("integer")]
[UNITY_patchconstantfunc("patchConstantFunction")]
vertexInput hull (InputPatch<vertexInput, 3> patch, uint id : SV_OutputControlPointID)
{
	return patch[id];
}

[UNITY_domain("tri")]
vertexOutput domain(TessellationFactors factors, OutputPatch<vertexInput, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
	vertexInput v;

	#define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) v.fieldName = \
		patch[0].fieldName * barycentricCoordinates.x + \
		patch[1].fieldName * barycentricCoordinates.y + \
		patch[2].fieldName * barycentricCoordinates.z;

	MY_DOMAIN_PROGRAM_INTERPOLATE(vertex)
	MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
	MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)

	return tessVert(v);
}