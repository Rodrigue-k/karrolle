import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:karrolle/core/logger/app_logger.dart';

// --- FFI Typedefs ---

// Engine Init
typedef EngineInitC = Void Function(Int32 width, Int32 height);
typedef EngineInitDart = void Function(int width, int height);

// Render
typedef EngineRenderC =
    Void Function(Pointer<Uint32> buffer, Int32 width, Int32 height);
typedef EngineRenderDart =
    void Function(Pointer<Uint32> buffer, int width, int height);

// Add Objects
typedef EngineAddRectC =
    Void Function(Int32 x, Int32 y, Int32 w, Int32 h, Uint32 color);
typedef EngineAddRectDart =
    void Function(int x, int y, int w, int h, int color);

typedef EngineAddEllipseC =
    Void Function(Int32 x, Int32 y, Int32 w, Int32 h, Uint32 color);
typedef EngineAddEllipseDart =
    void Function(int x, int y, int w, int h, int color);

typedef EngineAddLineC =
    Void Function(
      Int32 x1,
      Int32 y1,
      Int32 x2,
      Int32 y2,
      Uint32 color,
      Int32 thickness,
    );
typedef EngineAddLineDart =
    void Function(int x1, int y1, int x2, int y2, int color, int thickness);

typedef EngineAddTextC =
    Void Function(
      Int32 x,
      Int32 y,
      Pointer<Utf8> text,
      Uint32 color,
      Float size,
    );
typedef EngineAddTextDart =
    void Function(int x, int y, Pointer<Utf8> text, int color, double size);

typedef EngineAddImageC =
    Void Function(
      Int32 x,
      Int32 y,
      Int32 w,
      Int32 h,
      Pointer<Uint32> pixels,
      Int32 imgW,
      Int32 imgH,
    );
typedef EngineAddImageDart =
    void Function(
      int x,
      int y,
      int w,
      int h,
      Pointer<Uint32> pixels,
      int imgW,
      int imgH,
    );

// Font
typedef EngineLoadFontC = Void Function(Pointer<Uint8> data, Int32 length);
typedef EngineLoadFontDart = void Function(Pointer<Uint8> data, int length);

// Import
typedef EngineImportPptxC = Void Function(Pointer<Utf8> filepath);
typedef EngineImportPptxDart = void Function(Pointer<Utf8> filepath);

// Interaction (Pick / Move / Update)
typedef EnginePickC = Int32 Function(Int32 x, Int32 y);
typedef EnginePickDart = int Function(int x, int y);

typedef EngineMoveObjectC = Void Function(Int32 id, Int32 dx, Int32 dy);
typedef EngineMoveObjectDart = void Function(int id, int dx, int dy);

typedef EngineSetObjectRectC =
    Void Function(Int32 id, Int32 x, Int32 y, Int32 w, Int32 h);
typedef EngineSetObjectRectDart =
    void Function(int id, int x, int y, int w, int h);

typedef EngineSetObjectColorC = Void Function(Int32 id, Uint32 color);
typedef EngineSetObjectColorDart = void Function(int id, int color);

// Inspection
typedef EngineGetSelectedIdC = Int32 Function();
typedef EngineGetSelectedIdDart = int Function();

typedef EngineRemoveObjectC = Void Function(Int32 id);
typedef EngineRemoveObjectDart = void Function(int id);

typedef EngineSelectObjectC = Void Function(Int32 id);
typedef EngineSelectObjectDart = void Function(int id);

typedef EnginePickHandleC = Int32 Function(Int32 x, Int32 y);
typedef EnginePickHandleDart = int Function(int x, int y);

typedef EngineGetObjectUidC = Int32 Function(Int32 index);
typedef EngineGetObjectUidDart = int Function(int index);

typedef EngineGetObjectBoundsC =
    Void Function(
      Int32 id,
      Pointer<Int32> x,
      Pointer<Int32> y,
      Pointer<Int32> w,
      Pointer<Int32> h,
    );
typedef EngineGetObjectBoundsDart =
    void Function(
      int id,
      Pointer<Int32> x,
      Pointer<Int32> y,
      Pointer<Int32> w,
      Pointer<Int32> h,
    );

