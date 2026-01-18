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

class NativeApi {
  static late DynamicLibrary _lib;
  static late EngineInitDart _engineInit;
  static late EngineRenderDart _engineRender;

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
}
