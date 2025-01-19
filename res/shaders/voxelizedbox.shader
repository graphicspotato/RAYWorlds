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
uniform float resolution;

#define MAX_STEPS 100
#define MAX_DIST 200.0f
#define SURFACE_DIST 0.001f

// Perlin 2D Noide Code
vec4 mod289(vec4 x)
{
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x)
{
  return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec2 fade(vec2 t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

// Classic Perlin noise
float cnoise(vec2 P)
{
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod289(Pi); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;

  vec4 i = permute(permute(ix) + iy);

  vec4 gx = fract(i * (1.0 / 41.0)) * 2.0 - 1.0 ;
  vec4 gy = abs(gx) - 0.5 ;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;

  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);

  vec4 norm = taylorInvSqrt(vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;

  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));

  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(
        oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
        oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
        oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
        0.0,                                0.0,                                0.0,                                1.0
    );
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
    mat4 m = rotationMatrix(axis, angle);
    return (m * vec4(v, 1.0)).xyz;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float scene(vec3 p) {
    vec3 p1 = rotate(p, vec3(1.0, 1.0, 1.0), uTime /4.0);
    
    float cube = sdBox(p1, vec3(6.0, 6.0, 6.0));
    float sphere = sdSphere(p1 - vec3(22.0 * cos(uTime / 2.0), 7.0 * sin(uTime), 3.0 * cos(uTime)), 8.5);

    float displacement = cnoise(p.xy + uTime * 0.5) / 10.0;
    cube += displacement;
    sphere += displacement;

    return smin(cube, sphere, 10.0);
}

vec3 getNormal(vec3 p) {
    vec2 o = vec2(0.001, 0.0);
    return normalize(vec3(
        scene(p + o.xyy) - scene(p - o.xyy),
        scene(p + o.yxy) - scene(p - o.yxy),
        scene(p + o.yyx) - scene(p - o.yyx)
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

// Amanatides & Woo style voxel traversal
const vec3 voxelSize = vec3(1.0); // in world space
//const vec3 voxelSize = vec3(0.2);

vec3 worldToVoxel(vec3 i)
{
    return floor(i/voxelSize);
}

vec3 voxelToWorld(vec3 i)
{
    return i*voxelSize;	
}

vec3 voxelTrace(vec3 ro, vec3 rd, out bool hit, out vec3 hitNormal)
{
    const int maxSteps =500;
    const float isoValue = 0.0;

    vec3 voxel = worldToVoxel(ro);
    vec3 step = sign(rd);

    vec3 nearestVoxel = voxel + vec3(rd.x > 0.0, rd.y > 0.0, rd.z > 0.0);
    vec3 tMax = (voxelToWorld(nearestVoxel) - ro) / rd;
    vec3 tDelta = voxelSize / abs(rd);

    vec3 hitVoxel = voxel;
	
    hit = false;
    float hitT = 0.0;
    for(int i=0; i<maxSteps; i++) {
        float d = scene(voxelToWorld(voxel));        
        if (d <= isoValue && !hit) {
            hit = true;
	    	hitVoxel = voxel;
            //break;
        }

        if (tMax.x < tMax.y && tMax.x < tMax.z) { 
            voxel.x += step.x;
            tMax.x += tDelta.x;
			if (!hit) {
				hitNormal = vec3(-step.x, 0.0, 0.0);
				hitT = tMax.x;
			}
        } else if (tMax.y < tMax.z) {
            voxel.y += step.y;
            tMax.y += tDelta.y;
			if (!hit) {
				hitNormal = vec3(0.0, -step.y, 0.0);		
				hitT = tMax.y;
			}
        } else {
            voxel.z += step.z;
            tMax.z += tDelta.z;
			if (!hit) {
				hitNormal = vec3(0.0, 0.0, -step.z);		
				hitT = tMax.z;
			}
        }
     
#if 0
        if ((voxel.x < 0) || (voxel.x >= size.width) ||
            (voxel.y < 0) || (voxel.y >= size.height) ||
            (voxel.z < 0) || (voxel.z >= size.depth)) {
            break;            
        }
#endif	    
    }

    //return voxelToWorld(hitVoxel);
	return ro + hitT*rd;

}

void main() {
    vec2 scale = floor(gl_FragCoord.xy / resolution) * resolution;
    vec2 pixelizated = (scale * 2.0 - uResolution) / uResolution.y;

    vec3 ro = cameraPos;
    vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
    vec3 cameraUp = cross(cameraRight, cameraFront);
    
    vec3 rd = normalize(pixelizated.x * cameraRight + pixelizated.y * cameraUp + cameraFront);
    vec3 light = normalize(vec3(-1.0, 1.0, 1.0));

    float curDist = 0.0;
    float rayLen = 0.0;
    
    bool hit;
    vec3 n;
    vec3 d = voxelTrace(ro, rd, hit, n);
    vec3 p = ro + rd * d;

    vec3 color = vec3(0.920, 0.480, 0.921);
    
    vec3 backgroundColor = vec3(0.920, 0.480, 0.921);
    if (hit) {
        vec3 n = getNormal(p);
        float diff = max(dot(n, light), 0.0);//clamp(0.3, 0.8, dot(light, n));
        float shadows = softShadows(p, light, 0.1, 5.0, 64.0);
        color = vec3(diff*shadows);

        color = mix(backgroundColor, color, exp(-0.01 * rayLen));
    }
    else{

        color = mix(backgroundColor, color, exp(-0.01 * rayLen));
    }



    gl_FragColor = vec4(color, 1.0);
}
