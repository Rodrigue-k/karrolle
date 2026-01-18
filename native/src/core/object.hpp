#pragma once
#include <string>
#include <cstdint>
#include <algorithm>

class Object {
public:
    int id;
    std::string name;
    int x, y, w, h;
    
    virtual ~Object() = default;

    Object(int id, std::string name, int x, int y, int w, int h) 
        : id(id), name(std::move(name)), x(x), y(y), w(w), h(h) {}

    virtual void draw(uint32_t* buffer, int bufW, int bufH) = 0;

    virtual bool contains(int px, int py) {
        return (px >= x && px < x + w && py >= y && py < y + h);
    }

    virtual void move(int dx, int dy) {
        x += dx;
        y += dy;
    }
    
    virtual void setRect(int nx, int ny, int nw, int nh) {
        x = nx; y = ny; w = nw; h = nh;
    }
    
    virtual void setColor(uint32_t c) {}
    virtual uint32_t getColor() { return 0xFFFFFFFF; }
    
    virtual void setText(const std::string& t) {}
    virtual std::string getText() { return ""; }
    
    virtual void setFontSize(float s) {}
    virtual float getFontSize() { return 0; }
};
