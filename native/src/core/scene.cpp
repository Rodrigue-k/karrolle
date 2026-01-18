#include "scene.hpp"
#include "../objects/rect_object.hpp"
#include "../objects/text_object.hpp"
#include "../objects/image_object.hpp"
#include <cstdio>
#include <cmath>
#include <algorithm>

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

    if (selectedUids.empty()) return;

    for (int uid : selectedUids) {
        Object* sel = getObject(uid);
        if (sel) drawSelectionOutline(buffer, width, height, sel);
    }

    // Draw global bounding box if multiple selected
    if (selectedUids.size() > 1) {
        int minX = 1000000;
        int minY = 1000000;
        int maxX = -1000000;
        int maxY = -1000000;
        bool any = false;

        for (int uid : selectedUids) {
            Object* obj = getObject(uid);
            if (obj) {
                any = true;
                // Cast to int for pixel bounds calculation
                int ox = (int)obj->x;
                int oy = (int)obj->y;
                int ow = (int)obj->w;
                int oh = (int)obj->h;

                minX = std::min(minX, ox);
                minY = std::min(minY, oy);
                maxX = std::max(maxX, ox + ow);
                maxY = std::max(maxY, oy + oh);
            }
        }
        if (any) {
            uint32_t c = 0xFFFFFFFF; // White for group box
            // Draw lines for bounding box
            for (int i = minX; i < maxX; i++) {
                if (i >= 0 && i < width) {
                    if (minY >= 0 && minY < height) buffer[minY * width + i] = c;
                    if (maxY - 1 >= 0 && maxY - 1 < height) buffer[(maxY - 1) * width + i] = c;
                }
            }
            for (int i = minY; i < maxY; i++) {
                if (i >= 0 && i < height) {
                    if (minX >= 0 && minX < width) buffer[i * width + minX] = c;
                    if (maxX - 1 >= 0 && maxX - 1 < width) buffer[i * width + maxX - 1] = c;
                }
            }
        }
    }
}

void Scene::drawSelectionOutline(uint32_t* buffer, int w, int h, Object* obj) {
    uint32_t c = 0xFF007AFF; // Modern Blue
    
    int ox = (int)obj->x;
    int oy = (int)obj->y;
    int bw = (int)obj->w;
    int bh = (int)obj->h;

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

    // Handles only if single selection
    if (selectedUids.size() == 1) {
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
}

int Scene::pickHandle(int px, int py) {
    if (selectedUids.size() != 1) return -1;
    
    Object* obj = getObject(selectedUids[0]);
    if (!obj) return -1;

    int hs = 8; // Slightly larger hit area for ease of use
    int x = (int)obj->x;
    int y = (int)obj->y;
    int w = (int)obj->w;
    int h = (int)obj->h;

    // Same order as drawSelectionOutline
    // 0=TL, 1=T, 2=TR, 3=R, 4=BR, 5=B, 6=BL, 7=L
    int locations[8][2] = {
        {x, y},             {x + w / 2, y},     {x + w, y},
        {x + w, y + h / 2}, {x + w, y + h},
        {x + w / 2, y + h}, {x, y + h},
        {x, y + h / 2}
    };

    for (int i = 0; i < 8; i++) {
        int hx = locations[i][0];
        int hy = locations[i][1];
        
        if (px >= hx - hs && px <= hx + hs && 
            py >= hy - hs && py <= hy + hs) {
            return i;
        }
    }

    return -1;
}

int Scene::pick(int px, int py) {
    // Pure hit testing, no side effects
    
    for (int i = (int)objects.size() - 1; i >= 0; --i) {
        auto& obj = objects[i];
        if (obj->contains(px, py)) {
            return obj->id;
        }
    }
    
    return -1;
}

// Selection Management
void Scene::select(int uid, bool addToSelection) {
    if (uid == -1) return;
    
    if (!addToSelection) {
        selectedUids.clear();
    }
    
    // Avoid duplicates
    bool found = false;
    for(int id : selectedUids) {
        if(id == uid) { found = true; break;}
    }
    if(!found) selectedUids.push_back(uid);
}

void Scene::deselect(int uid) {
     auto it = std::remove(selectedUids.begin(), selectedUids.end(), uid);
     selectedUids.erase(it, selectedUids.end());
}

void Scene::clearSelection() {
    selectedUids.clear();
}

bool Scene::isSelected(int uid) {
    for(int id : selectedUids) {
        if(id == uid) return true;
    }
    return false;
}

int Scene::getPrimarySelection() {
    if (selectedUids.empty()) return -1;
    return selectedUids.back();
}

void Scene::moveSelection(float dx, float dy) {
    for (int uid : selectedUids) {
        Object* obj = getObject(uid);
        if (obj) obj->move(dx, dy);
    }
}

void Scene::moveObject(int uid, float dx, float dy) {
    Object* obj = getObject(uid);
    if (obj) obj->move(dx, dy);
}

void Scene::updateObjectRect(int uid, float nx, float ny, float nw, float nh) {
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
        deselect(uid);
    }
}

void Scene::clear() {
    objects.clear();
    nextUid = 1;
    clearSelection();
}