typedef EngineGetObjectColorC = Uint32 Function(Int32 id);
typedef EngineGetObjectColorDart = int Function(int id);

typedef EngineGetObjectCountC = Int32 Function();
typedef EngineGetObjectCountDart = int Function();

typedef EngineGetObjectNameC = Pointer<Utf8> Function(Int32 index);
typedef EngineGetObjectNameDart = Pointer<Utf8> Function(int index);

typedef EngineGetObjectTypeC = Int32 Function(Int32 index);
typedef EngineGetObjectTypeDart = int Function(int index);

typedef EngineGetObjectTextC = Pointer<Utf8> Function(Int32 id);
typedef EngineGetObjectTextDart = Pointer<Utf8> Function(int id);

typedef EngineSetObjectTextC = Void Function(Int32 id, Pointer<Utf8> text);
typedef EngineSetObjectTextDart = void Function(int id, Pointer<Utf8> text);

typedef EngineGetObjectFontSizeC = Float Function(Int32 id);
typedef EngineGetObjectFontSizeDart = double Function(int id);

typedef EngineSetObjectFontSizeC = Void Function(Int32 id, Float size);
typedef EngineSetObjectFontSizeDart = void Function(int id, double size);

class NativeApi {
  static late DynamicLibrary _lib;
  static bool _initialized = false;

  // --- Function Pointers ---
  static late EngineInitDart _engineInit;
  static late EngineRenderDart _engineRender;
  static late EngineAddRectDart _engineAddRect;
  static late EngineAddEllipseDart _engineAddEllipse;
  static late EngineAddLineDart _engineAddLine;
  static late EngineAddTextDart _engineAddText;
  static late EngineAddImageDart _engineAddImage;
  static late EngineLoadFontDart _engineLoadFont;
  static late EngineImportPptxDart _engineImportPptx;
  static late EnginePickDart _enginePick;
  static late EnginePickHandleDart _enginePickHandle;
  static late EngineMoveObjectDart _engineMoveObject;
  static late EngineSetObjectRectDart _engineSetObjectRect;
  static late EngineSetObjectColorDart _engineSetObjectColor;
  static late EngineGetSelectedIdDart _engineGetSelectedId;
  static late EngineRemoveObjectDart _engineRemoveObject;
  static late EngineSelectObjectDart _engineSelectObject;
  static late EngineGetObjectUidDart _engineGetObjectUid;
  static late EngineGetObjectBoundsDart _engineGetObjectBounds;
  static late EngineGetObjectColorDart _engineGetObjectColor;
  static late EngineGetObjectCountDart _engineGetObjectCount;
  static late EngineGetObjectNameDart _engineGetObjectName;
  static late EngineGetObjectTypeDart _engineGetObjectType;
  static late EngineGetObjectTextDart _engineGetObjectText;
  static late EngineSetObjectTextDart _engineSetObjectText;
  static late EngineGetObjectFontSizeDart _engineGetObjectFontSize;
  static late EngineSetObjectFontSizeDart _engineSetObjectFontSize;

