#ifndef KARROLLE_ENGINE_H
#define KARROLLE_ENGINE_H

#include <stdint.h>

#ifdef WIN32
    #define EXPORT __declspec(dllexport)
#else
    #define EXPORT __attribute__((visibility("default")))
#endif

extern "C" {
    EXPORT void engine_init(int width, int height);
    EXPORT void engine_render(uint32_t* buffer, int width, int height);
}

#endif // KARROLLE_ENGINE_H
