// #shader vertex
//         #version 330 core 
        
//         layout (location = 0) in vec4 position;
        
//         void main()
//         {
//          gl_Position = position;
//         };

// #shader fragment
// #version 330 core

// uniform float uTime;
// uniform vec2 uResolution;
// uniform vec3 cameraPos;
// uniform vec3 cameraFront;

// out vec4 fragColor; // Custom output for fragment color

// #define ITERATIONS 32
// #define OUTRANGE 2.0

// // Rotation matrix in 2D
// mat2 rot(float a) {
//     return mat2(cos(a), -sin(a),
//                 sin(a),  cos(a));
// }

// // Signed Distance Function for the fractal
// float SDF(vec3 p, out float trap) {
//     p.xz *= rot(-0.5 + uTime * 0.08);
//     p.yz *= rot(-0.5 + uTime * 0.07);
    
//     vec3 z = p;
//     float n = 8.0;
//     float r = 0.0;
//     float dr = 1.0;
    
//     trap = dot(z, z);
    
//     for (int i = 0; i < ITERATIONS; i++) {
//         r = length(z);
//         if (r >= OUTRANGE) break;

//         trap = min(dot(z, z), trap);
//         dr = n * pow(r, n - 1.0) * dr + 1.0;
        
//         float theta = atan(z.y, z.x);
//         float phi = asin(z.z / r);

//         r = pow(r, n);
//         theta *= n;
//         phi *= n;
        
//         z = r * vec3(cos(theta) * cos(phi), 
//                      sin(theta) * cos(phi), 
//                      sin(phi)) + p;
//     }
    
//     return 0.5 * log(r) * r / dr;
// }

// // Ray marching function
// float raymarch(vec3 ro, vec3 rd, out float i, out float trap) {
//     vec3 p = ro;

//     // Check for bounding sphere
//     vec3 cl = p + rd * abs(dot(p, rd));
//     if (dot(cl, cl) >= 1.3) {
//         return -1.0;
//     }
    
//     float t = 0.0;
//     for (i = 0.0; i < MARCH_STEPS; ++i) {
//         float d = SDF(p, trap);
//         float eps = 0.0001 + 0.0001 * t;
//         if (d < eps) {
//             return d;
//         }
//         t += d;
//         p += rd * d;
//     }
    
//     return -1.0;
// }

// // Coloring function based on trap value
// vec3 coloring(float trap) {
//     trap = clamp(pow(trap, 8.0), 0.0, 1.0);
//     return mix(vec3(1.0, 0.81, 0.64), vec3(0.8, 0.4, 0.1), trap);
// }

// float scene(vec3 p, inout float orbitTrap) {
//     float scale = 2.5f;
//     vec3 p1 = p / scale;
//     return DE(p1, orbitTrap);
// }

// float raymarch(vec3 ro, vec3 rd, out float orbitTrap) {
//     float dO = 0.0;
//     orbitTrap = 1e10; // Initialize orbit trap
    
//     for (int i = 0; i < MAX_STEPS; i++) {
//         vec3 p = ro + rd * dO;
//         float dS = scene(p, orbitTrap);

//         dO += dS;

//         if (dO > MAX_DIST || dS < SURFACE_DIST) {
//             break;
//         }
//     }
//     return dO;
// }

// // Orbit Trap-based Coloring
// vec3 getColor(float orbitTrap) {
//     float intensity = clamp(1.0 - orbitTrap / ORBIT_TRAP_RADIUS, 0.0, 1.0);
//     return vec3(intensity, intensity * 0.5, 1.0 - intensity);
// }

// vec3 getNormal(vec3 p) {
//     vec2 e = vec2(.01, 0);

//     vec3 n = vec3(
//         scene(p + e.xyy, e.x),
//         scene(p + e.yxy, e.y),
//         scene(p + e.yyx, e.y)) - scene(p, e.x);
        
//     return normalize(n);
// }

// void main() {
//     vec2 uv = gl_FragCoord.xy / uResolution.xy;
//     uv -= 0.5;
//     uv.x *= uResolution.x / uResolution.y;

//     // Camera Setup
//     vec3 cameraRight = normalize(cross(cameraFront, vec3(0.0, 1.0, 0.0)));
//     vec3 cameraUp = cross(cameraRight, cameraFront);

//     vec3 ro = cameraPos;
//     vec3 rd = normalize(uv.x * cameraRight + uv.y * cameraUp + cameraFront);

//     // Raymarching
//     float orbitTrap;
//     float d = raymarch(ro, rd, orbitTrap);
//     vec3 color = vec3(0.0);

//     if (d < MAX_DIST) {
//         color = getColor(orbitTrap);
//     }

//     fragColor = vec4(color, 1.0); // Use custom output variable
// }
