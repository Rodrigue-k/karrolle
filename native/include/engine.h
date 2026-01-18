#ifndef ENGINE_H
#define ENGINE_H

#include <stdint.h>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Initialize
EXPORT void engine_init(int32_t width, int32_t height);

// Render
EXPORT void engine_render(uint32_t* buffer, int32_t width, int32_t height);

// Objects
EXPORT void engine_add_rect(int32_t x, int32_t y, int32_t w, int32_t h, uint32_t color);
EXPORT void engine_add_text(int32_t x, int32_t y, const char* text, uint32_t color, float size);
EXPORT void engine_add_image(int32_t x, int32_t y, int32_t w, int32_t h, const uint32_t* pixels, int32_t imgW, int32_t imgH);

// Font Management
EXPORT void engine_load_font(const uint8_t* data, int32_t length);

// Interaction
EXPORT int32_t engine_pick(int32_t x, int32_t y);
EXPORT int32_t engine_pick_handle(int32_t x, int32_t y);
EXPORT void engine_move_object(int32_t id, int32_t dx, int32_t dy); // Relative move
EXPORT void engine_set_object_rect(int32_t id, int32_t x, int32_t y, int32_t w, int32_t h); // Absolute update
EXPORT void engine_set_object_color(int32_t id, uint32_t color);

// Inspection
EXPORT int32_t engine_get_selected_id();
EXPORT void engine_get_object_bounds(int32_t id, int32_t* x, int32_t* y, int32_t* w, int32_t* h);
EXPORT uint32_t engine_get_object_color(int32_t id);
EXPORT int32_t engine_get_object_count();
EXPORT const char* engine_get_object_name(int32_t index);
EXPORT int32_t engine_get_object_type(int32_t index);
EXPORT void engine_remove_object(int32_t id);
EXPORT int32_t engine_get_object_uid(int32_t index);
EXPORT void engine_select_object(int32_t id);

EXPORT const char* engine_get_object_text(int32_t id);
EXPORT void engine_set_object_text(int32_t id, const char* text);
EXPORT float engine_get_object_font_size(int32_t id);
EXPORT void engine_set_object_font_size(int32_t id, float size);

#ifdef __cplusplus
}
#endif

#endif // ENGINE_H
