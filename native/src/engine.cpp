#define STB_TRUETYPE_IMPLEMENTATION
#include "engine.h"
#include "core/scene.hpp"
#include "objects/rect_object.hpp"
#include "objects/text_object.hpp"
#include "objects/image_object.hpp"
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

void engine_add_image(int32_t x, int32_t y, int32_t w, int32_t h, const uint32_t* pixels, int32_t imgW, int32_t imgH) {
    g_scene.add(std::make_shared<ImageObject>((int)g_scene.objects.size(), x, y, w, h, pixels, imgW, imgH));
}

int32_t engine_pick(int32_t x, int32_t y) {
    return g_scene.pick(x, y);
}

int32_t engine_pick_handle(int32_t x, int32_t y) {
    return g_scene.pickHandle(x, y);
}

void engine_move_object(int32_t id, int32_t dx, int32_t dy) {
    g_scene.moveObject(id, dx, dy);
}

int32_t engine_get_selected_id() {
    return g_scene.selectedUid;
}

void engine_remove_object(int32_t id) {
    g_scene.removeObject(id);
}

void engine_select_object(int32_t id) {
    if (g_scene.findIndexByUid(id) != -1) {
        g_scene.selectedUid = id;
    } else {
        g_scene.selectedUid = -1;
    }
}

void engine_get_object_bounds(int32_t id, int32_t* x, int32_t* y, int32_t* w, int32_t* h) {
    // Note: 'id' is now UID. We need to find the object.
    Object* obj = g_scene.getObject(id);
    if (obj) {
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

uint32_t engine_get_object_color(int32_t id) {
    return g_scene.getObjectColor(id);
}

// ... layers use indices ...
int32_t engine_get_object_count() {
    return g_scene.getObjectCount();
}

const char* engine_get_object_name(int32_t index) {
    return g_scene.getObjectName(index);
}

int32_t engine_get_object_type(int32_t index) {
    return g_scene.getObjectType(index);
}

int32_t engine_get_object_uid(int32_t index) {
    return g_scene.getObjectUid(index);
}

const char* engine_get_object_text(int32_t id) {
    return g_scene.getObjectText(id);
}

void engine_set_object_text(int32_t id, const char* text) {
    g_scene.updateObjectText(id, text);
}

float engine_get_object_font_size(int32_t id) {
    return g_scene.getObjectFontSize(id);
}

void engine_set_object_font_size(int32_t id, float size) {
    g_scene.updateObjectFontSize(id, size);
}

