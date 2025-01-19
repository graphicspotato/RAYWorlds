#include "GUI.h"

GUI::GUI()
{
}

GUI::~GUI()
{
}
void GUI::Init(GLFWwindow* window)
{
    // Set up ImGui context
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();

    // Set ImGui style
    ImGui::StyleColorsDark();

    // Initialize ImGui for GLFW and OpenGL
    ImGui_ImplGlfw_InitForOpenGL(window, true);
    ImGui_ImplOpenGL3_Init("#version 330");
}

void GUI::StartNewFrame()
{
    // Start the ImGui frame
    ImGui_ImplOpenGL3_NewFrame();
    ImGui_ImplGlfw_NewFrame();
    ImGui::NewFrame();
}

ImGuiIO& GUI::returnIO()
{
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    return io;
}

void GUI::DefineMenu()
{
    ImGuiIO& io = returnIO();
    {
        static float f = 0.0f;
        static int counter = 0;
        static int selectedResolutionIndex = 0; // Index for resolution

        ImGui::Begin("Hello, world!"); // Create a window called "Hello, world!" and append into it.

        ImGui::Text("This is some useful text."); // Display some text (you can use a format strings too)

        ImGui::SliderFloat("float", &f, 0.0f, 1.0f); // Edit 1 float using a slider from 0.0f to 1.0f

        ImGui::Begin("Shader Selector"); // Begin the "Shader Selector" window


        const char* shaderNames[] = { "realtime","voxelized box","simesgreen","voxeltrace","voltest","Mountains","Volumetric Cloud","Torus","Box","Sierpinski","Sandbox","Richard Mattka","Menger", "Sphere-DiffuseLighting", "Shader 2", "3 Blending Blobs", "Sphere", "Min Demo", "Max Demo", "Mandelbulb", "Mandelbulb Orbit Trap","Noise Plane", "Core"};
        ImGui::Combo("Select Shader", &selectedShaderIndex, shaderNames, IM_ARRAYSIZE(shaderNames));
        
        // Define resolution options
        const int resolutionOptions[] = { 1, 4, 8, 16, 32 };
        const char* resolutionLabels[] = { "1", "4", "8", "16", "32" };

        ImGui::Combo("Resolution", &selectedResolutionIndex, resolutionLabels, IM_ARRAYSIZE(resolutionLabels));

        // Use selectedResolutionIndex to get the actual resolution value
        selectedResolution = resolutionOptions[selectedResolutionIndex];
        ImGui::Text("Selected Resolution: %d", selectedResolution);


        ImGui::SliderFloat("radius", &sphereRadius, 0.0f, 100.0f);


        if (ImGui::Button("Button")) // Buttons return true when clicked (most widgets return true when edited/activated)
            counter++;
        ImGui::SameLine();
        ImGui::Text("counter = %d", counter);

        ImGui::Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0f / io.Framerate, io.Framerate);

        ImGui::End(); // End the "Shader Selector" window

        ImGui::End(); // End the "Hello, world!" window
    }
}
void GUI::StartContext()
{
    GUI::StartNewFrame();
    GUI::DefineMenu();
}

void GUI::Render()
{
    ImGui::Render();

    ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
}

void GUI::Shutdown()
{
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplGlfw_Shutdown();
    ImGui::DestroyContext();
}