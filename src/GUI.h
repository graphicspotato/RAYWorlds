#pragma once
#include "GLFW/glfw3.h"
#include "imgui.h"
#include "imgui_impl_glfw.h"
#include "imgui_impl_opengl3.h"
#include "Shader.h"

class GUI {
public:
	//bool show_demo_window = true;
	//bool show_another_window = false;
	ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);
	int selectedShaderIndex = 0;
	int selectedResolution = 0;
	float sphereRadius= 0.0f;

	GUI();
	~GUI();

	ImGuiIO& returnIO();
	void StartNewFrame();
	void DefineMenu();
	void Init(GLFWwindow* window);
	void Render();
	void Shutdown();
	void StartContext();

};