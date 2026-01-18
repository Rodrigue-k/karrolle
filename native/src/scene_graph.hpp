#pragma once
#include <cstdint>
#include <vector>
#include <memory>
#include <algorithm>

// --- Base Object Class ---
class Object {
public:
    int id;
    int x, y, w, h;
    
    // Virtual destructor for proper cleanup
    virtual ~Object() = default;

    Object(int id, int x, int y, int w, int h) 
        : id(id), x(x), y(y), w(w), h(h) {}

    // Pure virtual draw method (must be implemented by subclasses)
    virtual void draw(uint32_t* buffer, int bufW, int bufH) = 0;

    // Hit test for mouse interaction
    virtual bool contains(int px, int py) {
        return (px >= x && px < x + w && py >= y && py < y + h);
    }

    virtual void move(int dx, int dy) {
        x += dx;
        y += dy;
    }
};

#include "stb_truetype.h"
#include <string>

// --- Utils ---
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

// --- Font Management ---
class Font {
public:
    stbtt_fontinfo info;
    std::vector<uint8_t> buffer; // TTF data
    float scale;
    int ascent, descent, lineGap;

    bool load(const uint8_t* data, int size) {
        buffer.assign(data, data + size);
        if (!stbtt_InitFont(&info, buffer.data(), 0)) {
            return false;
        }
        // Default scale for 24px
        scale = stbtt_ScaleForPixelHeight(&info, 24);
        stbtt_GetFontVMetrics(&info, &ascent, &descent, &lineGap);
        return true;
    }
    
    // Default Font singleton
    static Font& GetDefault() {
        static Font instance;
        return instance;
    }
};

// --- Objects ---

// --- Rectangle Object ---
class RectangleObject : public Object {
public:
    uint32_t color;

    RectangleObject(int id, int x, int y, int w, int h, uint32_t color)
        : Object(id, x, y, w, h), color(color) {}

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        // Clipping to avoid segfaults
        int x0 = std::max(0, x);
        int y0 = std::max(0, y);
        int x1 = std::min(bufW, x + w);
        int y1 = std::min(bufH, y + h);

        if (x0 >= x1 || y0 >= y1) return;

        // Software Rendering Loop (Pixel by Pixel)
        for (int py = y0; py < y1; ++py) {
            uint32_t* row = buffer + (py * bufW);
            for (int px = x0; px < x1; ++px) {
                // Use blending now
                row[px] = blendColor(row[px], color);
            }
        }
    }
};

class TextObject : public Object {
public:
    std::string text;
    uint32_t color;
    float fontSize;

    TextObject(int id, int x, int y, std::string text, uint32_t color, float fontSize = 24.0f)
        : Object(id, x, y, 100, 30), text(text), color(color), fontSize(fontSize) {}

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        Font& font = Font::GetDefault();
        if (font.buffer.empty()) return; // No font loaded

        float scale = stbtt_ScaleForPixelHeight(&font.info, fontSize);
        int ascent, descent, lineGap;
        stbtt_GetFontVMetrics(&font.info, &ascent, &descent, &lineGap);
        
        int baseline = y + (int)(ascent * scale);
        int cursorX = x;

