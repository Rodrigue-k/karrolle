#pragma once
#include <vector>
#include <memory>
#include <algorithm>
#include "object.hpp"
#include "font.hpp"

class Scene {
private:
    int nextUid = 1;

public:
    std::vector<std::shared_ptr<Object>> objects;
    std::vector<uint8_t> fontDataBlob; 
    std::vector<int> selectedUids; // Changed to vector to maintain order if needed, or use set

    void setFont(const uint8_t* data, int size);
    int add(std::shared_ptr<Object> obj);
    int findIndexByUid(int uid);
    Object* getObject(int uid);
    void render(uint32_t* buffer, int width, int height);
    void drawSelectionOutline(uint32_t* buffer, int w, int h, Object* obj);
    int pickHandle(int px, int py);
    int pick(int px, int py);

    // Selection
    void select(int uid, bool addToSelection);
    void deselect(int uid);
    void clearSelection();
    bool isSelected(int uid);
    int getPrimarySelection(); // Returns first selected or -1

    // Helpers
    void moveObject(int uid, int dx, int dy);
    void updateObjectRect(int uid, int nx, int ny, int nw, int nh);
    void updateObjectColor(int uid, uint32_t col);
    uint32_t getObjectColor(int uid);
    const char* getObjectText(int uid);
    void updateObjectText(int uid, const char* text);
    float getObjectFontSize(int uid);
    void updateObjectFontSize(int uid, float size);
    
    int getObjectCount() const;
    int getObjectUid(int index) const;
    const char* getObjectName(int index) const;
    int getObjectType(int index) const;
    void removeObject(int uid);
    void clear();
};
