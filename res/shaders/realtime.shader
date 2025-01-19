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

uniform float radius;

#define MAX_STEPS 100
#define MAX_DIST 100.0f
#define SURFACE_DIST 0.01f


float sdSphere(vec3 p, float radius)
{
	return length(p) - radius;
}
float scene(vec3 p)
{
 	float distance = sdSphere(p, radius);
	return distance;
}



float rayMarch(vec3 ro, vec3 rd) 
{
  float dO = 0.0;
  //vec3 color = vec3(0.0);

  for(int i = 0; i < MAX_STEPS; i++) 
  {
    vec3 p = ro + rd * dO;
    
	float dS = scene(p);
	dO += dS;

	if(dO > MAX_DIST || dS < SURFACE_DIST) 
	{
        break;
    }
  }
  return dO;
}

vec3 getNormal(vec3 p) {
  vec2 e = vec2(.01, 0);

  vec3 n = scene(p) - vec3(
    scene(p-e.xyy),
    scene(p-e.yxy),
    scene(p-e.yyx));

  return normalize(n);
}

void main()
{
	vec2 uv = gl_FragCoord.xy/uResolution.xy;
	uv -= 0.5;
	uv.x *= uResolution.x / uResolution.y;

	vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
	vec3 cameraUp = cross(cameraRight, cameraFront);

	vec3 ro = cameraPos;
	vec3 rd = normalize(uv.x * cameraRight + uv.y * cameraUp + cameraFront);

	float d = rayMarch(ro, rd);

	vec3 p = ro + rd * d;

	vec3 color = vec3(0.0f, 0.0f, 0.0f);

	  // Light Position
	vec3 lightPosition = vec3(-10.0 * cos(uTime), 10.0, 10.0 * sin(uTime));


	if(d < MAX_DIST)
	{
		vec3 normal = getNormal(p);
		vec3 lightDirection = normalize(lightPosition);
		float diffuse = max(dot(normal, lightDirection), 0.0);
		color = vec3(1.0) * diffuse;
	}

	gl_FragColor = vec4(color, 1.0);
};
