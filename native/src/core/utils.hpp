#pragma once
#include <cstdint>

inline uint32_t blendColor(uint32_t bg, uint32_t fg) {
    int a = (fg >> 24) & 0xFF;
    if (a == 0) return bg;
    if (a == 255) return fg;
    int invA = 255 - a;
    int r = (((fg >> 16) & 0xFF) * a + ((bg >> 16) & 0xFF) * invA) >> 8;
    int g = (((fg >> 8) & 0xFF) * a + ((bg >> 8) & 0xFF) * invA) >> 8;
    int b = (((fg) & 0xFF) * a + ((bg) & 0xFF) * invA) >> 8;
    return 0xFF000000 | (r << 16) | (g << 8) | b;
}
