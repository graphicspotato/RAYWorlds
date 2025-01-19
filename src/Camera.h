#pragma once
#include "glm/glm.hpp"
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/type_ptr.hpp>
#include "Clock.h"
#include "GLFW/glfw3.h"

class Camera 
{
private:

	

public:
	Camera(glm::vec3 position, float speed);
	~Camera();
	
	glm::vec3 position;
	glm::vec3 front = glm::vec3(0.0f, 0.0f, -1.0f);;
	glm::vec3 up = glm::vec3(0.0f, 1.0f, 0.0f);
	glm::vec3 right;

	float lastMouseX = 400.f;
	float lastMouseY = 300.f;

	bool firstMouse = true;
	float yaw = -90.0f;	// yaw is initialized to -90.0 degrees since a yaw of 0.0 results in a direction vector pointing to the right so we initially rotate a bit to the left.
	float pitch = 0.0f;
	float fov = 45.0f;
	float MouseSensitivity = 0.2f;

	float cameraSpeed;
	void processInput(GLFWwindow* window);
	void processMouseMovement(float xoffset, float yoffset, GLboolean constrainPitch = true);
	void updateCameraVectors();
};