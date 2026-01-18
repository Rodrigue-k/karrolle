import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:karrolle/core/logger/app_logger.dart';

// Typedefs for C functions
typedef EngineInitC = Void Function(Int32 width, Int32 height);
typedef EngineInitDart = void Function(int width, int height);

typedef EngineRenderC =
    Void Function(Pointer<Uint32> buffer, Int32 width, Int32 height);
typedef EngineRenderDart =
    void Function(Pointer<Uint32> buffer, int width, int height);

typedef EngineAddRectC =
    Void Function(Int32 x, Int32 y, Int32 w, Int32 h, Uint32 color);
typedef EngineAddRectDart =
    void Function(int x, int y, int w, int h, int color);

typedef EnginePickC = Int32 Function(Int32 x, Int32 y);
typedef EnginePickDart = int Function(int x, int y);

typedef EngineMoveObjectC = Void Function(Int32 id, Int32 dx, Int32 dy);
typedef EngineMoveObjectDart = void Function(int id, int dx, int dy);

typedef EngineLoadFontC = Void Function(Pointer<Uint8> data, Int32 length);
typedef EngineLoadFontDart = void Function(Pointer<Uint8> data, int length);

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

typedef EngineGetSelectedIdC = Int32 Function();
typedef EngineGetSelectedIdDart = int Function();

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

class NativeApi {
  static late DynamicLibrary _lib;
  static late EngineInitDart _engineInit;
  static late EngineRenderDart _engineRender;
  static late EngineAddRectDart _engineAddRect;
  static late EnginePickDart _enginePick;
  static late EngineMoveObjectDart _engineMoveObject;
  static late EngineLoadFontDart _engineLoadFont;
  static late EngineAddTextDart _engineAddText;

  static late EngineGetSelectedIdDart _engineGetSelectedId;
  static late EngineGetObjectBoundsDart _engineGetObjectBounds;

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;

    try {
      if (Platform.isWindows) {
        _lib = DynamicLibrary.open('karrolle_engine.dll');
      } else if (Platform.isLinux) {
        _lib = DynamicLibrary.open('libkarrolle_engine.so');
      } else if (Platform.isMacOS) {
        _lib = DynamicLibrary.open('libkarrolle_engine.dylib');
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      _engineInit = _lib.lookupFunction<EngineInitC, EngineInitDart>(
        'engine_init',
      );
      _engineRender = _lib.lookupFunction<EngineRenderC, EngineRenderDart>(
        'engine_render',
      );
      _engineAddRect = _lib.lookupFunction<EngineAddRectC, EngineAddRectDart>(
        'engine_add_rect',
      );
      _enginePick = _lib.lookupFunction<EnginePickC, EnginePickDart>(
        'engine_pick',
      );
      _engineMoveObject = _lib
          .lookupFunction<EngineMoveObjectC, EngineMoveObjectDart>(
            'engine_move_object',
          );
      _engineLoadFont = _lib
          .lookupFunction<EngineLoadFontC, EngineLoadFontDart>(
            'engine_load_font',
          );
      _engineAddText = _lib.lookupFunction<EngineAddTextC, EngineAddTextDart>(
        'engine_add_text',
      );

      _engineGetSelectedId = _lib
          .lookupFunction<EngineGetSelectedIdC, EngineGetSelectedIdDart>(
            'engine_get_selected_id',
          );
      _engineGetObjectBounds = _lib
          .lookupFunction<EngineGetObjectBoundsC, EngineGetObjectBoundsDart>(
            'engine_get_object_bounds',
          );

      _initialized = true;
      AppLog.i('Native API initialized successfully');
    } catch (e) {
      AppLog.e('Failed to load Native API', e);
      rethrow;
    }
  }

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

  static int pick(int x, int y) {
    if (!_initialized) initialize();
    return _enginePick(x, y);
  }

  static void moveObject(int id, int dx, int dy) {
    if (!_initialized) initialize();
    _engineMoveObject(id, dx, dy);
  }

  static void loadFont(List<int> bytes) {
    if (!_initialized) initialize();
    // Allocate memory on native execution stack or heap
    final ptr = calloc<Uint8>(bytes.length);
    final list = ptr.asTypedList(bytes.length);
    list.setAll(0, bytes);
    _engineLoadFont(ptr, bytes.length);
    calloc.free(ptr);
  }

  static void addText(int x, int y, String text, int color, double size) {
    if (!_initialized) initialize();
    final ptr = text.toNativeUtf8();
    _engineAddText(x, y, ptr, color, size);
    calloc.free(ptr);
  }

  static int getSelectedId() {
    if (!_initialized) initialize();
    return _engineGetSelectedId();
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
}
