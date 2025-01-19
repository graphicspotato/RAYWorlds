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

#define MAX_STEPS 1000
#define MAX_DIST 1000.0
#define SURFACE_DIST 0.0001

float sdSphere(vec3 p, float radius) {
    return length(p) - radius;
}

float sdBox(vec3 p, vec3 b) {
  vec3 q = abs(p) - b;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}


vec2 hash( vec2 x )  // replace this by something better
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}
float sdPlane(vec3 p)
{
    return p.y + 2.0f;
}

float heightDisplacement(vec3 p)
{
    vec3 c = (p);
    return (noise(c.xz));
    return sin(20.0*c.x)*sin(20.0*c.y)*sin(20.0*c.z) + 1500.0f;
}
float opHeightDisplacement(vec3 p)
{
    float d1 = sdPlane(p);
    float d2 = heightDisplacement(p);
    return d1+d2;
}

vec2 opU( vec2 d1, vec2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}
float scene(vec3 p) {
  //float plane = p.y + 2.0;
  
    vec2 res = vec2(opHeightDisplacement(p), 50.0);
    res = opU(res, vec2(sdPlane(p), 1.0));
        
    return res.x;
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

vec3 getNormal(vec3 p) {
  vec2 e = vec2(.01, 0);

  vec3 n = scene(p) - vec3(
    scene(p-e.xyy),
    scene(p-e.yxy),
    scene(p-e.yyx));

  return normalize(n);
}
vec3 getColor(float amount) {
  vec3 color = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.1, 0.2) + amount * vec3(1.0, 1.0, 1.0)));
  return color * amount;
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
  vec3 lightPosition = cameraPos;// vec3(-10.0, 10.0, 10.0);

  vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
  vec3 cameraUp = cross(cameraRight, cameraFront);
  vec3 ro = cameraPos;
  vec3 rd = normalize(uv.x * cameraRight + uv.y * cameraUp + cameraFront);

  float d = raymarch(ro, rd);
  vec3 p = ro + rd * d;

  vec3 color = vec3(0.0);

  if(d<MAX_DIST) {
    vec3 normal = getNormal(p);
    vec3 lightDirection = normalize(lightPosition - p);

    float diffuse = max(dot(normal, lightDirection), 0.0);
    float shadows = softShadows(p, lightDirection, 0.1, 5.0, 64.0);
    color =  vec3(1.0) * diffuse * shadows;//vec3(1.0, 1.0, 1.0) * getColor(diffuse * shadows) * 1.2f;
  }

  gl_FragColor = vec4(color, 1.0);
}
