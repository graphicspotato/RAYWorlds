#pragma once
#include <iostream>
#include "glad/gl.h"
#include "GLFW/glfw3.h"


class Window {
public:
	Window();
	~Window();
	
	GLFWwindow* GetGLFWwindow() const { return window; }
	
	GLuint GetWidth()
	{
		return WIDTH;
	}
	GLuint GetHeight()
	{
		return HEIGHT;
	}

private:
	GLFWwindow* window;
	const GLuint WIDTH = 1920, HEIGHT = 1080;

};
