#define STB_TRUETYPE_IMPLEMENTATION
#define STB_IMAGE_IMPLEMENTATION
#include "engine.h"
#include "core/scene.hpp"
#include "objects/rect_object.hpp"
#include "objects/text_object.hpp"
#include "objects/image_object.hpp"
#include "objects/ellipse_object.hpp"
#include "objects/line_object.hpp"
#include <memory>
#include <string>
#include <vector>
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <sstream>
#include <map>

// Native dependencies
#include "zip.h"
#include "tinyxml2.h"
#include "../deps/stb_image.h"

using namespace tinyxml2;

Scene g_scene;

// Helper to convert EMU (English Metric Units) to pixels
// 1 inch = 914400 EMUs. 
// Assuming 96 DPI for simplicity: 1 pixel = 914400 / 96 = 9525 EMUs
float emuToPixel(long long emu) {
    return (float)emu / 9525.0f;
}

// Parse color from PPTX XML (handles srgbClr, schemeClr with basic mapping)
uint32_t parseColor(XMLElement* parent, uint32_t defaultColor = 0xFFCCCCCC) {
    if (!parent) return defaultColor;
    
    // Direct RGB color
    XMLElement* srgbClr = parent->FirstChildElement("a:srgbClr");
    if (srgbClr) {
        const char* val = srgbClr->Attribute("val");
        if (val) {
            uint32_t rgb = (uint32_t)strtol(val, NULL, 16);
            return 0xFF000000 | rgb;
        }
    }
    
    // Scheme color (basic mapping)
    XMLElement* schemeClr = parent->FirstChildElement("a:schemeClr");
    if (schemeClr) {
        const char* val = schemeClr->Attribute("val");
        if (val) {
            std::string scheme = val;
            // Basic theme color mapping
            if (scheme == "tx1" || scheme == "dk1") return 0xFF000000;
            if (scheme == "tx2" || scheme == "dk2") return 0xFF444444;
            if (scheme == "bg1" || scheme == "lt1") return 0xFFFFFFFF;
            if (scheme == "bg2" || scheme == "lt2") return 0xFFEEEEEE;
            if (scheme == "accent1") return 0xFF4472C4;
            if (scheme == "accent2") return 0xFFED7D31;
            if (scheme == "accent3") return 0xFFA5A5A5;
            if (scheme == "accent4") return 0xFFFFC000;
            if (scheme == "accent5") return 0xFF5B9BD5;
            if (scheme == "accent6") return 0xFF70AD47;
        }
    }
    
    return defaultColor;
}

// Detect shape type from preset geometry
std::string detectShapeType(XMLElement* spPr) {
    if (!spPr) return "rect";
    
    XMLElement* prstGeom = spPr->FirstChildElement("a:prstGeom");
    if (prstGeom) {
        const char* prst = prstGeom->Attribute("prst");
        if (prst) {
            std::string preset = prst;
            if (preset == "ellipse" || preset == "oval") return "ellipse";
            if (preset == "line") return "line";
            if (preset == "roundRect") return "roundRect";
            if (preset == "triangle" || preset == "rtTriangle") return "triangle";
            // More presets can be added
            return preset;
        }
    }
    
    return "rect"; // Default
}

void engine_init(int32_t, int32_t) {
    g_scene.clear();
}

// Cache for loaded images from PPTX
std::map<std::string, std::vector<uint32_t>> g_imageCache;
std::map<std::string, std::pair<int, int>> g_imageSizes;

