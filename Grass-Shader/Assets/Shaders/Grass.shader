Shader "/Grass"
{
    Properties
    {
		[Header(Shading)]
        _TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_DepositColor("Deposit Color", Color) = (1,1,1,1)
		_DepositTex("Deposit Texture", 2D) = "defaulttexture" {}
		_GrassMask("Grass Mask Texture", 2D) = "defaulttexture" {}
		_GrassBladeTex("Grass Blade Texture", 2D) = "defaulttexture" {}
		_CutOff("Cut off", float) = 0.1
		_ColorVariationRandom("Color Variation Random", Range(0,128)) = 5
		_TranslucentGain("Translucent Gain", Range(0,1)) = 0.5
		_BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2
		_BladeWidth("Blade Width", Float) = 0.05
		_BladeWidthRandom("Blade Width Random", Float) = 0.02
		_BladeHeight("Blade Height", Float) = 0.5
		_BladeHeightRandom("Blade Height Random", Float) = 0.3
		_TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1
		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_RotationSpeed ("Rotation Speed", Float) = 2.0
		_WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength", Float) = 1
		_BladeForward("Blade Forward Amount", Float) = 0.38
		_BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2
		_maxDist("Max Distance", Float) = 100
		_UseTextureColors("Use Texture Colors", Range(0, 1)) = 0
		[Header(Bending)]
		_YOffset("Y offset", float) = 0.0// y offset, below this is no animation
        _MaxWidth("Max Displacement Width", Range(0, 2)) = 0.1 // width of the line around the dissolve
		_Radius("Radius", Range(0,5)) = 1 // width of the line around the dissolve 
		_CutRadius("Cut Radius", Range(0,5)) = 1 // width of the line around the dissolve (for cutting)
		_Positions("Positions", Vector) = (0,0,0,0) 
		_PositionArray("PositionArray", Float) = 0
		_CutPositions("Cut Positions", Vector) = (0,0,0,0) 
		_CutPositionArray("Cut PositionArray", Float) = 0
    }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"
	#include "./CustomTessellation.cginc"

	#define BLADE_SEGMENTS 2

	float _BendRotationRandom;
	float _BladeHeight;
	float _BladeHeightRandom;	
	float _BladeWidth;
	float _BladeWidthRandom;
	float _BladeForward;
	float _BladeCurve;

	uniform float3 _Positions[100];
	uniform float _PositionArray;

	uniform float3 _CutPositions[100];
	uniform float _CutPositionArray;

	sampler2D _WindDistortionMap;
	float4 _WindDistortionMap_ST;
	float2 _WindFrequency;
	float _WindStrength;

	float _RotationSpeed;

	float _UseTextureColors;

	//limits
	float _SlopeLimit;
	float _BeachLimit;
	float _HeightLimit;
	float _maxDist;

	sampler2D _DepositTex;
	//sampler2D _GrassMask;
	float4 _GrassMask_ST;
	float4 _DepositTex_ST;
	sampler2D _GrassBladeTex;
	uniform float _CutOff;

	//bending
	float _Radius;
	float _MaxWidth;
	float _YOffset;

	//cutting
	float _CutRadius;

	struct geometryOutput
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float3 normal : NORMAL;
		float deposit : DEPOSIT;
		unityShadowCoord4 _ShadowCoord : TEXCOORD1;
	};

	geometryOutput VertexOutput(float3 pos, float2 uv, float3 normal, float deposit)
	{
		geometryOutput o;
		o.pos = UnityObjectToClipPos(pos);
		o.uv = uv;
		o._ShadowCoord = ComputeScreenPos(o.pos);
		o.normal = UnityObjectToWorldNormal(normal);
		o.deposit = deposit;
		#if UNITY_PASS_SHADOWCASTER
			// Applying the bias prevents artifacts from appearing on the surface. i.e. self-shadowing
			o.pos = UnityApplyLinearShadowBias(o.pos);
		#endif
		return o;
	}

	

	// Simple noise function, sourced from http://answers.unity.com/answers/624136/view.html
	// Extended discussion on this function can be found at the following link:
	// https://forum.unity.com/threads/am-i-over-complicating-this-random-function.454887/#post-2949326
	// Returns a number in the 0...1 range.
	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	// Construct a rotation matrix that rotates around the provided axis, sourced from:
	// https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	float3x3 AngleAxis3x3(float angle, float3 axis)
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}

	geometryOutput GenerateGrassVertex(float3 vertexPosition, float width, float height, float forward, float2 uv, float3x3 transformMatrix, float depositSample)
	{
		float3 tangentPoint = float3(width, forward, height);
		float3 tangentNormal = normalize(float3(0, -1, forward));
		float3 localNormal = mul(transformMatrix, tangentNormal);
		float3 localPosition = vertexPosition + mul(transformMatrix, tangentPoint);

		return VertexOutput(localPosition, uv, localNormal, depositSample);
	}

	[maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
	void geo(triangle vertexOutput IN[3], inout TriangleStream<geometryOutput> triStream)
	{
		float3 pos = IN[0].vertex;
		float3 wpos = mul(unity_ObjectToWorld, pos).xyz;// world position
		float _size = 1000;
		//float3 worldPos = mul(unity_ObjectToWorld, IN[0].vertex.xyz);
		float3 worldNormal = mul( unity_ObjectToWorld, float4( IN[0].normal, 0.0 ) ).xyz;
		float slope =  worldNormal.y;
		float dist = distance(_WorldSpaceCameraPos, mul(unity_ObjectToWorld, IN[0].vertex).xyz);

		float grassMask = tex2Dlod(_GrassMask, float4(pos.xz / _GrassMask_ST.xy+_GrassMask_ST.zw,0,0));

		int shouldCreateGrass = sign(slope-0.9) + sign(180-dist) + sign(1 - grassMask);

		if(shouldCreateGrass==3){
			float3 vNormal = IN[0].normal;
			float4 vTangent = IN[0].tangent;
			float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;

			float3x3 tangentToLocal = float3x3(
			vTangent.x, vBinormal.x, vNormal.x,
			vTangent.y, vBinormal.y, vNormal.y,
			vTangent.z, vBinormal.z, vNormal.z
			);

			float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
			float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));
		
			float depositSample = tex2Dlod(_DepositTex, float4(pos.xz / _DepositTex_ST.xy+_DepositTex_ST.zw,0,0));

			float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom - (depositSample*3) + _BladeHeight;
			height = height > 0 ? height : 0.2f; // hack to keep the height from going negative

			float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;
			float forward = rand(pos.yyz) * _BladeForward;

			//bend grass radially away from xyz coords
			float windStrength = _WindStrength;

			for  (int x = 0; x < _PositionArray; x++){
				float3 dis =  distance(_Positions[x], wpos); // distance for radius
				float3 radius = 1 - saturate(dis /_Radius); // in world radius based on objects interaction radius
				float3 sphereDisp = wpos - _Positions[x]; // position comparison
				sphereDisp *= radius; // position multiplied by radius for falloff
				float2 bendArea = abs(clamp(sphereDisp.xz * step(_YOffset, pos.y), -_MaxWidth,_MaxWidth));

				pos.xz += bendArea*2;// vertex movement based on falloff
				height -= bendArea*5;
				forward += bendArea*10;
			}
			
			float2 uv = (pos.xz * (_WindDistortionMap_ST.xy) + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y);
			float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * windStrength;

			float3 wind = normalize(float3(windSample.x, windSample.y, 0));

			float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);

			float3x3 transformationMatrix = mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix), bendRotationMatrix);
			float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);

			
			
			//pos = 1;

			for (int i = 0; i < BLADE_SEGMENTS; i++)
			{
				float t = i / (float)BLADE_SEGMENTS;
				float segmentHeight = height * t;
				float segmentWidth = i == 0 ? width/4 : width * (1 - t); //slimmer bottom segments

				float segmentForward = pow(t, _BladeCurve) * forward;

				float3x3 transformMatrix = i == 0 ? transformationMatrixFacing : transformationMatrix;

				triStream.Append(GenerateGrassVertex(pos, segmentWidth, segmentHeight, segmentForward, float2(0, t), transformMatrix, depositSample));
				triStream.Append(GenerateGrassVertex(pos, -segmentWidth, segmentHeight, segmentForward, float2(1, t), transformMatrix, depositSample));
				
			}

			//for cutting
			bool inArea = false;
			for  (int j = 0; j < _CutPositionArray; j++){
				float3 dis =  distance(_CutPositions[j], wpos); // distance for radius
				float3 radius = 1 - saturate(dis /_CutRadius); // in world radius based on objects interaction radius
				float3 sphereDisp = wpos - _CutPositions[j]; // position comparison
				sphereDisp *= radius; // position multiplied by radius for falloff

				float2 area = abs(clamp(sphereDisp.xz * step(_YOffset, pos.y), -_MaxWidth,_MaxWidth));

				
				height -= area*10;
				if(height > 0)
				{
					//height = 0;
					inArea = true;
				}
			}
			if(inArea)
			{
				triStream.Append(GenerateGrassVertex(pos, 0, height, forward, float2(0.5, 1), transformationMatrix, depositSample));
			}
			triStream.Append(GenerateGrassVertex(pos, 0, height, forward, float2(0.5, 1), transformationMatrix, depositSample));
		}
	}
	ENDCG

    SubShader
    {
		Cull Off

        Pass
        {
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
				"DisableBatching" = "True"//possibly needed for bending?
			}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma geometry geo
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma multi_compile_fwdbase
            
			#include "Lighting.cginc"

			float4 _TopColor;
			float4 _BottomColor;
			float4 _DepositColor;
			float4 _ColorVariationRandom;
			float _TranslucentGain;

			float4 frag (geometryOutput i, fixed facing : VFACE) : SV_Target
            {	
				
				float3 normal = facing > 0 ? i.normal : -i.normal;
				float shadow = SHADOW_ATTENUATION(i);
				float NdotL = saturate(saturate(dot(normal, _WorldSpaceLightPos0)) + _TranslucentGain) * shadow;
				
				float3 ambient = ShadeSH9(float4(normal, 1));
				float4 lightIntensity = NdotL * _LightColor0 + float4(ambient, 1);
				
				float4 tex = tex2Dlod (_GrassBladeTex, float4(i.uv.xy,0,0));
				float deposit = i.deposit;

				float4 col = lerp(_BottomColor + (deposit * _DepositColor), (_TopColor  + (deposit * _DepositColor)) * lightIntensity, i.uv.y) * tex.r * 2;
				if(tex.a < _CutOff) discard;
				return _UseTextureColors ? tex : col;
            }
            ENDCG
        }

		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma multi_compile_shadowcaster

			float4 frag(geometryOutput i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i);
			}

			ENDCG
		}
    }
}