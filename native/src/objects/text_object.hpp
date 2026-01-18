#pragma once
#include "../core/object.hpp"
#include "../core/utils.hpp"
#include "../core/font.hpp"
#include <string>
#include <vector>

class TextObject : public Object {
public:
    std::string text;
    uint32_t color;
    float fontSize;

    TextObject(int id, int x, int y, std::string txt, uint32_t color, float fontSize = 24.0f)
        : Object(id, "Text", x, y, 100, 30), text(std::move(txt)), color(color), fontSize(fontSize) {
        recalculateBounds();
    }

    void setColor(uint32_t c) override { color = c; }
    uint32_t getColor() override { return color; }
    
    void setFontSize(float s) override { 
        fontSize = s; 
        recalculateBounds();
    }
    float getFontSize() override { return fontSize; }
    
    void setText(const std::string& t) override { 
        text = t;
        recalculateBounds();
    }
    std::string getText() override { return text; }

    bool contains(int px, int py) override {
        int padding = 20;
        return (px >= x - padding && px < x + w + padding && 
                py >= y - padding && py < y + h + padding);
    }

    void recalculateBounds() {
        Font& font = Font::GetDefault();
        if (!font.buffer.empty()) {
            float sc = stbtt_ScaleForPixelHeight(&font.info, fontSize);
            int asc, desc, lg;
            stbtt_GetFontVMetrics(&font.info, &asc, &desc, &lg);
            
            int cursorX = 0;
            for (char c : text) {
                int adv, lsb;
                stbtt_GetCodepointHMetrics(&font.info, c, &adv, &lsb);
                cursorX += (int)(adv * sc);
            }
            
            this->w = cursorX;
            this->h = (int)((asc - desc) * sc);
        }
    }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        Font& font = Font::GetDefault();
        if (font.buffer.empty()) return;

        float sc = stbtt_ScaleForPixelHeight(&font.info, fontSize);
        int asc, desc, lg;
        stbtt_GetFontVMetrics(&font.info, &asc, &desc, &lg);
        
        int baseline = y + (int)(asc * sc);
        int cursorX = x;

        for (char c : text) {
            int adv, lsb;
            stbtt_GetCodepointHMetrics(&font.info, c, &adv, &lsb);
            
            int c_x1, c_y1, c_x2, c_y2;
            stbtt_GetCodepointBitmapBox(&font.info, c, sc, sc, &c_x1, &c_y1, &c_x2, &c_y2);
            
            int y_off = c_y1 + baseline;
            int x_off = c_x1 + cursorX;
            
            int bw = c_x2 - c_x1;
            int bh = c_y2 - c_y1;
            if (bw > 0 && bh > 0) {
                std::vector<uint8_t> bitmap(bw * bh);
                stbtt_MakeCodepointBitmap(&font.info, bitmap.data(), bw, bh, bw, sc, sc, c);
                
                for (int iy = 0; iy < bh; ++iy) {
                    int screenY = y_off + iy;
                    if (screenY < 0 || screenY >= bufH) continue;
                    
                    for (int ix = 0; ix < bw; ++ix) {
                        int screenX = x_off + ix;
                        if (screenX < 0 || screenX >= bufW) continue;
                        
                        uint8_t alpha = bitmap[iy * bw + ix];
                        if (alpha == 0) continue;
                        
                        uint32_t pixelColor = (color & 0x00FFFFFF) | ((uint32_t)alpha << 24);
                        buffer[screenY * bufW + screenX] = blendColor(buffer[screenY * bufW + screenX], pixelColor);
                    }
                }
            }
            cursorX += (int)(adv * sc);
        }
        
        this->w = cursorX - x;
        this->h = (int)((asc - desc) * sc);
    }
};
