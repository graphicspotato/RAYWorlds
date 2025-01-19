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
//uniform vec3 bits;

#define MAX_STEPS 100
#define MAX_DIST 100.0f
#define SURFACE_DIST 0.001f


vec3 repeat(vec3 p) {
    return mod(p, 4.0) - 2.0;
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

float sphere(vec3 p) {
    return length(p) - mix(0.5, 1.5, sin(uTime) * 0.5 + 0.5);
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float scene(vec3 p) {
    vec3 p0 = repeat(p);
    vec3 p1 = rotate(p0, vec3(1.0, 1.0, 1.0), uTime);
    float cube = sdBox(p1, vec3(0.5, 0.5, 0.5));
    float sphereDist = sphere(p0);
    return smin(sphereDist, cube, 0.3);
}

vec3 getNormal(vec3 p) {
    vec2 o = vec2(0.001, 0.0);
    return normalize(vec3(
        scene(p + o.xyy) - scene(p - o.xyy),
        scene(p + o.yxy) - scene(p - o.yxy),
        scene(p + o.yyx) - scene(p - o.yyx)
    ));
}

void main() {
    vec2 bits = floor(gl_FragCoord.xy / 16.0) * 16.0;
    vec2 p = (bits * 2.0 - uResolution) / uResolution.y;

    vec3 camPos = cameraPos;
    vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
    vec3 cameraUp = cross(cameraRight, cameraFront);
    
    vec3 ray = normalize(p.x * cameraRight + p.y * cameraUp + cameraFront);
    vec3 light = normalize(vec3(-1.0, 1.0, 1.0));

    bool hit = false;
    float curDist = 0.0;
    float rayLen = 0.0;
    vec3 rayPos = camPos;

    for (int i = 0; i <= 64; i++) {
        curDist = scene(rayPos);
        rayLen += curDist;
        rayPos = camPos + ray * rayLen;

        if (abs(curDist) < 0.001) {
            hit = true;
            break;
        }
    }

    vec3 color = vec3(0.920, 0.480, 0.921);

    if (hit) {
        vec3 n = getNormal(rayPos);
        float diff = clamp(0.3, 0.8, dot(light, n));
        color = vec3(diff);
    }

    vec3 backgroundColor = vec3(0.920, 0.480, 0.921);
    color = mix(backgroundColor, color, exp(-0.1 * rayLen));

    gl_FragColor = vec4(color, 1.0);
}