// Helper to extract and decode image from PPTX
bool loadImageFromPptx(struct zip_t* zip, const std::string& imagePath, 
                       std::vector<uint32_t>& outPixels, int& outW, int& outH) {
    // Check cache first
    if (g_imageCache.find(imagePath) != g_imageCache.end()) {
        outPixels = g_imageCache[imagePath];
        auto& sz = g_imageSizes[imagePath];
        outW = sz.first;
        outH = sz.second;
        return true;
    }

    if (zip_entry_open(zip, imagePath.c_str()) < 0) {
        return false;
    }

    void* imgData = NULL;
    size_t imgSize = 0;
    
    if (zip_entry_read(zip, &imgData, &imgSize) < 0) {
        zip_entry_close(zip);
        return false;
    }
    zip_entry_close(zip);

    // Decode image using stb_image
    int w, h, channels;
    unsigned char* pixels = stbi_load_from_memory(
        (const unsigned char*)imgData, (int)imgSize,
        &w, &h, &channels, 4); // Force RGBA

    free(imgData);

    if (!pixels) {
        return false;
    }

    // Convert RGBA to BGRA (Windows bitmap format)
    outPixels.resize(w * h);
    for (int i = 0; i < w * h; i++) {
        unsigned char r = pixels[i * 4 + 0];
        unsigned char g = pixels[i * 4 + 1];
        unsigned char b = pixels[i * 4 + 2];
        unsigned char a = pixels[i * 4 + 3];
        outPixels[i] = (a << 24) | (r << 16) | (g << 8) | b;
    }

    stbi_image_free(pixels);

    outW = w;
    outH = h;

    // Cache for later use
    g_imageCache[imagePath] = outPixels;
    g_imageSizes[imagePath] = {w, h};

    return true;
}

// Parse relationship file to get image references
std::map<std::string, std::string> parseRelationships(struct zip_t* zip, int slideNum) {
    std::map<std::string, std::string> rels;
    
    std::ostringstream relPath;
    relPath << "ppt/slides/_rels/slide" << slideNum << ".xml.rels";
    
    if (zip_entry_open(zip, relPath.str().c_str()) < 0) {
        return rels;
    }

    void* relData = NULL;
    size_t relSize = 0;
    
    if (zip_entry_read(zip, &relData, &relSize) < 0) {
        zip_entry_close(zip);
        return rels;
    }
    zip_entry_close(zip);

    XMLDocument doc;
    if (doc.Parse((const char*)relData, relSize) == XML_SUCCESS) {
        XMLElement* root = doc.FirstChildElement("Relationships");
        if (root) {
            for (XMLElement* rel = root->FirstChildElement("Relationship"); 
                 rel; 
                 rel = rel->NextSiblingElement("Relationship")) {
                const char* id = rel->Attribute("Id");
                const char* target = rel->Attribute("Target");
                if (id && target) {
                    std::string targetStr = target;
                    // Convert relative path to absolute
                    if (targetStr.find("../") == 0) {
                        targetStr = "ppt/" + targetStr.substr(3);
                    }
                    rels[id] = targetStr;
                }
            }
        }
    }

    free(relData);
    return rels;
}

