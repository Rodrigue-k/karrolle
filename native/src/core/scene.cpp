#include "scene.hpp"
#include "../objects/rect_object.hpp"
#include "../objects/text_object.hpp"
#include "../objects/image_object.hpp"
#include <cstdio>
#include <cmath>

void Scene::setFont(const uint8_t* data, int size) {
    fontDataBlob.assign(data, data + size);
    Font::GetDefault().load(fontDataBlob.data(), size);
}

int Scene::add(std::shared_ptr<Object> obj) {
    obj->id = nextUid++; 
    objects.push_back(obj);
    return obj->id;
}

int Scene::findIndexByUid(int uid) {
    for (size_t i = 0; i < objects.size(); ++i) {
        if (objects[i]->id == uid) return (int)i;
    }
    return -1;
}

Object* Scene::getObject(int uid) {
    int idx = findIndexByUid(uid);
    if (idx != -1) return objects[idx].get();
    return nullptr;
}

void Scene::render(uint32_t* buffer, int width, int height) {
    std::fill_n(buffer, width * height, 0xFF252526);

    for (const auto& obj : objects) {
        obj->draw(buffer, width, height);
    }

    if (selectedUid != -1) {
        Object* sel = getObject(selectedUid);
        if (sel) drawSelectionOutline(buffer, width, height, sel);
    }
}

void Scene::drawSelectionOutline(uint32_t* buffer, int w, int h, Object* obj) {
    uint32_t c = 0xFF007AFF; // Modern Blue
    
    int ox = obj->x;
    int oy = obj->y;
    int bw = obj->w;
    int bh = obj->h;

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

    int hs = 3; 
    int locations[8][2] = {
        {ox, oy}, {ox + bw / 2, oy}, {ox + bw, oy},
        {ox + bw, oy + bh / 2}, {ox + bw, oy + bh},
        {ox + bw / 2, oy + bh}, {ox, oy + bh},
        {ox, oy + bh / 2}
    };

    for (int i = 0; i < 8; i++) {
        int hx = locations[i][0];
        int hy = locations[i][1];
        
        for (int dy = -hs; dy <= hs; dy++) {
            for (int dx = -hs; dx <= hs; dx++) {
                int px = hx + dx;
                int py = hy + dy;
                if (px >= 0 && px < w && py >= 0 && py < h) {
                    if (std::abs(dx) == hs || std::abs(dy) == hs)
                        buffer[py * w + px] = c;
                    else
                        buffer[py * w + px] = 0xFFFFFFFF;
                }
            }
        }
    }
}

int Scene::pickHandle(int px, int py) {
    if (selectedUid == -1) return -1;
    Object* obj = getObject(selectedUid);
    if (!obj) return -1;

    int hs = 6; 
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

int Scene::pick(int px, int py) {
    printf("🎯 PICK at (%d, %d) - %zu objects\n", px, py, objects.size());
    
    for (int i = (int)objects.size() - 1; i >= 0; --i) {
        auto& obj = objects[i];
        printf("  [%d] '%s' @ (%d,%d) size=(%d,%d) ", 
               i, obj->name.c_str(), obj->x, obj->y, obj->w, obj->h);
        
        if (obj->contains(px, py)) {
            printf("✓ HIT!\n");
            selectedUid = obj->id;
            return selectedUid;
        } else {
            printf("✗ miss\n");
        }
    }
    
    printf("  ❌ No object hit\n");
    selectedUid = -1;
    return -1;
}

void Scene::moveObject(int uid, int dx, int dy) {
    Object* obj = getObject(uid);
    if (obj) obj->move(dx, dy);
}

void Scene::updateObjectRect(int uid, int nx, int ny, int nw, int nh) {
    Object* obj = getObject(uid);
    if (obj) obj->setRect(nx, ny, nw, nh);
}

void Scene::updateObjectColor(int uid, uint32_t col) {
    Object* obj = getObject(uid);
    if (obj) obj->setColor(col);
}

uint32_t Scene::getObjectColor(int uid) {
    Object* obj = getObject(uid);
    if (obj) return obj->getColor();
    return 0;
}

const char* Scene::getObjectText(int uid) {
    Object* obj = getObject(uid);
    if (obj) {
        static std::string lastText; 
        lastText = obj->getText();
        return lastText.c_str();
    }
    return "";
}

void Scene::updateObjectText(int uid, const char* text) {
    Object* obj = getObject(uid);
    if (obj) obj->setText(text);
}

float Scene::getObjectFontSize(int uid) {
    Object* obj = getObject(uid);
    if (obj) return obj->getFontSize();
    return 0;
}

void Scene::updateObjectFontSize(int uid, float size) {
    Object* obj = getObject(uid);
    if (obj) obj->setFontSize(size);
}

int Scene::getObjectCount() const { return (int)objects.size(); }

int Scene::getObjectUid(int index) const {
    if (index >= 0 && index < (int)objects.size()) {
        return objects[index]->id;
    }
    return -1;
}

const char* Scene::getObjectName(int index) const {
    if (index >= 0 && index < (int)objects.size()) {
        return objects[index]->name.c_str();
    }
    return "";
}

int Scene::getObjectType(int index) const {
    if (index >= 0 && index < (int)objects.size()) {
        if (std::dynamic_pointer_cast<TextObject>(objects[index])) return 1;
        if (std::dynamic_pointer_cast<ImageObject>(objects[index])) return 2;
        return 0; 
    }
    return -1;
}

void Scene::removeObject(int uid) {
    int idx = findIndexByUid(uid);
    if (idx != -1) {
        objects.erase(objects.begin() + idx);
        if (selectedUid == uid) selectedUid = -1;
    }
}

void Scene::clear() {
    objects.clear();
    nextUid = 1;
    selectedUid = -1;
}
