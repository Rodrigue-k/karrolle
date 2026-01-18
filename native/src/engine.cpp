#include "engine.h"
#include <iostream>
#include <vector>

// Simple global state for prototype
int g_width = 800;
int g_height = 600;

void engine_init(int width, int height) {
    g_width = width;
    g_height = height;
    std::cout << "[C++] Engine Initialized: " << width << "x" << height << std::endl;
}

void engine_render(uint32_t* buffer, int width, int height) {
    // Fill with a simple pattern (Red/Blue gradient)
    for (int y = 0; y < height; ++y) {
        for (int x = 0; x < width; ++x) {
            uint8_t r = (x * 255) / width;
            uint8_t g = (y * 255) / height;
            uint8_t b = 128;
            uint8_t a = 255;
            
            // Format BGRA (common for Flutter/Skia)
            buffer[y * width + x] = (a << 24) | (r << 16) | (g << 8) | b;
        }
    }
}
