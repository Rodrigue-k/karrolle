#define STB_TRUETYPE_IMPLEMENTATION
#include "scene_graph.hpp"
#include "engine.h"
#include <memory>

Scene g_scene;

void engine_init(int32_t, int32_t) {
    g_scene.clear();
}

void engine_render(uint32_t* buffer, int32_t width, int32_t height) {
    g_scene.render(buffer, width, height);
}

void engine_add_rect(int32_t x, int32_t y, int32_t w, int32_t h, uint32_t color) {
    g_scene.add(std::make_shared<RectangleObject>((int)g_scene.objects.size(), x, y, w, h, color));
}

void engine_load_font(const uint8_t* data, int32_t length) {
    g_scene.setFont(data, length);
}

void engine_add_text(int32_t x, int32_t y, const char* text, uint32_t color, float size) {
    g_scene.add(std::make_shared<TextObject>((int)g_scene.objects.size(), x, y, text, color, size));
}

int32_t engine_pick(int32_t x, int32_t y) {
    return g_scene.pick(x, y);
}

void engine_move_object(int32_t id, int32_t dx, int32_t dy) {
    g_scene.moveObject(id, dx, dy);
}

int32_t engine_get_selected_id() {
    return g_scene.selectedId;
}

void engine_get_object_bounds(int32_t id, int32_t* x, int32_t* y, int32_t* w, int32_t* h) {
    if (id >= 0 && id < (int)g_scene.objects.size()) {
        auto& obj = g_scene.objects[id];
        if (x) *x = obj->x;
        if (y) *y = obj->y;
        if (w) *w = obj->w;
        if (h) *h = obj->h;
    }
}

void engine_set_object_rect(int32_t id, int32_t x, int32_t y, int32_t w, int32_t h) {
    g_scene.updateObjectRect(id, x, y, w, h);
}

void engine_set_object_color(int32_t id, uint32_t color) {
    g_scene.updateObjectColor(id, color);
}
