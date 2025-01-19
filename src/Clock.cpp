#pragma once
#include "Clock.h"

float Clock::deltaTime = 0.0f;
float Clock::lastFrame = 0.0f;

//Updates deltaTime and lastFrame.
void Clock::Tick()
{
	// Update deltaTime and lastFrame
	float currentFrame = glfwGetTime();
	deltaTime = currentFrame - lastFrame;
	lastFrame = currentFrame;
}