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

// voxels!
// @simesgreen

float box( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float sphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdCone( vec3 p, vec2 c )
{
    // c must be normalized
    float q = length(p.xz);
    return dot(c, vec2(q, p.y));
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdPlane(vec3 p)
{
    return p.y + 1.0f;
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}
// distance to scene
float scene(vec3 p)
{	
    float d = sphere(p * 2.0 - vec3(0.0, -.5, 0.0), sin(uTime)*0.5+1);
    //float d1 = plane(p, vec3(0.0, 1.0, 0.0), vec3(0.0,-1.0,0.0));
    float d1 = sdPlane(p);
    d = smin(d, d1, 1.0);
    return d;
}

// calculate scene normal
vec3 sceneNormal(vec3 pos )
{
    float eps = 0.0001;
    vec3 n;
#if 0
    n.x = scene( vec3(pos.x+eps, pos.y, pos.z) ) - scene( vec3(pos.x-eps, pos.y, pos.z) );
    n.y = scene( vec3(pos.x, pos.y+eps, pos.z) ) - scene( vec3(pos.x, pos.y-eps, pos.z) );
    n.z = scene( vec3(pos.x, pos.y, pos.z+eps) ) - scene( vec3(pos.x, pos.y, pos.z-eps) );
#else
    float d = scene(pos);
    n.x = scene( vec3(pos.x+eps, pos.y, pos.z) ) - d;
    n.y = scene( vec3(pos.x, pos.y+eps, pos.z) ) - d;
    n.z = scene( vec3(pos.x, pos.y, pos.z+eps) ) - d;
#endif
    return normalize(n);
}

// ambient occlusion approximation
float ambientOcclusion(vec3 p, vec3 n)
{
    const int steps = 3;
    const float delta = 0.5;

    float a = 0.0;
    float weight = 1.0;
    for(int i=1; i<=steps; i++) {
        float d = (float(i) / float(steps)) * delta; 
        a += weight*(d - scene(p + n*d));
        weight *= 0.5;
    }
    return clamp(1.0 - a, 0.0, 1.0);
}

// lighting
vec3 shade(vec3 pos, vec3 n, vec3 eyePos)
{
    const vec3 lightPos = vec3(4.0, 3.0, 5.0);
    const vec3 color = vec3(1.0, 0.7, 0.5);
    const float shininess = 40.0;

    vec3 l = normalize(lightPos - pos);
    vec3 v = normalize(eyePos - pos);
    vec3 h = normalize(v + l);

    float diff = clamp( dot( n, l), 0.0, 1.0 );//dot(n, l);
    float spec = max(0.0, pow(dot(n, h), shininess)) * float(diff > 0.0);
    diff = max(0.0, diff);
    //diff = 0.5+0.5*diff;

    float fresnel = pow(1.0 - dot(n, v), 5.0);
    float ao = ambientOcclusion(pos, n);

    return vec3(diff*ao)*color;	
}

// Amanatides & Woo style voxel traversal
const vec3 voxelSize = vec3(0.05); // in world space
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
    const int maxSteps =258;
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

    return voxelToWorld(hitVoxel);
	//return ro + hitT*rd;

}


vec3 background(vec3 rd)
{
     //return mix(vec3(1.0), vec3(0.0), rd.y);
     return mix(vec3(1.0, 1.0, 1.0), vec3(0.0, 0.5, 1.0), abs(rd.y));
     //return vec3(0.0);
}

void main()
{
    //vec2 pixel = (gl_FragColor.xy / uResolution.xy)*2.0-1.0;
    vec2 uv = gl_FragCoord.xy/uResolution.xy;
    uv -= 0.5;
    uv.x *= uResolution.x / uResolution.y;

    // Ray Origin - camera
    vec3 ro = cameraPos;

    vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
    vec3 cameraUp = cross(cameraRight, cameraFront);
    vec3 rd = normalize(uv.x * cameraRight + uv.y * cameraUp + cameraFront);
    

		

	vec2 a = vec2(0.0, 0.0);

    bool hit;
    vec3 n;
    vec3 pos = voxelTrace(ro, rd, hit, n);
    ro += rd + pos;

    vec3 rgb;
    if(hit)
    {
        // calc normal
        vec3 n = sceneNormal(pos);
	    
        // shade
        rgb = shade(pos, n, ro);

        if(pos.y < -0.8)
        {
            rgb = mix(vec3(1.0), vec3(1.0, 0.7, 0.5), rgb);
        }

#if 0
        // reflection
        vec3 v = normalize(ro - pos);
        float fresnel = 0.1 + 0.9*pow(1.0 - dot(n, v), 5.0);

        ro = pos + n*0.2; // offset to avoid self-intersection
        rd = reflect(-v, n);
		pos = voxelTrace(ro, rd, hit, n);
	    
        if (hit) {
            vec3 n = sceneNormal(pos);
            rgb += shade(pos, n, ro) * vec3(fresnel);
        } else {
            rgb += background(rd) * vec3(fresnel);
        }
#endif 

     } else {
        rgb = background(rd);
     }

    // vignetting
    //rgb *= 0.5+0.5*smoothstep(2.0, 0.5, dot(pixel, pixel));

    gl_FragColor=vec4(rgb, 1.0);
}