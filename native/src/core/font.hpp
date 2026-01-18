#pragma once
#include <vector>
#include <cstdint>
#include "stb_truetype.h" 

class Font {
public:
    stbtt_fontinfo info;
    std::vector<uint8_t> buffer;
    float scale = 0;
    int ascent = 0, descent = 0, lineGap = 0;

    bool load(const uint8_t* data, int size) {
        buffer.assign(data, data + size);
        if (!stbtt_InitFont(&info, buffer.data(), 0)) {
            return false;
        }
        scale = stbtt_ScaleForPixelHeight(&info, 24);
        stbtt_GetFontVMetrics(&info, &ascent, &descent, &lineGap);
        return true;
    }
    
    static Font& GetDefault() {
        static Font instance;
        return instance;
    }
};
