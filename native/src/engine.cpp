#include "engine.h"
#include "scene_graph.hpp"
#include <iostream>

// --- Global Engine State ---
static Scene g_scene;

// --- Exported Functions ---

void engine_init(int32_t width, int32_t height) {
    g_scene.clear();
    std::cout << "[C++] Engine Initialized: " << width << "x" << height << " with Scene Graph" << std::endl;
}

void engine_render(uint32_t* buffer, int32_t width, int32_t height) {
    g_scene.render(buffer, width, height);
}

void engine_add_rect(int32_t x, int32_t y, int32_t w, int32_t h, uint32_t color) {
    // Create a new RectangleObject via shared_ptr
    // ID is currently managed by vector index logic in Scene::add, so passing 0 is placeholder
    auto rect = std::make_shared<RectangleObject>(0, x, y, w, h, color);
    g_scene.add(rect);
    std::cout << "[C++] Rect Object added at " << x << "," << y << std::endl;
}

int32_t engine_pick(int32_t x, int32_t y) {
    return g_scene.pick(x, y);
}

void engine_move_object(int32_t id, int32_t dx, int32_t dy) {
    g_scene.moveObject(id, dx, dy);
}