void engine_import_pptx(const char* filepath) {
    struct zip_t* zip = zip_open(filepath, 0, 'r');
    if (!zip) {
        printf("Error: Could not open PPTX (ZIP) file: %s\n", filepath);
        return;
    }

    g_scene.clear();
    g_imageCache.clear();
    g_imageSizes.clear();

    // Find all slides
    for (int slideNum = 1; slideNum <= 100; ++slideNum) {
        std::ostringstream slidePath;
        slidePath << "ppt/slides/slide" << slideNum << ".xml";
        
        if (zip_entry_open(zip, slidePath.str().c_str()) < 0) {
            break; // No more slides
        }

        void* pSlideData = NULL;
        size_t uncompressed_size = 0;
        
        if (zip_entry_read(zip, &pSlideData, &uncompressed_size) < 0) {
            zip_entry_close(zip);
            continue;
        }
        zip_entry_close(zip);

        // Parse relationships for this slide
        auto rels = parseRelationships(zip, slideNum);

        // Parse XML
        XMLDocument doc;
        if (doc.Parse((const char*)pSlideData, uncompressed_size) == XML_SUCCESS) {
            XMLElement* sld = doc.FirstChildElement("p:sld");
            if (sld) {
                XMLElement* cSld = sld->FirstChildElement("p:cSld");
                if (cSld) {
                    XMLElement* spTree = cSld->FirstChildElement("p:spTree");
                    if (spTree) {
                        // Iterate through all shapes
                        for (XMLElement* element = spTree->FirstChildElement(); 
                             element; 
                             element = element->NextSiblingElement()) {
                            
                            const char* rawName = element->Name();
                            std::string elName = rawName ? rawName : "";
                            
                            // Shape: <p:sp>
                            if (elName == "p:sp") {
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

                                // Get color from solidFill
                                uint32_t color = 0xFFCCCCCC;
                                if (spPr) {
                                    XMLElement* solidFill = spPr->FirstChildElement("a:solidFill");
                                    if (solidFill) {
                                        color = parseColor(solidFill);
                                    }
                                }

                                // Detect shape type
                                std::string shapeType = detectShapeType(spPr);
                                int newId = (int)g_scene.objects.size() + 1;
                                
                                if (shapeType == "ellipse") {
                                    g_scene.add(std::make_shared<EllipseObject>(
                                        newId, (int)x, (int)y, (int)w, (int)h, color));
                                } else if (shapeType == "line") {
                                    g_scene.add(std::make_shared<LineObject>(
                                        newId, (int)x, (int)y, (int)(x + w), (int)(y + h), color, 3));
                                } else {
                                    // Default to rectangle
                                    g_scene.add(std::make_shared<RectangleObject>(
                                        newId, (int)x, (int)y, (int)w, (int)h, color));
                                }

                                // Extract text if present
                                XMLElement* txBody = element->FirstChildElement("p:txBody");
                                if (txBody) {
                                    std::string fullText = "";
                                    float fontSize = 24.0f;
                                    uint32_t textColor = 0xFF000000;
                                    
                                    for (XMLElement* p = txBody->FirstChildElement("a:p"); p; p = p->NextSiblingElement("a:p")) {
                                        for (XMLElement* r = p->FirstChildElement("a:r"); r; r = r->NextSiblingElement("a:r")) {
                                            // Get run properties for font size
                                            XMLElement* rPr = r->FirstChildElement("a:rPr");
                                            if (rPr) {
                                                const char* sz = rPr->Attribute("sz");
                                                if (sz) {
                                                    fontSize = atof(sz) / 100.0f; // Size in hundredths of a point
                                                }
                                                // Get text color
                                                XMLElement* solidFill = rPr->FirstChildElement("a:solidFill");
                                                if (solidFill) {
                                                    textColor = parseColor(solidFill, 0xFF000000);
                                                }
                                            }
                                            
                                            XMLElement* t = r->FirstChildElement("a:t");
                                            if (t && t->GetText()) {
                                                fullText += t->GetText();
                                            }
                                        }
                                        fullText += "\n";
                                    }

                                    if (!fullText.empty()) {
                                        if (fullText.back() == '\n') fullText.pop_back();

                                        int textId = (int)g_scene.objects.size() + 1;
                                        g_scene.add(std::make_shared<TextObject>(
                                            textId,
                                            (int)(x + 10), (int)(y + 10),
                                            fullText.c_str(),
                                            textColor,
                                            fontSize > 8 ? fontSize : 24.0f
                                        ));
                                    }
                                }
                            }
                            // Picture: <p:pic>
                            else if (elName == "p:pic") {
                                float x = 0, y = 0, w = 100, h = 100;
                                std::string imageRelId;

                                // Get image reference
                                XMLElement* blipFill = element->FirstChildElement("p:blipFill");
                                if (blipFill) {
                                    XMLElement* blip = blipFill->FirstChildElement("a:blip");
                                    if (blip) {
                                        const char* embed = blip->Attribute("r:embed");
                                        if (embed) imageRelId = embed;
                                    }
                                }

                                XMLElement* spPr = element->FirstChildElement("p:spPr");
                                if (spPr) {
                                    XMLElement* xfrm = spPr->FirstChildElement("a:xfrm");
                                    if (xfrm) {
                                        XMLElement* off = xfrm->FirstChildElement("a:off");
                                        XMLElement* ext = xfrm->FirstChildElement("a:ext");
                                        if (off) {
                                            if (off->Attribute("x")) x = emuToPixel(atoll(off->Attribute("x")));
                                            if (off->Attribute("y")) y = emuToPixel(atoll(off->Attribute("y")));
                                        }
                                        if (ext) {
                                            if (ext->Attribute("cx")) w = emuToPixel(atoll(ext->Attribute("cx")));
                                            if (ext->Attribute("cy")) h = emuToPixel(atoll(ext->Attribute("cy")));
                                        }
                                    }
                                }

                                int picId = (int)g_scene.objects.size() + 1;
                                
                                // Try to load the actual image
                                if (!imageRelId.empty() && rels.find(imageRelId) != rels.end()) {
                                    std::string imagePath = rels[imageRelId];
                                    std::vector<uint32_t> pixels;
                                    int imgW, imgH;
                                    
                                    if (loadImageFromPptx(zip, imagePath, pixels, imgW, imgH)) {
                                        g_scene.add(std::make_shared<ImageObject>(
                                            picId, (int)x, (int)y, (int)w, (int)h,
                                            pixels.data(), imgW, imgH));
                                        continue;
                                    }
                                }
                                
                                // Fallback: placeholder rectangle
                                g_scene.add(std::make_shared<RectangleObject>(
                                    picId, (int)x, (int)y, (int)w, (int)h, 0xFF888888));
                            }
                            // Group: <p:grpSp>
                            else if (elName == "p:grpSp") {
                                // TODO: Recursively parse group shapes
                                // For now, skip groups
                            }
                        }
                    }
                }
            }
        }

        if (pSlideData) free(pSlideData);
    }

    zip_close(zip);
    printf("PPTX imported successfully: %zu objects created\n", g_scene.objects.size());
}

