#include "Shader.h"
#include <fstream>
#include <string>
#include <sstream>
#include <iostream>
#include <glad/gl.h>

#include "Renderer.h"
#include "glm/glm.hpp"



Shader::Shader(const std::string& filepath)
	:m_FilePath(filepath), m_RendererId(0)
{
    ShaderProgramSource source = ParseShader(filepath);

    m_RendererId = CreateShader(source.VertexSource, source.FragmentSource);
}

Shader::~Shader()
{
    GLCall(glDeleteProgram(m_RendererId));
}


unsigned int Shader::LoadTexture(const std::string& filepath)
{
    unsigned int texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    int width, height, nrChannels;
    unsigned char* data = stbi_load("C:/dev/RAYENGINE/RAYENGINE/noise2.png", &width, &height, &nrChannels, 0);
    if (data)
    {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
        glGenerateMipmap(GL_TEXTURE_2D);
    }
    else
    {
        std::cout << "Failed to load texture" << std::endl;
    }
    stbi_image_free(data);
    return texture;
}

void Shader::SetTexture(unsigned int texture)
{
    // Bind the texture to a texture unit
    glActiveTexture(GL_TEXTURE0); // Activate texture unit 0
    glBindTexture(GL_TEXTURE_2D, texture); // Bind the texture object to this unit

}

unsigned int Shader::CreateShader(const std::string& vertexShader, const std::string& fragmentShader)
{
    unsigned int program = glCreateProgram();
    unsigned int vs = CompileShader(GL_VERTEX_SHADER, vertexShader);
    unsigned int fs = CompileShader(GL_FRAGMENT_SHADER, fragmentShader);

    GLCall(glAttachShader(program, vs));
    GLCall(glAttachShader(program, fs));
    GLCall(glLinkProgram(program));
    GLCall(glValidateProgram(program));

    glDeleteShader(vs);
    glDeleteShader(fs);

    return program;
}

unsigned int Shader::CompileShader(unsigned int type, const std::string& source)
{
    unsigned int id = glCreateShader(type);
    const char* src = source.c_str();
    glShaderSource(id, 1, &src, nullptr);
    glCompileShader(id);

    int result;
    glGetShaderiv(id, GL_COMPILE_STATUS, &result);

    if (result == GL_FALSE)
    {
        int length;
        glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
        char* message = (char*)alloca(length * sizeof(char));
        glGetShaderInfoLog(id, length, &length, message);
        std::cout << "Failed to compile " << (type == GL_VERTEX_SHADER ? "vertex" : "fragment") << " shader!" << std::endl;
        std::cout << message << std::endl;
        glDeleteShader(id);
        return 0;

    }
    return id;
}



ShaderProgramSource Shader::ParseShader(const std::string& filepath)
{
    std::fstream stream(filepath);

    enum class ShaderType {
        NONE = -1, VERTEX = 0, FRAGMENT = 1
    };

    ShaderType shaderType = ShaderType::NONE;
    std::string line;
    std::stringstream ss[2];
    while (getline(stream, line))
    {
        if (line.find("#shader") != std::string::npos)
        {
            if (line.find("vertex") != std::string::npos)
            {
                shaderType = ShaderType::VERTEX;
            }
            else if (line.find("fragment") != std::string::npos)
            {
                shaderType = ShaderType::FRAGMENT;
            }
        }
        else
        {
            ss[(int)shaderType] << line << '\n';
        }
    }
    return { ss[0].str(), ss[1].str() };
}


void Shader::Bind() const
{
    GLCall(glUseProgram(m_RendererId));
}

void Shader::Unbind() const
{
    GLCall(glUseProgram(0));
}

void Shader::SetUniform4f(const std::string& name, float v0, float v1, float v2, float v3)
{
    GLCall(glUniform4f(GetUniformLocation(name), v0, v1, v2, v3));
}
void Shader::SetUniform2f(const std::string& name, float v0, float v1)
{
    GLCall(glUniform2f(GetUniformLocation(name), v0, v1));
}
void Shader::SetUniform2v(const std::string& name, const glm::vec2& vec) {
    GLCall(glUniform2fv(GetUniformLocation(name), 1, &vec[0]));
}
void Shader::SetUniformf(const std::string& name, float v0) 
{
    GLCall(glUniform1f(GetUniformLocation(name), v0));
}
void Shader::SetUniform1i(const std::string& name, int v0)
{
    GLCall(glUniform1i(GetUniformLocation(name), v0));
}
void Shader::setUniformMat4(const std::string& name, const glm::mat4& matrix) 
{
    GLCall(glUniformMatrix4fv(GetUniformLocation(name), 1, GL_FALSE, &matrix[0][0]));
}
void Shader::SetUniform3f(const std::string& name, float v0, float v1, float v2) 
{
    GLCall(glUniform3f(GetUniformLocation(name), v0, v1, v2));
}
void Shader::SetUniform1f(const std::string& name, float v0) 
{
    GLCall(glUniform1f(GetUniformLocation(name), v0));
}

unsigned int Shader::GetUniformLocation(const std::string& name)
{
    if (m_UniformLocationCache.find(name) != m_UniformLocationCache.end())
        return m_UniformLocationCache[name];
    GLCall(unsigned int location = glGetUniformLocation(m_RendererId, name.c_str()));
    return location;
}
