#pragma once
#include "../core/object.hpp"
#include "../core/utils.hpp"
#include <algorithm>

class RectangleObject : public SceneObject {
public:
    uint32_t color;

    RectangleObject(int id, int x, int y, int w, int h, uint32_t color)
        : SceneObject(id, "Rectangle", x, y, w, h), color(color) {}

    void setColor(uint32_t c) override { color = c; }
    uint32_t getColor() override { return color; }

    bool contains(int px, int py) override {
        int padding = 5;
        return (px >= x - padding && px < x + w + padding && 
                py >= y - padding && py < y + h + padding);
    }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        int x0 = std::max(0, x);
        int y0 = std::max(0, y);
        int x1 = std::min(bufW, x + w);
        int y1 = std::min(bufH, y + h);

        if (x0 >= x1 || y0 >= y1) return;

        for (int py = y0; py < y1; ++py) {
            uint32_t* row = buffer + (py * bufW);
            for (int px = x0; px < x1; ++px) {
                row[px] = blendColor(row[px], color);
            }
        }
    }
};
