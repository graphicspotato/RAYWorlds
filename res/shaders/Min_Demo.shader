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
#define MAX_DIST 100.0
#define SURFACE_DIST 0.01
vec3 getColor(float amount) {
  vec3 color = 0.5 + 0.5 * cos(6.2831 * (vec3(1.0, 0.7, 0.4) * amount + vec3(0.1, 0.25, 0.2)));
  return color * amount;
}


float sdSphere(vec3 p, float radius) {
    return length(p) - radius;
}
float sdPyramid( vec3 p, float h )
{
  float m2 = h*h + 0.25;
    
  p.xz = abs(p.xz);
  p.xz = (p.z>p.x) ? p.zx : p.xz;
  p.xz -= 0.5;

  vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);
   
  float s = max(-q.x,0.0);
  float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );
    
  float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
  float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    
  float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);
    
  return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
}
// sigmoid
float smin( float a, float b, float k )
{
    k *= log(2.0);
    float x = b-a;
    return a + x/(1.0-exp2(x/k));
}

float scene(vec3 p) {
  float plane = p.y + 1.0;

  float sphere2 = sdSphere(p + vec3(1.0, 0.5 + sin(uTime)/2.0, 0.0), 1.0);
  float pyramid = sdPyramid(p/2.0 - vec3(0.7 + cos(uTime*2.0), 0.5 + sin(uTime)/2.0, 0.0), 1.0);

  float distance1 = smin(pyramid, sphere2,0.25);
  float distance2 = smin(plane, distance1,0.25);

  return distance2;
}

float raymarch(vec3 ro, vec3 rd) {
  float dO = 0.0;

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

vec3 calcNormal(in vec3 p) {
    const float eps = 0.0001;
    const vec2 h = vec2(eps, 0.0);

    return normalize(vec3(
        scene(p + h.xyy) - scene(p - h.xyy), // Partial derivative in x
        scene(p + h.yxy) - scene(p - h.yxy), // Partial derivative in y
        scene(p + h.yyx) - scene(p - h.yyx)  // Partial derivative in z
    ));
}
void main() {
  vec2 uv = gl_FragCoord.xy/uResolution.xy;
  uv -= 0.5;
  uv.x *= uResolution.x / uResolution.y;

  // Light Position
  vec3 lightPosition = vec3(-10.0, 10.0, 10.0);

	vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
	vec3 cameraUp = cross(cameraRight, cameraFront);

	vec3 ro = cameraPos;
	vec3 rd = normalize(uv.x * cameraRight + uv.y * cameraUp + cameraFront);

  float d = raymarch(ro, rd);
  vec3 p = ro + rd * d;

  vec3 color = vec3(0.0);

  if(d<MAX_DIST) {
    vec3 normal = calcNormal(p);
    vec3 lightDirection = normalize(lightPosition - p);
    float diffuse = max(dot(normal, lightDirection), 0.0);
    color = vec3(1.0, 1.0, 1.0) * getColor(diffuse);// * shadows;
  }

  gl_FragColor = vec4(color, 1.0);
}
