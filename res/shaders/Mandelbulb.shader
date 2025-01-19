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

out vec4 FragColor;

// Constants
#define MARCH_STEPS 128
#define ITERATIONS 32
#define OUTRANGE 2.0

// Rotation matrix in 2D
mat2 rot(float a) {
    return mat2(cos(a), -sin(a),
                sin(a),  cos(a));
}

// Signed Distance Function for the fractal
float SDF(vec3 p, out float trap) {
    p.xz *= rot(-0.5 + uTime * 0.08);
    p.yz *= rot(-0.5 + uTime * 0.07);
    
    vec3 z = p;
    float n = 8.0;
    float r = 0.0;
    float dr = 1.0;
    
    trap = dot(z, z);
    
    for (int i = 0; i < ITERATIONS; i++) {
        r = length(z);
        if (r >= OUTRANGE) break;

        trap = min(dot(z, z), trap);
        dr = n * pow(r, n - 1.0) * dr + 1.0;
        
        float theta = atan(z.y, z.x);
        float phi = asin(z.z / r);

        r = pow(r, n);
        theta *= n;
        phi *= n;
        
        z = r * vec3(cos(theta) * cos(phi), 
                     sin(theta) * cos(phi), 
                     sin(phi)) + p;
    }
    
    return 0.5 * log(r) * r / dr;
}

// Ray marching function
float raymarch(vec3 ro, vec3 rd, out float i, out float trap) {
    vec3 p = ro;

    // Check for bounding sphere
    vec3 cl = p + rd * abs(dot(p, rd));
    if (dot(cl, cl) >= 1.3) {
        return -1.0;
    }
    
    float t = 0.0;
    for (i = 0.0; i < MARCH_STEPS; ++i) {
        float d = SDF(p, trap);
        float eps = 0.0001 + 0.0001 * t;
        if (d < eps) {
            return d;
        }
        t += d;
        p += rd * d;
    }
    
    return -1.0;
}

// Coloring function based on trap value
vec3 coloring(float trap) {
    trap = clamp(pow(trap, 8.0), 0.0, 1.0);
    return mix(vec3(1.0, 0.81, 0.64), vec3(0.8, 0.4, 0.1), trap);
}

// Main function for rendering
void main() {
    vec2 uv = gl_FragCoord.xy / uResolution.xy;
    uv -= 0.5;
    uv.x *= uResolution.x / uResolution.y;
    
    float zoom = smoothstep(0.0, 1.0, pow(sin(uTime * 0.12), 2.0));
    vec3 ro = cameraPos;//vec3(0.0, 0.0, -2.5) + vec3(0.0, 0.0, 1.0) * zoom * 1.3;
    
  vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
  vec3 cameraUp = cross(cameraRight, cameraFront);

  // Compute the ray direction based on camera orientation
  vec3 rd = normalize(uv.x * cameraRight + uv.y * cameraUp + cameraFront);
  //vec3 rd = normalize(vec3(uv, 1.0));
    
    vec3 col = vec3(0.0);
    
    float i;
    float trap;
    float d = raymarch(ro, rd, i, trap);
    
    if (d > 0.0) {
        col = vec3(1.0) * pow(1.0 - i / MARCH_STEPS, 4.0);
        col *= coloring(trap);
    }
    
    FragColor = vec4(col, 1.0);
}
