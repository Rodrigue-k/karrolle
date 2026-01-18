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
                row[px] = color;
            }
        }
    }
};

// --- Scene Manager ---
class Scene {
private:
    int nextId = 0;
public:
    // Polymorphic list of objects
    std::vector<std::shared_ptr<Object>> objects;

    void add(std::shared_ptr<Object> obj) {
        // Assign ID and store
        // Note: For this simplified version, we use the vector index as ID for FFI simplicity
        // In a real engine, we'd use a map<id, obj>
        objects.push_back(obj);
    }

    void render(uint32_t* buffer, int width, int height) {
        // 1. Clear Background (Dark Grey)
        std::fill_n(buffer, width * height, 0xFF252526);

        // 2. Draw all objects
        for (const auto& obj : objects) {
            obj->draw(buffer, width, height);
        }
    }

    // Returns index in vector, or -1
    int pick(int px, int py) {
        // Iterate backwards (top to bottom)
        for (int i = (int)objects.size() - 1; i >= 0; --i) {
            if (objects[i]->contains(px, py)) {
                return i;
            }
        }
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
