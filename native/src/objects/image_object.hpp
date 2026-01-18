#pragma once
#include "../core/object.hpp"
#include "../core/utils.hpp"
#include <vector>

class ImageObject : public Object {
public:
    std::vector<uint32_t> pixels;
    int imgW, imgH;

    ImageObject(int id, int x, int y, int w, int h, const uint32_t* data, int dataW, int dataH)
        : Object(id, "Image", x, y, w, h), imgW(dataW), imgH(dataH) {
        pixels.assign(data, data + (dataW * dataH));
    }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        if (pixels.empty() || imgW <= 0 || imgH <= 0) return;

        int x0 = std::max(0, x);
        int y0 = std::max(0, y);
        int x1 = std::min(bufW, x + w);
        int y1 = std::min(bufH, y + h);

        if (x0 >= x1 || y0 >= y1) return;

        for (int py = y0; py < y1; ++py) {
            uint32_t* row = buffer + (py * bufW);
            
            // Texture Y coordinate
            int texY = ((py - y) * imgH) / h;
            if (texY >= imgH) texY = imgH - 1;
            
            const uint32_t* srcRow = pixels.data() + (texY * imgW);

            for (int px = x0; px < x1; ++px) {
                // Texture X coordinate
                int texX = ((px - x) * imgW) / w;
                if (texX >= imgW) texX = imgW - 1;
                
                uint32_t color = srcRow[texX];
                row[px] = blendColor(row[px], color);
            }
        }
    }
};
