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

// Add Object
EXPORT void engine_add_rect(int32_t x, int32_t y, int32_t w, int32_t h, uint32_t color);

// Interaction
// Returns the index of the object at (x,y), or -1 if none.
EXPORT int32_t engine_pick(int32_t x, int32_t y);

// Move an object by delta
EXPORT void engine_move_object(int32_t id, int32_t dx, int32_t dy);

#ifdef __cplusplus
}
#endif

#endif // ENGINE_H
