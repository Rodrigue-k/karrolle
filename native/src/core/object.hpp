#pragma once
#include <string>
#include <cstdint>
#include <algorithm>

class SceneObject {
public:
    int id;
    std::string name;
    float x, y, w, h;
    
    virtual ~SceneObject() = default;

    SceneObject(int id, std::string name, float x, float y, float w, float h) 
        : id(id), name(std::move(name)), x(x), y(y), w(w), h(h) {}

    virtual void draw(uint32_t* buffer, int bufW, int bufH) = 0;

    // Type identifiers: 0=rect, 1=text, 2=image, 3=ellipse, 4=line
    virtual int getType() { return 0; }

    virtual bool contains(int px, int py) {
        return (px >= (int)x && px < (int)(x + w) && py >= (int)y && py < (int)(y + h));
    }

    virtual void move(float dx, float dy) {
        x += dx;
        y += dy;
    }
    
    virtual void setRect(float nx, float ny, float nw, float nh) {
        x = nx; y = ny; w = nw; h = nh;
    }
    
    virtual void setColor(uint32_t /*c*/) {}
    virtual uint32_t getColor() { return 0xFFFFFFFF; }
    
    virtual void setText(const std::string& /*t*/) {}
    virtual std::string getText() { return ""; }
    
    virtual void setFontSize(float /*s*/) {}
    virtual float getFontSize() { return 0; }
};

// Alias for backward compatibility
using Object = SceneObject;
