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
    std::string name;
    int x, y, w, h;
    
    virtual ~Object() = default;

    Object(int id, std::string name, int x, int y, int w, int h) 
        : id(id), name(std::move(name)), x(x), y(y), w(w), h(h) {}

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
    
    virtual void setColor(uint32_t c) {}
    virtual uint32_t getColor() { return 0xFFFFFFFF; }
    
    virtual void setText(const std::string& t) {}
    virtual std::string getText() { return ""; }
    
    virtual void setFontSize(float s) {}
    virtual float getFontSize() { return 0; }
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
        : Object(id, "Rectangle", x, y, w, h), color(color) {}

    void setColor(uint32_t c) override { color = c; }
    uint32_t getColor() override { return color; }

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
        : Object(id, "Text", x, y, 100, 30), text(std::move(txt)), color(color), fontSize(fontSize) {}

    void setColor(uint32_t c) override { color = c; }
    uint32_t getColor() override { return color; }
    
    void setFontSize(float s) override { fontSize = s; }
    float getFontSize() override { return fontSize; }
    
    void setText(const std::string& t) override { text = t; }
    std::string getText() override { return text; }

    // Override contains for better hit detection (add padding)
    bool contains(int px, int py) override {
        int padding = 10;
        return (px >= x - padding && px < x + w + padding && 
                py >= y - padding && py < y + h + padding);
    }

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

// --- Image Object ---
class ImageObject : public Object {
public:
    std::vector<uint32_t> pixels; // RBGA or ARGB? Expecting native engine format (ARGB or ABGR)
    // Actually our blendColor expects: 0xAARRGGBB.
    int imgW, imgH;

    ImageObject(int id, int x, int y, int w, int h, const uint32_t* data, int dataW, int dataH)
        : Object(id, "Image", x, y, w, h), imgW(dataW), imgH(dataH) {
        pixels.assign(data, data + (dataW * dataH));
    }

    void draw(uint32_t* buffer, int bufW, int bufH) override {
        if (pixels.empty() || imgW <= 0 || imgH <= 0) return;

        int x0 = std::max(0, x);
        int y0 = std::max(0, y);
        int x1 = std::min(bufW, x + w);
        int y1 = std::min(bufH, y + h);

        if (x0 >= x1 || y0 >= y1) return;

        // Simple Nearest Neighbor Scaling
        for (int py = y0; py < y1; ++py) {
            uint32_t* row = buffer + (py * bufW);
            
            // Texture Y coordinate
            int texY = ((py - y) * imgH) / h;
            if (texY >= imgH) texY = imgH - 1;
            
            const uint32_t* srcRow = pixels.data() + (texY * imgW);

            for (int px = x0; px < x1; ++px) {
                // Texture X coordinate
                int texX = ((px - x) * imgW) / w;
                if (texX >= imgW) texX = imgW - 1;
                
                uint32_t color = srcRow[texX];
                row[px] = blendColor(row[px], color);
            }
        }
    }
};
// --- Scene Manager ---
class Scene {
private:
    int nextUid = 1; // 0 can be invalid or background
public:
    std::vector<std::shared_ptr<Object>> objects;
    std::vector<uint8_t> fontDataBlob; 
    int selectedUid = -1;

    void setFont(const uint8_t* data, int size) {
        fontDataBlob.assign(data, data + size);
        Font::GetDefault().load(fontDataBlob.data(), size);
    }

    int add(std::shared_ptr<Object> obj) {
        obj->id = nextUid++; // Assign persistent UID
        objects.push_back(obj);
        return obj->id;
    }
    
    // Find object index by UID (helper)
    int findIndexByUid(int uid) {
        for (size_t i = 0; i < objects.size(); ++i) {
            if (objects[i]->id == uid) return (int)i;
        }
        return -1;
    }
    
    // Find object pointer by UID
    Object* getObject(int uid) {
        int idx = findIndexByUid(uid);
        if (idx != -1) return objects[idx].get();
        return nullptr;
    }

    void render(uint32_t* buffer, int width, int height) {
        std::fill_n(buffer, width * height, 0xFF252526);

        for (const auto& obj : objects) {
            obj->draw(buffer, width, height);
        }

        if (selectedUid != -1) {
            Object* sel = getObject(selectedUid);
            if (sel) drawSelectionOutline(buffer, width, height, sel);
        }
    }

