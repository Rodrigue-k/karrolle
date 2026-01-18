#define STB_TRUETYPE_IMPLEMENTATION
#include "engine.h"
#include "core/scene.hpp"
#include "objects/rect_object.hpp"
#include "objects/text_object.hpp"
#include "objects/image_object.hpp"
#include <memory>
#include <string>
#include <vector>
#include <iostream>
#include <cstdlib>
#include <cstring>

// Native dependencies
#include "zip.h"
#include "tinyxml2.h"

using namespace tinyxml2;

Scene g_scene;

// Helper to convert EMU (English Metric Units) to pixels
// 1 inch = 914400 EMUs. 
// Assuming 96 DPI for simplicity: 1 pixel = 914400 / 96 = 9525 EMUs
float emuToPixel(long long emu) {
    return (float)emu / 9525.0f;
}

void engine_init(int32_t, int32_t) {
    g_scene.clear();
}

void engine_import_pptx(const char* filepath) {
    struct zip_t* zip = zip_open(filepath, 0, 'r');
    if (!zip) {
        printf("Error: Could not open PPTX (ZIP) file: %s\n", filepath);
        return;
    }

    // For now, let's just try to read Slide 1
    const char* slidePath = "ppt/slides/slide1.xml";
    if (zip_entry_open(zip, slidePath) < 0) {
        printf("Error: Could not find %s in archive.\n", slidePath);
        zip_close(zip);
        return;
    }

    void* pSlideData = NULL;
    size_t uncompressed_size = 0;
    // zip_entry_read allocates memory for us into pSlideData
    if (zip_entry_read(zip, &pSlideData, &uncompressed_size) < 0) {
        printf("Error: Could not read %s from archive.\n", slidePath);
        zip_entry_close(zip);
        zip_close(zip);
        return;
    }
    zip_entry_close(zip);

    // Parse XML
    XMLDocument doc;
    if (doc.Parse((const char*)pSlideData, uncompressed_size) == XML_SUCCESS) {
        g_scene.clear();

        // Navigate to <p:sld> -> <p:cSld> -> <p:spTree>
        XMLElement* sld = doc.FirstChildElement("p:sld");
        if (sld) {
            XMLElement* cSld = sld->FirstChildElement("p:cSld");
            if (cSld) {
                XMLElement* spTree = cSld->FirstChildElement("p:spTree");
                if (spTree) {
                    // Iterate through children of spTree (shapes)
                    for (XMLElement* element = spTree->FirstChildElement(); element; element = element->NextSiblingElement()) {
                        const char* rawName = element->Name();
                        std::string elName = rawName ? rawName : "";
                        
                        // Shape: <p:sp>
                        if (elName == "p:sp") {
                            // 1. Get Transform (Geometry + Position)
                            XMLElement* spPr = element->FirstChildElement("p:spPr");
                            float x = 0, y = 0, w = 100, h = 100;
                            if (spPr) {
                                XMLElement* xfrm = spPr->FirstChildElement("a:xfrm");
                                if (xfrm) {
                                    XMLElement* off = xfrm->FirstChildElement("a:off");
                                    if (off) {
                                        if (off->Attribute("x")) x = emuToPixel(atoll(off->Attribute("x")));
                                        if (off->Attribute("y")) y = emuToPixel(atoll(off->Attribute("y")));
                                    }
                                    XMLElement* ext = xfrm->FirstChildElement("a:ext");
                                    if (ext) {
                                        if (ext->Attribute("cx")) w = emuToPixel(atoll(ext->Attribute("cx")));
                                        if (ext->Attribute("cy")) h = emuToPixel(atoll(ext->Attribute("cy")));
                                    }
                                }
                            }

                            // 2. Get Color
                            uint32_t color = 0xFFCCCCCC; // Default
                            if (spPr) {
                                XMLElement* solidFill = spPr->FirstChildElement("a:solidFill");
                                if (solidFill) {
                                    XMLElement* srgbClr = solidFill->FirstChildElement("a:srgbClr");
                                    if (srgbClr) {
                                        const char* val = srgbClr->Attribute("val");
                                        if (val) {
                                            uint32_t rgb = (uint32_t)strtol(val, NULL, 16);
                                            // PPTX colors are often just RGB, need full alpha
                                            color = 0xFF000000 | rgb;
                                        }
                                    }
                                }
                            }

                            // Add the rectangle
                            // Note: We use size() + 1 as ID generator logic is inside Scene but manual add needs ID
                            int newId = (int)g_scene.objects.size() + 1;
                            g_scene.add(std::make_shared<RectangleObject>(newId, (int)x, (int)y, (int)w, (int)h, color));

                            // 3. Get Text
                            XMLElement* txBody = element->FirstChildElement("p:txBody");
                            if (txBody) {
                                std::string fullText = "";
                                for (XMLElement* p = txBody->FirstChildElement("a:p"); p; p = p->NextSiblingElement("a:p")) {
                                    for (XMLElement* r = p->FirstChildElement("a:r"); r; r = r->NextSiblingElement("a:r")) {
                                        XMLElement* t = r->FirstChildElement("a:t");
                                        if (t && t->GetText()) {
                                            fullText += t->GetText();
                                        }
                                    }
                                    fullText += "\n";
                                }

                                if (!fullText.empty()) {
                                    // Strip last newline
                                    if (fullText.back() == '\n') fullText.pop_back();

                                    int textId = (int)g_scene.objects.size() + 1;
                                    g_scene.add(std::make_shared<TextObject>(
                                        textId,
                                        (int)(x + 5), (int)(y + 5),
                                        fullText.c_str(),
                                        0xFF000000,
                                        24.0f
                                    ));
                                }
                            }
                        }
                        // Picture: <p:pic>
                        else if (elName == "p:pic") {
                            // Just a placeholder for now
                             XMLElement* spPr = element->FirstChildElement("p:spPr");
                             if (spPr) {
                                 XMLElement* xfrm = spPr->FirstChildElement("a:xfrm");
                                 if (xfrm) {
                                     XMLElement* off = xfrm->FirstChildElement("a:off");
                                     XMLElement* ext = xfrm->FirstChildElement("a:ext");
                                     if (off && ext) {
                                         float x = 0, y = 0, w = 100, h = 100;
                                         if (off->Attribute("x")) x = emuToPixel(atoll(off->Attribute("x")));
                                         if (off->Attribute("y")) y = emuToPixel(atoll(off->Attribute("y")));
                                         if (ext->Attribute("cx")) w = emuToPixel(atoll(ext->Attribute("cx")));
                                         if (ext->Attribute("cy")) h = emuToPixel(atoll(ext->Attribute("cy")));
                                         
                                         int picId = (int)g_scene.objects.size() + 1;
                                         g_scene.add(std::make_shared<RectangleObject>(picId, (int)x, (int)y, (int)w, (int)h, 0xFF00FF00));
                                     }
                                 }
                             }
                        }
                    }
                }
            }
        }
    }

    if (pSlideData) free(pSlideData);
    zip_close(zip);
}

