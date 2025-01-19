#include <iostream>
#include "Window.h"

#include <fstream>
#include <string>
#include <sstream>

#include "Renderer.h"
#include "VertexBuffer.h"
#include "IndexBuffer.h"
#include "VertexBufferLayout.h"
#include "VertexArray.h"
#include "Shader.h"
#include "Renderer.h"

#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>

#include "Clock.h"
#include "Camera.h"
#include "GUI.h"

int main()
{
    Camera camera(glm::vec3(0.0f, 0.0f, 5.0f), 7.5);
    
    Window window;
    glfwSetWindowUserPointer(window.GetGLFWwindow(), &camera);

    GUI imgui;
    imgui.Init(window.GetGLFWwindow());

    float positions[]
    {
        1.0f, 1.0f,
        1.0f, -1.0f,
        -1.0f, -1.0f,
        -1.0f, 1.0f
    };

    unsigned int indices[]
    {
        0, 1, 2,
        2, 3, 0
    };
    VertexArray va;

    VertexBuffer vb(positions, 4 * 2 * sizeof(float));

    VertexBufferLayout layout;

    layout.Push<float>(2);

    va.AddBuffer(vb, layout);

    IndexBuffer ib(indices, 6);

    Shader shader("res/shaders/Fun.shader");
    Shader infinite("res/shaders/InfiniteSpace.shader");
    Shader mandelbulb("res/shaders/Mandelbulb.shader");
    Shader mandelbulbOrbitTrap("res/shaders/MandelbulbOrbitTrap.shader");
    Shader blob("res/shaders/3_Blending_Blobs.shader");
    Shader sphere("res/shaders/Sphere.shader");
    Shader min("res/shaders/Min_Demo.shader");
    Shader max("res/shaders/Max_Demo.shader");
    Shader planeNoise("res/shaders/Plane_Noise.shader");
    Shader core("res/shaders/Core.shader");
    Shader menger("res/shaders/Menger.shader");
    Shader richardmattka("res/shaders/richardmattka.shader");
    Shader cloud("res/shaders/cloud.shader");
    Shader sandbox("res/shaders/glslsandbox.shader");
    Shader sierpinski("res/shaders/Sierpinski.shader");
    Shader box("res/shaders/box.shader");
    Shader torus("res/shaders/torus.shader");
    Shader vCloud("res/shaders/volumetric_cloud.shader");
    Shader mountains("res/shaders/mountains.shader");
    Shader voltest("res/shaders/volumetric_mandelbulb.shader");
    Shader voxeltrace("res/shaders/voxeltrace.shader");
    Shader simesgreen("res/shaders/simesgreen.shader");
    Shader voxelizedbox("res/shaders/voxelizedbox.shader");
    Shader realtime("res/shaders/realtime.shader");
    
    Shader shaders[23]{realtime,voxelizedbox,simesgreen,voxeltrace,voltest,mountains,vCloud,torus,box,sierpinski,sandbox,richardmattka,menger ,shader, infinite, blob, sphere, min, max, mandelbulb, mandelbulbOrbitTrap,planeNoise, core };
    
    shaders[imgui.selectedShaderIndex].Bind();

    va.UnBind();
    vb.Unbind();
    ib.Unbind();
    
    shaders[imgui.selectedShaderIndex].SetTexture(shader.LoadTexture("C:/dev/RAYENGINE/RAYENGINE/noise2.png"));
    shaders[imgui.selectedShaderIndex].Unbind();
    
    Renderer renderer;
    int frame = 0;
    // Game loop
    while (!glfwWindowShouldClose(window.GetGLFWwindow()))
    {
        renderer.Clear();
        
        glfwPollEvents();

        Clock::Tick();

        camera.processInput(window.GetGLFWwindow());

        imgui.StartContext();
         
        // Render
        shaders[imgui.selectedShaderIndex].Bind();

        shaders[imgui.selectedShaderIndex].SetUniform1i("uFrame", 0);
        frame++;
        shaders[imgui.selectedShaderIndex].SetUniform4f("u_Color", 1.0, 0.0, 0.0, 1.0);
        shaders[imgui.selectedShaderIndex].SetUniform2f("uResolution", window.GetWidth(), window.GetHeight());
        shaders[imgui.selectedShaderIndex].SetUniformf("uTime", (float)glfwGetTime());
        shaders[imgui.selectedShaderIndex].SetUniform3f("cameraPos", camera.position.x, camera.position.y, camera.position.z);
        shaders[imgui.selectedShaderIndex].SetUniform3f("cameraFront", camera.front.x, camera.front.y, camera.front.z);
        shaders[imgui.selectedShaderIndex].SetUniform1f("radius",imgui.sphereRadius);

        shaders[imgui.selectedShaderIndex].SetUniformf("resolution", imgui.selectedResolution);

        renderer.Draw(va, ib, shaders[imgui.selectedShaderIndex]);

        imgui.Render();
        
        glfwSwapBuffers(window.GetGLFWwindow());
    }

    imgui.Shutdown();

    glfwTerminate();
    return 0;
}
