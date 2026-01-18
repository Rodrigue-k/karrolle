import 'dart:ffi';
import 'dart:io';
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

class NativeApi {
  static late DynamicLibrary _lib;
  static late EngineInitDart _engineInit;
  static late EngineRenderDart _engineRender;
  static late EngineAddRectDart _engineAddRect;
  static late EnginePickDart _enginePick;
  static late EngineMoveObjectDart _engineMoveObject;

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;

    // Load library based on platform
    if (Platform.isWindows) {
      _lib = DynamicLibrary.open('karrolle_engine.dll');
    } else if (Platform.isLinux) {
      _lib = DynamicLibrary.open('libkarrolle_engine.so');
    } else if (Platform.isMacOS) {
      _lib = DynamicLibrary.open('libkarrolle_engine.dylib');
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    // Lookup functions
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

    _initialized = true;
    AppLog.i('Native API initialized');
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
}
