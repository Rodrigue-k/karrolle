#pragma once
#include "../core/object.hpp"
#include "../core/utils.hpp"
#include <algorithm>

class RectangleObject : public SceneObject {
public:
    uint32_t color;

    RectangleObject(int id, float x, float y, float w, float h, uint32_t color)
        : SceneObject(id, "Rectangle", x, y, w, h), color(color) {}

    void setColor(uint32_t c) override { color = c; }
    uint32_t getColor() override { return color; }

    bool contains(int px, int py) override {
        int padding = 5;
        return (px >= (int)x - padding && px < (int)x + (int)w + padding && 
                py >= (int)y - padding && py < (int)y + (int)h + padding);
    }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        int ix = (int)x;
        int iy = (int)y;
        int iw = (int)w;
        int ih = (int)h;

        int x0 = std::max(0, ix);
        int y0 = std::max(0, iy);
        int x1 = std::min(bufW, ix + iw);
        int y1 = std::min(bufH, iy + ih);

        if (x0 >= x1 || y0 >= y1) return;

        for (int py = y0; py < y1; ++py) {
            uint32_t* row = buffer + (py * bufW);
            for (int px = x0; px < x1; ++px) {
                row[px] = blendColor(row[px], color);
            }
        }
    }
};
