#include "Camera.h"

#include <iostream>



Camera::Camera(glm::vec3 position, float speed)
    :position(position), cameraSpeed(speed)
{

}


Camera::~Camera()
{
}

void Camera::processInput(GLFWwindow* window)
{
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);

    float cameraSpeed = static_cast<float>(7.5f * Clock::getDeltaTime());

    if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS)
    {
        cameraSpeed = static_cast<float>(20.0f * Clock::getDeltaTime());
    }
    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        position += cameraSpeed * front;
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        position -= cameraSpeed * front;
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        position -= glm::normalize(glm::cross(front, up)) * cameraSpeed;
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        position += glm::normalize(glm::cross(front, up)) * cameraSpeed;
    
    if (glfwGetKey(window, GLFW_KEY_E) == GLFW_PRESS)
    {
        glm::vec3 right = glm::normalize(glm::cross(front, up));
        position += glm::normalize(glm::cross(right, front)) * cameraSpeed;
    }
    if (glfwGetKey(window, GLFW_KEY_Q) == GLFW_PRESS)
    {
        glm::vec3 right = glm::normalize(glm::cross(front, up));
        position -= glm::normalize(glm::cross(right, front)) * cameraSpeed;
    }
}
void Camera::updateCameraVectors()
{
    // calculate the new Front vector
    glm::vec3 front;
    front.x = cos(glm::radians(yaw)) * cos(glm::radians(pitch));
    front.y = sin(glm::radians(pitch));
    front.z = sin(glm::radians(yaw)) * cos(glm::radians(pitch));
    this->front = glm::normalize(front);

    // re-calculate the Right and Up vector
    right = glm::normalize(glm::cross(this->front, glm::vec3(0.0f, 1.0f, 0.0f)));  // Normalize the vectors, because their length gets closer to 0 the more you look up or down, resulting in slower movement.
    up = glm::normalize(glm::cross(right, this->front));
}

void Camera::processMouseMovement(float xoffset, float yoffset, GLboolean constrainPitch)
{
    xoffset *= MouseSensitivity;
    yoffset *= MouseSensitivity;

    yaw += xoffset;
    pitch += yoffset;

    // make sure that when pitch is out of bounds, screen doesn't get flipped
    if (constrainPitch)
    {
        if (pitch > 89.0f)
            pitch = 89.0f;
        if (pitch < -89.0f)
            pitch = -89.0f;
    }

    // update Front, Right and Up Vectors using the updated Euler angles
    updateCameraVectors();
}
