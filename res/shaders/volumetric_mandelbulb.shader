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

#define MAX_STEPS 100
float mandelbulb_power = 10.;
const int mandelbulb_iter_num = 64;
const vec3 SUN_POSITION = vec3(1.0, 1.0, -1.0);

float mandelbulb_sdf(vec3 pos) {
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < mandelbulb_iter_num ; i++)
	{
		r = length(z);
		if (r>1.5) break;
		
		// convert to polar coordinates
		float theta = acos(z.z / r);
		float phi = atan(z.y, z.x);

		dr =  pow( r, mandelbulb_power-1.0)*mandelbulb_power*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow( r,mandelbulb_power);
		theta = theta*mandelbulb_power;
		phi = phi*mandelbulb_power;
		
		// convert back to cartesian coordinates
		z = pos + zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
	}
	return 0.5*log(r)*r/dr;
}
float scene(vec3 p) {
  float distance = mandelbulb_sdf(p);
  return -distance;
}

float shadow(vec3 ro, vec3 rd) {
    float res = 1.0;
    float t = 0.02; // Initial march size
    for (int i = 0; i < 50; i++) {
        float h = mandelbulb_sdf(ro + rd * t);
        res = min(res, 10.0 * h / t);
        if (h < 0.001) break;
        t += h;
    }
    return clamp(res, 0.0, 1.0);
}

const float MARCH_SIZE = 0.08;
vec3 calculateNormal(vec3 p) {
    const vec3 e = vec3(0.001, 0.0, 0.0);
    float d = mandelbulb_sdf(p);
    return normalize(vec3(
        mandelbulb_sdf(p + e.xyy) - d,
        mandelbulb_sdf(p + e.yxy) - d,
        mandelbulb_sdf(p + e.yyx) - d
    ));
}
vec4 raymarch(vec3 rayOrigin, vec3 rayDirection) {
  float depth = 0.0;
  vec3 p = rayOrigin + depth * rayDirection;
    vec3 sunDirection = normalize(SUN_POSITION);
  vec4 res = vec4(0.0);

  for (int i = 0; i < MAX_STEPS; i++) {
    float density = scene(p);

    // We only draw the density if it's greater than 0
    if (density > 0.0) {


        vec3 normal = calculateNormal(p);
        float nl = max(dot(normal, sunDirection), 0.0);
      float diffuse = clamp((scene(p) - scene(p + 0.3 * sunDirection)) / 0.3, 0.0, 1.0 );
      float shadow = shadow(rayOrigin,rayDirection);
      vec3 lin = vec3(0.60,0.60,0.75) * 1.1 + 0.8 * vec3(1.0,0.6,0.3) * diffuse;
      vec4 color = vec4(mix(vec3(1.0, 0.5, 0.5), vec3(0.0, 0.0, 0.0), density), density );
      color.rgb *= lin;
      color.rgb *= color.a;
      color.rgb += shadow;
      color.rgb *= nl;
      res += color * (1.0 - res.a);
    }

    depth += MARCH_SIZE;
    p = rayOrigin + depth * rayDirection;
  }

  return res;
}

void main() {
  vec2 uv = gl_FragCoord.xy/uResolution.xy;
  uv -= 0.5;
  uv.x *= uResolution.x / uResolution.y;

  // Ray Origin - camera
  vec3 ro = cameraPos;

   vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
    vec3 cameraUp = cross(cameraRight, cameraFront);
    vec3 rd = normalize(uv.x * cameraRight + uv.y * cameraUp + cameraFront);

  
    vec3 color = vec3(0.0);

  // Sun and Sky
  vec3 sunDirection = normalize(SUN_POSITION);
  float sun = clamp(dot(sunDirection, rd), 0.0, 1.0 );
  // Base sky color
  color = vec3(0.678,0.91,0.957);
  // Add vertical gradient
  color -= 0.8 * vec3(0.7,0.7,0.90) * rd.y;
  // Add sun color to sky
  color += 0.5 * vec3(1.0,0.75,0.5) * pow(sun, 10.0);

  vec4 res = raymarch(ro, rd);
    color = color * (1.0 - res.a) + res.rgb;

  gl_FragColor = vec4(color, 1.0);
}
