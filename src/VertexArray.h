#pragma once
#include "VertexBufferLayout.h"
#include "VertexBuffer.h"
class VertexArray
{
private:
	unsigned int m_RendererId;
public:
	VertexArray();
	~VertexArray();
	void Bind() const;
	void UnBind() const;
	void AddBuffer(const VertexBuffer& vb, const VertexBufferLayout& layout);
};