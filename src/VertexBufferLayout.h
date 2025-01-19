#pragma once
#include <GLFW/glfw3.h>
#include <iostream>
#include "vector"

// Define ASSERT locally
#ifndef ASSERT
#define ASSERT(x) if (!(x)) __debugbreak();
#endif
struct VertexBufferElement
{
	unsigned int type;
	unsigned int count;
	unsigned char normalized;

	static unsigned int GetSizeOfType(unsigned int type)
	{
		switch (type)
		{
			case GL_FLOAT:			return 4;
			case GL_UNSIGNED_INT:	return 4;
			case GL_UNSIGNED_BYTE:	return 1;
				ASSERT(false);
				return 0;
		}
	}
};

class VertexBufferLayout
{
private:
	std::vector<VertexBufferElement> m_Elements;
	unsigned int m_Stride;
public:
	VertexBufferLayout()
		: m_Stride(0) {}
	
	template<typename T>
	void Push(unsigned int count)
	{
		std::runtime_error("error");
		//static_assert(false);
	}

	template<>
	void Push<float>(unsigned int count)
	{
		m_Elements.push_back({ static_cast<unsigned int>(GL_FLOAT), static_cast<unsigned int>(count), GL_FALSE });
		m_Stride += count * VertexBufferElement::GetSizeOfType(GL_FLOAT);
	}
	template<>
	void Push<unsigned int>(unsigned int count)
	{
		m_Elements.push_back({ static_cast<unsigned int>(GL_UNSIGNED_INT), static_cast<unsigned int>(count), GL_FALSE });
		m_Stride += count * VertexBufferElement::GetSizeOfType(GL_UNSIGNED_INT) ;
	}
	template<>
	void Push<unsigned char>(unsigned int count)
	{
		m_Elements.push_back({ static_cast<unsigned int>(GL_UNSIGNED_BYTE), static_cast<unsigned int>(count), GL_TRUE });
		m_Stride += count * VertexBufferElement::GetSizeOfType(GL_UNSIGNED_BYTE);
	}
	inline const std::vector<VertexBufferElement> GetElements() const { return m_Elements; }
	inline int GetStride() const { return m_Stride; }
	

	
};