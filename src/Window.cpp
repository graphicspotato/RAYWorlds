#include "Window.h"
#include "Camera.h"

// Key callback function
void key_callback(GLFWwindow* window, int key, int scancode, int action, int mode)
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GL_TRUE);
}

// Mouse callback function
void mouse_callback(GLFWwindow* window, double xposIn, double yposIn)
{
    Camera* camera = static_cast<Camera*>(glfwGetWindowUserPointer(window));

    if (camera)
    {
        float xpos = static_cast<float>(xposIn);
        float ypos = static_cast<float>(yposIn);

        if (camera->firstMouse)
        {
            camera->lastMouseX = xpos;
            camera->lastMouseY = ypos;
            camera->firstMouse = false;
        }

        float xoffset = xpos - camera->lastMouseX;
        float yoffset = camera->lastMouseY - ypos; // reversed since y-coordinates go from bottom to top

        camera->lastMouseX = xpos;
        camera->lastMouseY = ypos;

        camera->processMouseMovement(xoffset, yoffset);
    }
}


Window::Window()
{

    std::cout << "Starting GLFW context, OpenGL 3.3" << std::endl;

    // Init GLFW
    if (!glfwInit()) {
        std::cerr << "Failed to initialize GLFW" << std::endl;
        return;
    }

    // Set all the required options for GLFW
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
    glfwWindowHint(GLFW_RESIZABLE, GL_FALSE);

    // Create a GLFWwindow object that we can use for GLFW's functions
    window = glfwCreateWindow(WIDTH, HEIGHT, "LearnOpenGL", NULL, NULL);
    if (window == NULL)
    {
        std::cerr << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return;
    }

    glfwMakeContextCurrent(window);

    // Set the required callback functions
    glfwSetKeyCallback(window, key_callback);
    glfwSetCursorPosCallback(window, mouse_callback);
    glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR);

    glfwSwapInterval(1);

    // Load OpenGL functions, gladLoadGL returns the loaded version, 0 on error.
    int version = gladLoadGL(glfwGetProcAddress);
    if (version == 0)
    {
        std::cerr << "Failed to initialize OpenGL context" << std::endl;
        return;
    }

    // Successfully loaded OpenGL
    std::cout << "Loaded OpenGL " << GLAD_VERSION_MAJOR(version) << "." << GLAD_VERSION_MINOR(version) << std::endl;

    // Define the viewport dimensions
    glViewport(0, 0, WIDTH, HEIGHT);
}

Window::~Window()
{
    // Destroy the window and terminate GLFW when the object is destructed
    if (window)
    {
        glfwDestroyWindow(window);
    }
    glfwTerminate();
}
