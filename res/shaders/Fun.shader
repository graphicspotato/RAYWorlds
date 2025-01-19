#shader vertex
#version 330 core 
        
layout (location = 0) in vec4 position;
        
void main()
{
    gl_Position = position;
};

#shader fragment
#version 330 core

uniform float uTime;
uniform vec2 uResolution;
uniform vec3 cameraPos;
uniform vec3 cameraFront;


#define MAX_STEPS 50
#define MAX_DIST 100.0
#define SURFACE_DIST 0.001

float sdSphere(vec3 p, float radius) {
    return length(p) - radius;
}

float scene(vec3 p) {
  float distance = sdSphere(p, 10.0);
  return distance;
}

vec3 calcNormal(in vec3 p) {
    const float eps = 0.0001;
    const vec2 h = vec2(eps, 0.0);

    return normalize(vec3(
        scene(p + h.xyy) - scene(p - h.xyy), // Partial derivative in x
        scene(p + h.yxy) - scene(p - h.yxy), // Partial derivative in y
        scene(p + h.yyx) - scene(p - h.yyx)  // Partial derivative in z
    ));
}

float raymarch(vec3 ro, vec3 rd) {
  float dO = 0.0;
  vec3 color = vec3(0.0);

  for(int i = 0; i < MAX_STEPS; i++) {
    vec3 p = ro + rd * dO;
    float dS = scene(p);

    dO += dS;

    if(dO > MAX_DIST || dS < SURFACE_DIST) {
        break;
    }
  }
  return dO;
}

float VoxelTrace(vec3 ro, vec3 rd, out bool hit, out vec3 hitNormal, out vec3 pos, out int material)
{
    const int maxSteps = 100;
    vec3 voxel = floor(ro)+.501;
    vec3 step = sign(rd);
	//voxel = voxel + vec3(rd.x > 0.0, rd.y > 0.0, rd.z > 0.0);
    vec3 tMax = (voxel - ro) / rd;
    vec3 tDelta = 1.0 / abs(rd);
    vec3 hitVoxel = voxel;
	int mat = 0;
	
    hit = false;
	
    float hitT = 0.0;
    for(int i=0; i < maxSteps; i++)
	{
		if (!hit)
		{
			float d = scene(voxel);        
			if (d <= 0.0 && !hit)
			{
				hit = true;
				hitVoxel = voxel;
				material = mat;
                break;
			}
			bool c1 = tMax.x < tMax.y;
			bool c2 = tMax.x < tMax.z;
			bool c3 = tMax.y < tMax.z;
			if (c1 && c2) 
			{ 
				if (!hit) 
				{
					hitNormal = vec3(-step.x, 0.0, 0.0);
					hitT = tMax.x;
				}
				voxel.x += step.x;
				tMax.x += tDelta.x;
	
			} else if (c3 && !c1) 
			{
				if (!hit) 
				{
					hitNormal = vec3(0.0, -step.y, 0.0);	
					hitT = tMax.y;
				}
				voxel.y += step.y;
				tMax.y += tDelta.y;
			} else
			{
				if (!hit) 
				{
					hitNormal = vec3(0.0, 0.0, -step.z);		
					hitT = tMax.z;
				}
				voxel.z += step.z;
				tMax.z += tDelta.z;
			}
		}
    }
	if (hit && (hitVoxel.x > 27.0 || hitVoxel.x < -27.0 || hitVoxel.z < -27.0 || hitVoxel.z > 27.0))
	{
		hit = false;
		return 1000.0;
	}
	
	pos = ro + hitT * rd;
	return hitT;
}

void main() {
  vec2 uv = gl_FragCoord.xy/uResolution.xy;
  uv -= 0.5;
  uv.x *= uResolution.x / uResolution.y;

  // Light Position
  vec3 lightPosition = vec3(-10.0 * cos(uTime), 10.0, 10.0 * sin(uTime));

  vec3 ro = cameraPos;

  vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
  vec3 cameraUp = cross(cameraRight, cameraFront);

  // Compute the ray direction based on camera orientation
  vec3 rd = normalize(uv.x * cameraRight + uv.y * cameraUp + cameraFront);
      // Declare variables for VoxelTrace output
    bool hit;
    vec3 hitNormal;
    vec3 pos;
    int material;

    // Call VoxelTrace with all required parameters
    float d = VoxelTrace(ro, rd, hit, hitNormal, pos, material);

  vec3 p = ro + rd * d;

  vec3 color = vec3(0.0);

  if(d<MAX_DIST) {
    vec3 normal = calcNormal(p); // Use the updated calcNormal function
    vec3 lightDirection = normalize(lightPosition - p);

    float diffuse = max(dot(normal, lightDirection), 0.0);
    color = vec3(1.0, 1.0, 1.0) * diffuse;
  }

  gl_FragColor = vec4(color, 1.0);
}
