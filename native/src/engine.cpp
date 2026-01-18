#define STB_TRUETYPE_IMPLEMENTATION
#include "scene_graph.hpp"
#include "engine.h"
#include <iostream>

// --- Global Engine State ---
static Scene g_scene;

// --- Exported Functions ---

void engine_init(int32_t width, int32_t height) {
    g_scene.clear();
    std::cout << "[C++] Engine Initialized: " << width << "x" << height << " with Scene Graph & Text" << std::endl;
}

void engine_render(uint32_t* buffer, int32_t width, int32_t height) {
    g_scene.render(buffer, width, height);
}

void engine_load_font(const uint8_t* data, int32_t length) {
    g_scene.setFont(data, length);
    std::cout << "[C++] Font loaded (" << length << " bytes)" << std::endl;
}

void engine_add_rect(int32_t x, int32_t y, int32_t w, int32_t h, uint32_t color) {
    auto rect = std::make_shared<RectangleObject>(0, x, y, w, h, color);
    g_scene.add(rect);
    std::cout << "[C++] Rect added" << std::endl;
}

void engine_add_text(int32_t x, int32_t y, const char* text, uint32_t color, float size) {
    if (text) {
        auto txt = std::make_shared<TextObject>(0, x, y, std::string(text), color, size);
        g_scene.add(txt);
        std::cout << "[C++] Text added: " << text << std::endl;
    }
}

int32_t engine_pick(int32_t x, int32_t y) {
    return g_scene.pick(x, y);
}

void engine_move_object(int32_t id, int32_t dx, int32_t dy) {
    g_scene.moveObject(id, dx, dy);
}