void engine_render(uint32_t* buffer, int32_t width, int32_t height) {
    g_scene.render(buffer, width, height);
}

void engine_add_rect(int32_t x, int32_t y, int32_t w, int32_t h, uint32_t color) {
    int id = g_scene.objects.size() + 1; 
    // Actually Scene::add should handle ID if passed -1 or similar, but Object ctor takes ID.
    // We'll trust simple increment for now or let Scene manage if we change Object ctor.
    // Current Scene doesn't auto-assign ID in add(), it assumes Object has ID.
    // But Scene::nextUid exists... let's check scene.cpp if I can.
    // For now, just generate ID here.
    g_scene.add(std::make_shared<RectangleObject>(id, x, y, w, h, color));
}

void engine_load_font(const uint8_t* data, int32_t length) {
    g_scene.setFont(data, length);
}

void engine_add_text(int32_t x, int32_t y, const char* text, uint32_t color, float size) {
    int id = g_scene.objects.size() + 1;
    g_scene.add(std::make_shared<TextObject>(id, x, y, text, color, size));
}

void engine_add_image(int32_t x, int32_t y, int32_t w, int32_t h, const uint32_t* pixels, int32_t imgW, int32_t imgH) {
    int id = g_scene.objects.size() + 1;
    g_scene.add(std::make_shared<ImageObject>(id, x, y, w, h, pixels, imgW, imgH));
}

int32_t engine_pick(int32_t x, int32_t y) {
    return g_scene.pick(x, y);
}

int32_t engine_pick_handle(int32_t x, int32_t y) {
    return g_scene.pickHandle(x, y);
}

void engine_move_object(int32_t id, int32_t dx, int32_t dy) {
    g_scene.moveObject(id, dx, dy);
}

int32_t engine_get_selected_id() {
    return g_scene.selectedUid;
}

void engine_remove_object(int32_t id) {
    g_scene.removeObject(id);
}

void engine_select_object(int32_t id) {
    if (g_scene.findIndexByUid(id) != -1) {
        g_scene.selectedUid = id;
    } else {
        g_scene.selectedUid = -1;
    }
}

void engine_get_object_bounds(int32_t id, int32_t* x, int32_t* y, int32_t* w, int32_t* h) {
    Object* obj = g_scene.getObject(id);
    if (obj) {
        if (x) *x = obj->x;
        if (y) *y = obj->y;
        if (w) *w = obj->w;
        if (h) *h = obj->h;
    }
}

void engine_set_object_rect(int32_t id, int32_t x, int32_t y, int32_t w, int32_t h) {
    g_scene.updateObjectRect(id, x, y, w, h);
}

void engine_set_object_color(int32_t id, uint32_t color) {
    g_scene.updateObjectColor(id, color);
}

uint32_t engine_get_object_color(int32_t id) {
    return g_scene.getObjectColor(id);
}

int32_t engine_get_object_count() {
    return g_scene.getObjectCount();
}

const char* engine_get_object_name(int32_t index) {
    return g_scene.getObjectName(index);
}

int32_t engine_get_object_type(int32_t index) {
    return g_scene.getObjectType(index);
}

int32_t engine_get_object_uid(int32_t index) {
    return g_scene.getObjectUid(index);
}

const char* engine_get_object_text(int32_t id) {
    return g_scene.getObjectText(id);
}

void engine_set_object_text(int32_t id, const char* text) {
    g_scene.updateObjectText(id, text);
}

float engine_get_object_font_size(int32_t id) {
    return g_scene.getObjectFontSize(id);
}

void engine_set_object_font_size(int32_t id, float size) {
    g_scene.updateObjectFontSize(id, size);
}
