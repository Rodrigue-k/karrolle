#pragma once
#include "../core/object.hpp"
#include "../core/utils.hpp"
#include <vector>

class ImageObject : public Object {
public:
    std::vector<uint32_t> pixels;
    int imgW, imgH;

    ImageObject(int id, float x, float y, float w, float h, const uint32_t* data, int dataW, int dataH)
        : Object(id, "Image", x, y, w, h), imgW(dataW), imgH(dataH) {
        pixels.assign(data, data + (dataW * dataH));
    }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        if (pixels.empty() || imgW <= 0 || imgH <= 0) return;

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
            
            // Texture Y coordinate
            int texY = (int)(((py - iy) * imgH) / ih);
            if (texY < 0) texY = 0;
            if (texY >= imgH) texY = imgH - 1;
            
            const uint32_t* srcRow = pixels.data() + (texY * imgW);

            for (int px = x0; px < x1; ++px) {
                // Texture X coordinate
                int texX = (int)(((px - ix) * imgW) / iw);
                if (texX < 0) texX = 0;
                if (texX >= imgW) texX = imgW - 1;
                
                uint32_t color = srcRow[texX];
                row[px] = blendColor(row[px], color);
            }
        }
    }
};
