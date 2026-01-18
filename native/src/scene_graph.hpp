#pragma once
#include <cstdint>
#include <vector>
#include <memory>
#include <algorithm>
#include <string>

// --- Base Object Class ---
class Object {
public:
    int id;
    int x, y, w, h;
    
    virtual ~Object() = default;

    Object(int id, int x, int y, int w, int h) 
        : id(id), x(x), y(y), w(w), h(h) {}

    virtual void draw(uint32_t* buffer, int bufW, int bufH) = 0;

    virtual bool contains(int px, int py) {
        return (px >= x && px < x + w && py >= y && py < y + h);
    }

    virtual void move(int dx, int dy) {
        x += dx;
        y += dy;
    }
    
    virtual void setRect(int nx, int ny, int nw, int nh) {
        x = nx; y = ny; w = nw; h = nh;
    }
    
    virtual void setColor(uint32_t) {}
};

#include "stb_truetype.h"

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
    std::vector<uint8_t> buffer;
    float scale = 0;
    int ascent = 0, descent = 0, lineGap = 0;

    bool load(const uint8_t* data, int size) {
        buffer.assign(data, data + size);
        if (!stbtt_InitFont(&info, buffer.data(), 0)) {
            return false;
        }
        scale = stbtt_ScaleForPixelHeight(&info, 24);
        stbtt_GetFontVMetrics(&info, &ascent, &descent, &lineGap);
        return true;
    }
    
    static Font& GetDefault() {
        static Font instance;
        return instance;
    }
};

// --- Rectangle Object ---
class RectangleObject : public Object {
public:
    uint32_t color;

    RectangleObject(int id, int x, int y, int w, int h, uint32_t color)
        : Object(id, x, y, w, h), color(color) {}

    void setColor(uint32_t c) override { color = c; }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        int x0 = std::max(0, x);
        int y0 = std::max(0, y);
        int x1 = std::min(bufW, x + w);
        int y1 = std::min(bufH, y + h);

        if (x0 >= x1 || y0 >= y1) return;

        for (int py = y0; py < y1; ++py) {
            uint32_t* row = buffer + (py * bufW);
            for (int px = x0; px < x1; ++px) {
                row[px] = blendColor(row[px], color);
            }
        }
    }
};

// --- Text Object ---
class TextObject : public Object {
public:
    std::string text;
    uint32_t color;
    float fontSize;

    TextObject(int id, int x, int y, std::string txt, uint32_t color, float fontSize = 24.0f)
        : Object(id, x, y, 100, 30), text(std::move(txt)), color(color), fontSize(fontSize) {}

    void setColor(uint32_t c) override { color = c; }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        Font& font = Font::GetDefault();
        if (font.buffer.empty()) return;

        float sc = stbtt_ScaleForPixelHeight(&font.info, fontSize);
        int asc, desc, lg;
        stbtt_GetFontVMetrics(&font.info, &asc, &desc, &lg);
        
        int baseline = y + (int)(asc * sc);
        int cursorX = x;

        for (char c : text) {
            int adv, lsb;
            stbtt_GetCodepointHMetrics(&font.info, c, &adv, &lsb);
            
            int c_x1, c_y1, c_x2, c_y2;
            stbtt_GetCodepointBitmapBox(&font.info, c, sc, sc, &c_x1, &c_y1, &c_x2, &c_y2);
            
            int y_off = c_y1 + baseline;
            int x_off = c_x1 + cursorX;
            
            int bw = c_x2 - c_x1;
            int bh = c_y2 - c_y1;
            if (bw > 0 && bh > 0) {
                std::vector<uint8_t> bitmap(bw * bh);
                stbtt_MakeCodepointBitmap(&font.info, bitmap.data(), bw, bh, bw, sc, sc, c);
                
                for (int iy = 0; iy < bh; ++iy) {
                    int screenY = y_off + iy;
                    if (screenY < 0 || screenY >= bufH) continue;
                    
                    for (int ix = 0; ix < bw; ++ix) {
                        int screenX = x_off + ix;
                        if (screenX < 0 || screenX >= bufW) continue;
                        
                        uint8_t alpha = bitmap[iy * bw + ix];
                        if (alpha == 0) continue;
                        
                        uint32_t pixelColor = (color & 0x00FFFFFF) | ((uint32_t)alpha << 24);
                        buffer[screenY * bufW + screenX] = blendColor(buffer[screenY * bufW + screenX], pixelColor);
                    }
                }
            }
            cursorX += (int)(adv * sc);
        }
        
        this->w = cursorX - x;
        this->h = (int)((asc - desc) * sc);
    }
};

// --- Scene Manager ---
class Scene {
private:
    int nextId = 0;
public:
    std::vector<std::shared_ptr<Object>> objects;
    std::vector<uint8_t> fontDataBlob; 
    int selectedId = -1;

    void setFont(const uint8_t* data, int size) {
        fontDataBlob.assign(data, data + size);
        Font::GetDefault().load(fontDataBlob.data(), size);
    }

    void add(std::shared_ptr<Object> obj) {
        objects.push_back(obj);
    }

    void render(uint32_t* buffer, int width, int height) {
        std::fill_n(buffer, width * height, 0xFF252526);

        for (const auto& obj : objects) {
            obj->draw(buffer, width, height);
        }

        if (selectedId >= 0 && selectedId < (int)objects.size()) {
            drawSelectionOutline(buffer, width, height, objects[selectedId].get());
        }
    }

    void drawSelectionOutline(uint32_t* buffer, int w, int h, Object* obj) {
        uint32_t c = 0xFF00FFFF;
        int ox = obj->x - 2;
        int oy = obj->y - 2;
        int bw = obj->w + 4;
        int bh = obj->h + 4;

        for (int i = 0; i < bw; i++) {
            int px = ox + i;
            if (px >= 0 && px < w && oy >= 0 && oy < h) buffer[oy * w + px] = c;
            if (px >= 0 && px < w && oy + bh >= 0 && oy + bh < h) buffer[(oy + bh) * w + px] = c;
        }
        for (int i = 0; i < bh; i++) {
            int py = oy + i;
            if (ox >= 0 && ox < w && py >= 0 && py < h) buffer[py * w + ox] = c;
            if (ox + bw >= 0 && ox + bw < w && py >= 0 && py < h) buffer[py * w + ox + bw] = c;
        }
    }

    int pick(int px, int py) {
        for (int i = (int)objects.size() - 1; i >= 0; --i) {
            if (objects[i]->contains(px, py)) {
                selectedId = i;
                return i;
            }
        }
        selectedId = -1;
        return -1;
    }

    void moveObject(int index, int dx, int dy) {
        if (index >= 0 && index < (int)objects.size()) {
            objects[index]->move(dx, dy);
        }
    }
    
    void updateObjectRect(int id, int nx, int ny, int nw, int nh) {
        if (id >= 0 && id < (int)objects.size()) {
            objects[id]->setRect(nx, ny, nw, nh);
        }
    }
    
    void updateObjectColor(int id, uint32_t col) {
        if (id >= 0 && id < (int)objects.size()) {
            objects[id]->setColor(col);
        }
    }
    
    void clear() {
        objects.clear();
        nextId = 0;
    }
};