  static void initialize() {
    if (_initialized) return;

    try {
      if (Platform.isWindows) {
        // Standard loading since we aren't using Aspose dependencies
        _lib = DynamicLibrary.open('engine.dll');
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      // Lookups
      _engineInit = _lib.lookupFunction<EngineInitC, EngineInitDart>(
        'engine_init',
      );
      _engineRender = _lib.lookupFunction<EngineRenderC, EngineRenderDart>(
        'engine_render',
      );
      _engineAddRect = _lib.lookupFunction<EngineAddRectC, EngineAddRectDart>(
        'engine_add_rect',
      );
      _engineAddEllipse = _lib
          .lookupFunction<EngineAddEllipseC, EngineAddEllipseDart>(
            'engine_add_ellipse',
          );
      _engineAddLine = _lib.lookupFunction<EngineAddLineC, EngineAddLineDart>(
        'engine_add_line',
      );
      _engineAddText = _lib.lookupFunction<EngineAddTextC, EngineAddTextDart>(
        'engine_add_text',
      );
      _engineAddImage = _lib
          .lookupFunction<EngineAddImageC, EngineAddImageDart>(
            'engine_add_image',
          );
      _engineLoadFont = _lib
          .lookupFunction<EngineLoadFontC, EngineLoadFontDart>(
            'engine_load_font',
          );
      _engineImportPptx = _lib
          .lookupFunction<EngineImportPptxC, EngineImportPptxDart>(
            'engine_import_pptx',
          );
      _enginePick = _lib.lookupFunction<EnginePickC, EnginePickDart>(
        'engine_pick',
      );
      _enginePickHandle = _lib
          .lookupFunction<EnginePickHandleC, EnginePickHandleDart>(
            'engine_pick_handle',
          );
      _engineMoveObject = _lib
          .lookupFunction<EngineMoveObjectC, EngineMoveObjectDart>(
            'engine_move_object',
          );
      _engineSetObjectRect = _lib
          .lookupFunction<EngineSetObjectRectC, EngineSetObjectRectDart>(
            'engine_set_object_rect',
          );
      _engineSetObjectColor = _lib
          .lookupFunction<EngineSetObjectColorC, EngineSetObjectColorDart>(
            'engine_set_object_color',
          );
      _engineGetSelectedId = _lib
          .lookupFunction<EngineGetSelectedIdC, EngineGetSelectedIdDart>(
            'engine_get_selected_id',
          );
      _engineRemoveObject = _lib
          .lookupFunction<EngineRemoveObjectC, EngineRemoveObjectDart>(
            'engine_remove_object',
          );
      _engineSelectObject = _lib
          .lookupFunction<EngineSelectObjectC, EngineSelectObjectDart>(
            'engine_select_object',
          );
      _engineGetObjectUid = _lib
          .lookupFunction<EngineGetObjectUidC, EngineGetObjectUidDart>(
            'engine_get_object_uid',
          );
      _engineGetObjectBounds = _lib
          .lookupFunction<EngineGetObjectBoundsC, EngineGetObjectBoundsDart>(
            'engine_get_object_bounds',
          );
      _engineGetObjectColor = _lib
          .lookupFunction<EngineGetObjectColorC, EngineGetObjectColorDart>(
            'engine_get_object_color',
          );
      _engineGetObjectCount = _lib
          .lookupFunction<EngineGetObjectCountC, EngineGetObjectCountDart>(
            'engine_get_object_count',
          );
      _engineGetObjectName = _lib
          .lookupFunction<EngineGetObjectNameC, EngineGetObjectNameDart>(
            'engine_get_object_name',
          );
      _engineGetObjectType = _lib
          .lookupFunction<EngineGetObjectTypeC, EngineGetObjectTypeDart>(
            'engine_get_object_type',
          );
      _engineGetObjectText = _lib
          .lookupFunction<EngineGetObjectTextC, EngineGetObjectTextDart>(
            'engine_get_object_text',
          );
      _engineSetObjectText = _lib
          .lookupFunction<EngineSetObjectTextC, EngineSetObjectTextDart>(
            'engine_set_object_text',
          );
      _engineGetObjectFontSize = _lib
          .lookupFunction<
            EngineGetObjectFontSizeC,
            EngineGetObjectFontSizeDart
          >('engine_get_object_font_size');
      _engineSetObjectFontSize = _lib
          .lookupFunction<
            EngineSetObjectFontSizeC,
            EngineSetObjectFontSizeDart
          >('engine_set_object_font_size');

      _initialized = true;
      AppLog.i('Native Engine API initialized');
    } catch (e) {
      AppLog.e('Failed to load native library', e);
      rethrow;
    }
  }

  // --- Public Methods ---

  static void initEngine(int width, int height) {
    if (!_initialized) initialize();
    _engineInit(width, height);
  }

  static void render(Pointer<Uint32> buffer, int width, int height) {
    if (!_initialized) initialize();
    _engineRender(buffer, width, height);
  }

  static void addRect(int x, int y, int w, int h, int color) {
    if (!_initialized) initialize();
    _engineAddRect(x, y, w, h, color);
  }

  static void addEllipse(int x, int y, int w, int h, int color) {
    if (!_initialized) initialize();
    _engineAddEllipse(x, y, w, h, color);
  }

  static void addLine(
    int x1,
    int y1,
    int x2,
    int y2,
    int color, {
    int thickness = 2,
  }) {
    if (!_initialized) initialize();
    _engineAddLine(x1, y1, x2, y2, color, thickness);
  }

  static void addText(int x, int y, String text, int color, double size) {
    if (!_initialized) initialize();
    final textPtr = text.toNativeUtf8();
    _engineAddText(x, y, textPtr, color, size);
    calloc.free(textPtr);
  }

  static void addImage(
    int x,
    int y,
    int w,
    int h,
    Uint32List pixels,
    int imgW,
    int imgH,
  ) {
    if (!_initialized) initialize();
    final ptr = calloc<Uint32>(pixels.length);
    ptr.asTypedList(pixels.length).setAll(0, pixels);
    _engineAddImage(x, y, w, h, ptr, imgW, imgH);
    calloc.free(ptr);
  }

  static void loadFont(Uint8List data) {
    if (!_initialized) initialize();
    final ptr = calloc<Uint8>(data.length);
    final list = ptr.asTypedList(data.length);
    list.setAll(0, data);
    _engineLoadFont(ptr, data.length);
    calloc.free(ptr);
  }

  static void importPptx(String filepath) {
    if (!_initialized) initialize();
    final ptr = filepath.toNativeUtf8();
    _engineImportPptx(ptr);
    calloc.free(ptr);
  }

  static int pick(int x, int y) {
    if (!_initialized) initialize();
    return _enginePick(x, y);
  }

  static int pickHandle(int x, int y) {
    if (!_initialized) initialize();
    return _enginePickHandle(x, y);
  }

  static void moveObject(int id, int dx, int dy) {
    if (!_initialized) initialize();
    _engineMoveObject(id, dx, dy);
  }

  static void setObjectRect(int id, int x, int y, int w, int h) {
    if (!_initialized) initialize();
    _engineSetObjectRect(id, x, y, w, h);
  }

  static void setObjectColor(int id, int color) {
    if (!_initialized) initialize();
    _engineSetObjectColor(id, color);
  }

  static int getSelectedId() {
    if (!_initialized) initialize();
    return _engineGetSelectedId();
  }

  static void removeObject(int id) {
    if (!_initialized) initialize();
    _engineRemoveObject(id);
  }

  static void selectObject(int id) {
    if (!_initialized) initialize();
    _engineSelectObject(id);
  }

  static int getObjectUid(int index) {
    if (!_initialized) initialize();
    return _engineGetObjectUid(index);
  }

  static void getObjectBounds(
    int id,
    Pointer<Int32> x,
    Pointer<Int32> y,
    Pointer<Int32> w,
    Pointer<Int32> h,
  ) {
    if (!_initialized) initialize();
    _engineGetObjectBounds(id, x, y, w, h);
  }

  static int getObjectColor(int id) {
    if (!_initialized) initialize();
    return _engineGetObjectColor(id);
  }

  static int getObjectCount() {
    if (!_initialized) initialize();
    return _engineGetObjectCount();
  }

  static String getObjectName(int index) {
    if (!_initialized) initialize();
    final ptr = _engineGetObjectName(index);
    return ptr.toDartString();
  }

  static int getObjectType(int index) {
    if (!_initialized) initialize();
    return _engineGetObjectType(index);
  }

  static String getObjectText(int id) {
    if (!_initialized) initialize();
    final ptr = _engineGetObjectText(id);
    return ptr.toDartString();
  }

  static void setObjectText(int id, String text) {
    if (!_initialized) initialize();
    final ptr = text.toNativeUtf8();
    _engineSetObjectText(id, ptr);
    calloc.free(ptr);
  }

  static double getObjectFontSize(int id) {
    if (!_initialized) initialize();
    return _engineGetObjectFontSize(id);
  }

  static void setObjectFontSize(int id, double size) {
    if (!_initialized) initialize();
    _engineSetObjectFontSize(id, size);
  }
}
