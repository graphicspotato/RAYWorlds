#pragma once
#include <string>
#include "unordered_map"
#include "glm/mat4x4.hpp"
#include "glm/glm.hpp"
#include "stb_image.h"
struct ShaderProgramSource {
	std::string VertexSource;
	std::string FragmentSource;
};

class Shader 
{
private:
	std::string m_FilePath;
	unsigned int m_RendererId;
	std::unordered_map<std::string, unsigned int> m_UniformLocationCache;

public:
	Shader(const std::string& filepath);
	~Shader();

	void Bind() const;
	void Unbind() const;

	void SetUniform4f(const std::string& name, float v0, float v1, float v2, float v3);
	void SetUniform3f(const std::string& name, float v0, float v1, float v2);
	void SetUniform2f(const std::string& name, float v0, float v1);
	void SetUniformf(const std::string& name, float v0);
	void SetUniform2v(const std::string& name, const glm::vec2& vec);
	void SetUniform1i(const std::string& name, int v0);
	void SetUniform1f(const std::string& name, float v0);
	void setUniformMat4(const std::string& name, const glm::mat4& matrix);
	unsigned int LoadTexture(const std::string& filepath);
	void SetTexture(unsigned int texture);

private:
	unsigned int CreateShader(const std::string& vertexShader, const std::string& fragmentShader);
	unsigned int CompileShader(unsigned int type, const std::string& source);
	ShaderProgramSource ParseShader(const std::string& filepath);
	unsigned int GetUniformLocation(const std::string& name);
};