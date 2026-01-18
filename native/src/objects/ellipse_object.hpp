#pragma once
#include "../core/object.hpp"
#include "../core/utils.hpp"
#include <algorithm>
#include <cmath>

class EllipseObject : public SceneObject {
public:
    uint32_t color;

    EllipseObject(int id, int x, int y, int w, int h, uint32_t color)
        : SceneObject(id, "Ellipse", x, y, w, h), color(color) {}

    int getType() override { return 3; } // 0=rect, 1=text, 2=image, 3=ellipse

    void setColor(uint32_t c) override { color = c; }
    uint32_t getColor() override { return color; }

    bool contains(int px, int py) override {
        // Ellipse equation: ((px-cx)/rx)^2 + ((py-cy)/ry)^2 <= 1
        float cx = x + w / 2.0f;
        float cy = y + h / 2.0f;
        float rx = w / 2.0f;
        float ry = h / 2.0f;
        
        if (rx <= 0 || ry <= 0) return false;
        
        float dx = (px - cx) / rx;
        float dy = (py - cy) / ry;
        
        // Add some padding for easier selection
        float padding = 5.0f;
        float rxPad = (rx + padding) / rx;
        float ryPad = (ry + padding) / ry;
        
        return (dx * dx + dy * dy) <= (rxPad * ryPad);
    }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        float cx = x + w / 2.0f;
        float cy = y + h / 2.0f;
        float rx = w / 2.0f;
        float ry = h / 2.0f;

        if (rx <= 0 || ry <= 0) return;

        int x0 = std::max(0, x);
        int y0 = std::max(0, y);
        int x1 = std::min(bufW, x + w);
        int y1 = std::min(bufH, y + h);

        for (int py = y0; py < y1; ++py) {
            uint32_t* row = buffer + (py * bufW);
            for (int px = x0; px < x1; ++px) {
                // Check if point is inside ellipse
                float dx = (px - cx) / rx;
                float dy = (py - cy) / ry;
                
                if (dx * dx + dy * dy <= 1.0f) {
                    row[px] = blendColor(row[px], color);
                }
            }
        }
    }
};
