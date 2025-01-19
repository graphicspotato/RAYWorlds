#shader vertex
#version 330 core 
        
layout (location = 0) in vec4 position;
        
void main()
{
    gl_Position = position;
};

#shader fragment
#version 330 core

//https://www.youtube.com/watch?v=afc8qabsGYg watch this and do it again.

uniform float uTime;
uniform vec2 uResolution;
uniform vec3 cameraPos;
uniform vec3 cameraFront;

#define MAX_STEPS 100
#define MAX_DIST 100.0
#define SURFACE_DIST 0.01

float sineWeird(vec3 p){
    return 1 - sin(p.x) + sin(p.y) + sin(p.z) / 3.0;
}

vec3 getColor(float amount){
    vec3 col = 0.5 + 0.5 * cos(6.28319 * (vec3(0.2,0.0,00) + amount * vec3(1.0, 1.0, 0.5)));
    return col * amount;
 }

float sdSphere(vec3 p, float radius) {
    return length(p) - radius;
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float scene(vec3 p) {
  //float plane = p.y + 2.0;
  float scale = 10;
  return max(sdSphere(p, 1.0f), (0.85 - sineWeird(p * scale)) / scale);
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

float softShadows(vec3 ro, vec3 rd, float mint, float maxt, float k ) {
  float resultingShadowColor = 1.0;
  float t = mint;
  for(int i = 0; i < 50 && t < maxt; i++) {
      float h = scene(ro + rd*t);
      if( h < 0.001 )
          return 0.0;
      resultingShadowColor = min(resultingShadowColor, k*h/t );
      t += h;
  }
  return resultingShadowColor ;
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
    float shadows = softShadows(p, lightDirection, 0.1, 5.0, 64.0);
    color = getColor(length(d) / 7.5);
  }
  gl_FragColor = vec4(color, 1.0);
}
