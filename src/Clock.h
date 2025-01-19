#pragma once
#include "GLFW/glfw3.h"

static class Clock
{
public:
	Clock() = delete;
	~Clock() = delete;
	
	/**
	 * @brief Gets the time elapsed between the current frame and the previous frame.
	 *
	 * @return The time elapsed (delta time) in seconds.
	 */
	static float getDeltaTime()
	{
		return deltaTime;
	}

	/**
	 * @brief Gets the time of the last frame.
	 *
	 * @return The time of the last frame in seconds since the application started.
	 */
	static float getLastFrame()
	{
		return lastFrame;
	}
	
	/**
	 * @brief Updates the delta time and last frame time.
	 *
	 * This function should be called once per frame to update the time elapsed since the last frame.
	 * It uses `glfwGetTime()` to get the current time and calculates the difference from the last frame time.
	 */
	static void Tick();

private:
	static float deltaTime;
	static float lastFrame;
};


