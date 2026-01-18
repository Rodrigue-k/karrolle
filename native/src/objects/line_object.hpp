#pragma once
#include "../core/object.hpp"
#include "../core/utils.hpp"
#include <algorithm>
#include <cmath>

class LineObject : public SceneObject {
public:
    uint32_t color;
    int thickness;

    LineObject(int id, int x1, int y1, int x2, int y2, uint32_t color, int thickness = 2)
        : SceneObject(id, "Line", 
            std::min(x1, x2), std::min(y1, y2),
            std::abs(x2 - x1), std::abs(y2 - y1)), 
          color(color), thickness(thickness),
          _x1(x1), _y1(y1), _x2(x2), _y2(y2) {}

    int getType() override { return 4; } // 0=rect, 1=text, 2=image, 3=ellipse, 4=line

    void setColor(uint32_t c) override { color = c; }
    uint32_t getColor() override { return color; }

    bool contains(int px, int py) override {
        // Simple bounding box + proximity to line
        float dx = (float)(_x2 - _x1);
        float dy = (float)(_y2 - _y1);
        float len = std::sqrt(dx * dx + dy * dy);
        
        if (len < 1.0f) return false;
        
        // Distance from point to line
        float t = std::max(0.0f, std::min(1.0f, 
            ((px - _x1) * dx + (py - _y1) * dy) / (len * len)));
        
        float projX = _x1 + t * dx;
        float projY = _y1 + t * dy;
        
        float dist = std::sqrt((px - projX) * (px - projX) + (py - projY) * (py - projY));
        
        return dist <= thickness + 5; // 5px padding for easier selection
    }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        // Bresenham's line algorithm with thickness
        int x1 = _x1, y1 = _y1, x2 = _x2, y2 = _y2;
        
        int dx = std::abs(x2 - x1);
        int dy = std::abs(y2 - y1);
        int sx = x1 < x2 ? 1 : -1;
        int sy = y1 < y2 ? 1 : -1;
        int err = dx - dy;
        
        while (true) {
            // Draw thick point
            for (int ty = -thickness/2; ty <= thickness/2; ++ty) {
                for (int tx = -thickness/2; tx <= thickness/2; ++tx) {
                    int px = x1 + tx;
                    int py = y1 + ty;
                    if (px >= 0 && px < bufW && py >= 0 && py < bufH) {
                        buffer[py * bufW + px] = blendColor(buffer[py * bufW + px], color);
                    }
                }
            }
            
            if (x1 == x2 && y1 == y2) break;
            
            int e2 = 2 * err;
            if (e2 > -dy) {
                err -= dy;
                x1 += sx;
            }
            if (e2 < dx) {
                err += dx;
                y1 += sy;
            }
        }
    }

private:
    int _x1, _y1, _x2, _y2; // Actual line endpoints
};