        for (char c : text) {
             int adv, lsb;
             stbtt_GetCodepointHMetrics(&font.info, c, &adv, &lsb);
             
             // Render char
             int c_x1, c_y1, c_x2, c_y2;
             stbtt_GetCodepointBitmapBox(&font.info, c, scale, scale, &c_x1, &c_y1, &c_x2, &c_y2);
             
             int y_offset = c_y1 + baseline;
             int x_offset = c_x1 + cursorX;
             
             // Get Bitmap
             int bw = c_x2 - c_x1;
             int bh = c_y2 - c_y1;
             if (bw > 0 && bh > 0) {
                 // Optimization: Stack alloc small bitmap, or heap for safety
                 std::vector<uint8_t> bitmap(bw * bh);
                 stbtt_MakeCodepointBitmap(&font.info, bitmap.data(), bw, bh, bw, scale, scale, c);
                 
                 // Blit
                 for (int iy=0; iy<bh; ++iy) {
                     int screenY = y_offset + iy;
                     if (screenY < 0 || screenY >= bufH) continue;
                     
                     for (int ix=0; ix<bw; ++ix) {
                         int screenX = x_offset + ix;
                         if (screenX < 0 || screenX >= bufW) continue;
                         
                         uint8_t alpha = bitmap[iy*bw + ix];
                         if (alpha == 0) continue;
                         
                         // Apply text color with alpha from font
                         uint32_t pixelColor = (color & 0x00FFFFFF) | ((uint32_t)alpha << 24);
                         buffer[screenY * bufW + screenX] = blendColor(buffer[screenY * bufW + screenX], pixelColor);
                     }
                 }
             }

             cursorX += (int)(adv * scale);
             // Kerning? stbtt_GetCodepointKernAdvance(&font.info, c, next_c)
        }
        
        // Update width/height for bounds check (approx)
        this->w = cursorX - x;
        this->h = (int)((ascent - descent) * scale);
    }
};

// --- Scene Manager ---
class Scene {
private:
    int nextId = 0;
public:
    // Polymorphic list of objects
    std::vector<std::shared_ptr<Object>> objects;
    
    // Font Data Storage for persistence
    std::vector<uint8_t> fontDataBlob; 

    void setFont(const uint8_t* data, int size) {
        fontDataBlob.assign(data, data + size);
        Font::GetDefault().load(fontDataBlob.data(), size);
    }

    void add(std::shared_ptr<Object> obj) {
        // Assign ID and store
        // Note: For this simplified version, we use the vector index as ID for FFI simplicity
        // In a real engine, we'd use a map<id, obj>
        objects.push_back(obj);
    }

    int selectedId = -1; // -1 means none

    void render(uint32_t* buffer, int width, int height) {
        // 1. Clear Background
        std::fill_n(buffer, width * height, 0xFF252526);

        // 2. Draw all objects
        for (const auto& obj : objects) {
            obj->draw(buffer, width, height);
        }

        // 3. Draw Selection Outline
        if (selectedId >= 0 && selectedId < (int)objects.size()) {
            drawSelectionOutline(buffer, width, height, objects[selectedId].get());
        }
    }

    void drawSelectionOutline(uint32_t* buffer, int w, int h, Object* obj) {
        // Draw Cyan Box (0xFF00FFFF)
        uint32_t color = 0xFF00FFFF;
        int x = obj->x - 2;
        int y = obj->y - 2;
        int bw = obj->w + 4;
        int bh = obj->h + 4;

        // Horiz top
        for(int i=0; i<bw; i++) {
            int px = x + i; int py = y;
            if(px>=0 && px<w && py>=0 && py<h) buffer[py*w+px] = color;
        }
        // Horiz bottom
        for(int i=0; i<bw; i++) {
            int px = x + i; int py = y + bh;
            if(px>=0 && px<w && py>=0 && py<h) buffer[py*w+px] = color;
        }
        // Vert left
        for(int i=0; i<bh; i++) {
            int px = x; int py = y + i;
            if(px>=0 && px<w && py>=0 && py<h) buffer[py*w+px] = color;
        }
        // Vert right
        for(int i=0; i<bh; i++) {
            int px = x + bw; int py = y + i;
            if(px>=0 && px<w && py>=0 && py<h) buffer[py*w+px] = color;
        }
    }

    // Returns index in vector, or -1
    int pick(int px, int py) {
        // Iterate backwards (top to bottom)
        for (int i = (int)objects.size() - 1; i >= 0; --i) {
            if (objects[i]->contains(px, py)) {
                // Set as selected!
                selectedId = i;
                return i;
            }
        }
        // Click on void deselects? Yes
        selectedId = -1;
        return -1;
    }

    void moveObject(int index, int dx, int dy) {
        if (index >= 0 && index < (int)objects.size()) {
            objects[index]->move(dx, dy);
        }
    }
    
    void clear() {
        objects.clear();
        nextId = 0;
    }
};
