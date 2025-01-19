#shader vertex
#version 330 core

layout (location = 0) in vec4 position;

void main() {
    gl_Position = position;
}

#shader fragment
#version 330 core

uniform vec3 cameraPos;
uniform vec3 cameraFront;
uniform float uTime;
uniform vec2 uResolution;
uniform sampler2D uTexture;

#define MAX_STEPS 100
#define MAX_DIST 250.0
#define SURFACE_DIST 0.001
#define MAX_OCTAVES 6

// Noise function for terrain generation
vec3 noised(vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = textureLod(uTexture, (p + vec2(0.0, 0.0)) / 256.0, 0.0).x;
    float b = textureLod(uTexture, (p + vec2(1.0, 0.0)) / 256.0, 0.0).x;
    float c = textureLod(uTexture, (p + vec2(0.0, 1.0)) / 256.0, 0.0).x;
    float d = textureLod(uTexture, (p + vec2(1.0, 1.0)) / 256.0, 0.0).x;

    float noiseValue = a + (b - a) * u.x + (c - a) * u.y + (a - b - c + d) * u.x * u.y;
    vec2 noiseDerivative = 6.0 * f * (1.0 - f) * (vec2(b - a, c - a) + (a - b - c + d) * u.yx);

    return vec3(noiseValue, noiseDerivative);
}

// Terrain height function
float terrain(vec2 p) {
    vec2 p1 = p * 0.06;
    float height = 0.0;
    float amplitude = 2.5;
    vec2 derivatives = vec2(0.0);
    float scale = 2.75;

    for (int i = 0; i < MAX_OCTAVES; i++) {
        vec3 n = noised(p1);
        derivatives += n.yz;
        height += amplitude * n.x / (dot(derivatives, derivatives) + 1.0);
        amplitude *= -0.4;
        height *= 0.85;
        p1 = mat2(0.8, -0.6, 0.6, 0.8) * p1 * scale;
    }
    return height * 3.0;
}

// Scene distance field
float scene(vec3 p) {
    return p.y - 8 *terrain(p.xz);
}

// Raymarching
float raymarch(vec3 ro, vec3 rd) {
    float dO = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * dO;
        float dS = scene(p);
        dO += dS;
        if (dS < SURFACE_DIST || dO > MAX_DIST) break;
    }
    return dO;
}

// Fog blending
vec3 fog(vec3 color, vec3 fogColor, float distance) {
    float fogDensity = 0.02;
    float fogFactor = 1.0 - exp(-distance * fogDensity);
    return mix(color, fogColor, fogFactor);
}

// Get normal vector for lighting
vec3 getNormal(vec3 p) {
    vec2 e = vec2(0.01, 0.0);
    vec3 n = scene(p) - vec3(
        scene(p - e.xyy),
        scene(p - e.yxy),
        scene(p - e.yyx)
    );
    return normalize(n);
}

void main() {
    vec2 uv = (gl_FragCoord.xy / uResolution) * 2.0 - 1.0;
    uv.x *= uResolution.x / uResolution.y;

    vec3 ro = cameraPos;
    vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
    vec3 cameraUp = cross(cameraRight, cameraFront);
    vec3 rd = normalize(uv.x * cameraRight + uv.y * cameraUp + cameraFront);

    vec3 fogColor = vec3(0.678,0.91,0.957); // Light blue fog
    vec3 backgroundColor = vec3(0.2, 0.4, 0.6); // Sky-like background

    float d = raymarch(ro, rd);
    vec3 p = ro + rd * d;
    vec3 color;

    if (d < MAX_DIST) {
        vec3 normal = getNormal(p);
        float diffuse = max(dot(normal, normalize(vec3(-50.0, 20.0, 50.0) - p)), 0.0);
        color = vec3(0.8, 0.6, 0.4) * diffuse; // Base terrain color

        // Apply texture based on height
        float heightFactor = clamp(p.y / 10.0, 0.0, 1.0);
        vec3 textureColor = mix(vec3(0.3, 0.2, 0.1), vec3(0.6, 0.5, 0.4), heightFactor);
        color *= textureColor;

        // Apply fog
        color = fog(color, fogColor, d);
    } else {
        color = fog(backgroundColor, fogColor, d);
    }

    gl_FragColor = vec4(color, 1.0);
}