void engine_render(uint32_t* buffer, int32_t width, int32_t height) {
    g_scene.render(buffer, width, height);
}

int32_t engine_add_rect(int32_t x, int32_t y, int32_t w, int32_t h, uint32_t color) {
    int id = g_scene.objects.size() + 1;
    g_scene.add(std::make_shared<RectangleObject>(id, x, y, w, h, color));
    return id;
}

int32_t engine_add_ellipse(int32_t x, int32_t y, int32_t w, int32_t h, uint32_t color) {
    int id = g_scene.objects.size() + 1;
    g_scene.add(std::make_shared<EllipseObject>(id, x, y, w, h, color));
    return id;
}

int32_t engine_add_line(int32_t x1, int32_t y1, int32_t x2, int32_t y2, uint32_t color, int32_t thickness) {
    int id = g_scene.objects.size() + 1;
    g_scene.add(std::make_shared<LineObject>(id, x1, y1, x2, y2, color, thickness));
    return id;
}

void engine_load_font(const uint8_t* data, int32_t length) {
    g_scene.setFont(data, length);
}

int32_t engine_add_text(int32_t x, int32_t y, const char* text, uint32_t color, float size) {
    int id = g_scene.objects.size() + 1;
    g_scene.add(std::make_shared<TextObject>(id, x, y, text, color, size));
    return id;
}

int32_t engine_add_image(int32_t x, int32_t y, int32_t w, int32_t h, const uint32_t* pixels, int32_t imgW, int32_t imgH) {
    int id = g_scene.objects.size() + 1;
    g_scene.add(std::make_shared<ImageObject>(id, x, y, w, h, pixels, imgW, imgH));
    return id;
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
    return g_scene.getPrimarySelection();
}

void engine_remove_object(int32_t id) {
    g_scene.removeObject(id);
}

void engine_select_object(int32_t id) {
    g_scene.select(id, false); // Default to single selection exclusive
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