    void drawSelectionOutline(uint32_t* buffer, int w, int h, Object* obj) {
        uint32_t c = 0xFF007AFF; // Modern Blue (Canva-like)
        
        // Draw main bounding box
        int ox = obj->x;
        int oy = obj->y;
        int bw = obj->w;
        int bh = obj->h;

        // Draw selection lines
        for (int i = 0; i < bw; i++) {
            int px = ox + i;
            if (px >= 0 && px < w) {
                if (oy >= 0 && oy < h) buffer[oy * w + px] = c;
                if (oy + bh - 1 >= 0 && oy + bh - 1 < h) buffer[(oy + bh - 1) * w + px] = c;
            }
        }
        for (int i = 0; i < bh; i++) {
            int py = oy + i;
            if (py >= 0 && py < h) {
                if (ox >= 0 && ox < w) buffer[py * w + ox] = c;
                if (ox + bw - 1 >= 0 && ox + bw - 1 < w) buffer[py * w + ox + bw - 1] = c;
            }
        }

        // Draw 8 handles (Squares)
        int hs = 3; // radius 
        int locations[8][2] = {
            {ox, oy}, {ox + bw / 2, oy}, {ox + bw, oy},
            {ox + bw, oy + bh / 2}, {ox + bw, oy + bh},
            {ox + bw / 2, oy + bh}, {ox, oy + bh},
            {ox, oy + bh / 2}
        };

        for (int i = 0; i < 8; i++) {
            int hx = locations[i][0];
            int hy = locations[i][1];
            
            // Draw square
            for (int dy = -hs; dy <= hs; dy++) {
                for (int dx = -hs; dx <= hs; dx++) {
                    int px = hx + dx;
                    int py = hy + dy;
                    if (px >= 0 && px < w && py >= 0 && py < h) {
                        // White fill with blue border
                        if (std::abs(dx) == hs || std::abs(dy) == hs)
                            buffer[py * w + px] = c;
                        else
                            buffer[py * w + px] = 0xFFFFFFFF;
                    }
                }
            }
        }
    }

    int pickHandle(int px, int py) {
        if (selectedUid == -1) return -1;
        Object* obj = getObject(selectedUid);
        if (!obj) return -1;

        int hs = 6; // Hit area radius
        int ox = obj->x;
        int oy = obj->y;
        int bw = obj->w;
        int bh = obj->h;

        int locations[8][2] = {
            {ox, oy}, {ox + bw / 2, oy}, {ox + bw, oy},
            {ox + bw, oy + bh / 2}, {ox + bw, oy + bh},
            {ox + bw / 2, oy + bh}, {ox, oy + bh},
            {ox, oy + bh / 2}
        };

        for (int i = 0; i < 8; i++) {
            if (px >= locations[i][0] - hs && px <= locations[i][0] + hs &&
                py >= locations[i][1] - hs && py <= locations[i][1] + hs) {
                return i;
            }
        }
        return -1;
    }

    int pick(int px, int py) {
        for (int i = (int)objects.size() - 1; i >= 0; --i) {
            if (objects[i]->contains(px, py)) {
                selectedUid = objects[i]->id;
                return selectedUid;
            }
        }
        selectedUid = -1;
        return -1;
    }

    void moveObject(int uid, int dx, int dy) {
        Object* obj = getObject(uid);
        if (obj) obj->move(dx, dy);
    }
    
    void updateObjectRect(int uid, int nx, int ny, int nw, int nh) {
        Object* obj = getObject(uid);
        if (obj) obj->setRect(nx, ny, nw, nh);
    }
    
    void updateObjectColor(int uid, uint32_t col) {
        Object* obj = getObject(uid);
        if (obj) obj->setColor(col);
    }

    uint32_t getObjectColor(int uid) {
        Object* obj = getObject(uid);
        if (obj) return obj->getColor();
        return 0;
    }
    
    const char* getObjectText(int uid) {
        Object* obj = getObject(uid);
        if (obj) {
            static std::string lastText; 
            lastText = obj->getText();
            return lastText.c_str();
        }
        return "";
    }
    
    void updateObjectText(int uid, const char* text) {
        Object* obj = getObject(uid);
        if (obj) obj->setText(text);
    }
    
    float getObjectFontSize(int uid) {
        Object* obj = getObject(uid);
        if (obj) return obj->getFontSize();
        return 0;
    }
    
    void updateObjectFontSize(int uid, float size) {
        Object* obj = getObject(uid);
        if (obj) obj->setFontSize(size);
    }
    
    // --- Layer Management (Index-based) ---

    int getObjectCount() const { return (int)objects.size(); }
    
    // Get UID at specific layer index
    int getObjectUid(int index) const {
        if (index >= 0 && index < (int)objects.size()) {
            return objects[index]->id;
        }
        return -1;
    }
    
    const char* getObjectName(int index) const {
        if (index >= 0 && index < (int)objects.size()) {
            return objects[index]->name.c_str();
        }
        return "";
    }
    
    int getObjectType(int index) const {
        if (index >= 0 && index < (int)objects.size()) {
            if (std::dynamic_pointer_cast<TextObject>(objects[index])) return 1;
            if (std::dynamic_pointer_cast<ImageObject>(objects[index])) return 2;
            return 0; // Default to rect
        }
        return -1;
    }
    
    void removeObject(int uid) {
        int idx = findIndexByUid(uid);
        if (idx != -1) {
            objects.erase(objects.begin() + idx);
            if (selectedUid == uid) selectedUid = -1;
        }
    }
    
    void clear() {
        objects.clear();
        nextUid = 1;
        selectedUid = -1;
    }
};

