import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import '../../../bridge/native_api.dart';

class EngineView extends StatefulWidget {
  const EngineView({super.key});

  @override
  State<EngineView> createState() => _EngineViewState();
}

class _EngineViewState extends State<EngineView> {
  ui.Image? _image;
  Timer? _timer;
  Pointer<Uint32>? _buffer;
  final int _width = 800;
  final int _height = 600;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  void _initEngine() {
    try {
      NativeApi.initialize(); // Try load DLL
      NativeApi.initEngine(_width, _height);

      // Load Default Font (Windows)
      if (Platform.isWindows) {
        try {
          final fontFile = File(r'C:\Windows\Fonts\arial.ttf');
          if (fontFile.existsSync()) {
            final bytes = fontFile.readAsBytesSync();
            NativeApi.loadFont(bytes);
            AppLog.i("Loaded Arial font (${bytes.length} bytes)");
          } else {
            AppLog.w("Arial font not found");
          }
        } catch (e) {
          AppLog.e("Failed to load font", e);
        }
      }

      // Allocate buffer in Dart/Native heap
      _buffer = calloc<Uint32>(_width * _height);

      // Loop to simulate 60 FPS (or slower for test)
      _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        _renderFrame();
      });
    } catch (e) {
      AppLog.e('Failed to init engine', e);
    }
  }

  void _renderFrame() {
    if (_buffer == null) return;

    // Ask C++ to fill buffer
    NativeApi.render(_buffer!, _width, _height);

    // Convert buffer to Image (Expensive in Dart, temporary for Hello World)
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    final pixels = _buffer!.asTypedList(_width * _height);
    final comp = Completer<ui.Image>();

    ui.decodeImageFromPixels(
      pixels.buffer.asUint8List(),
      _width,
      _height,
      ui.PixelFormat.bgra8888,
      (image) {
        comp.complete(image);
      },
    );

    final image = await comp.future;
    if (mounted) {
      setState(() {
        _image = image;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_buffer != null) calloc.free(_buffer!);
    super.dispose();
  }

  int _draggedObjectId = -1;

  @override
  Widget build(BuildContext context) {
    if (_image == null) {
      return const Center(
        child: Text("Loading C++ Engine... (Compile DLL first!)"),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            final renderBox = context.findRenderObject() as RenderBox;
            final localPos = renderBox.globalToLocal(details.globalPosition);

            // Calculate scale ratios
            final double scaleX = _width / constraints.maxWidth;
            final double scaleY = _height / constraints.maxHeight;

            final int engineX = (localPos.dx * scaleX).toInt();
            final int engineY = (localPos.dy * scaleY).toInt();

            final id = NativeApi.pick(engineX, engineY);
            if (id != -1) {
              setState(() {
                _draggedObjectId = id;
              });
              AppLog.d('Picked object $id');
            }
          },
          onPanUpdate: (details) {
            if (_draggedObjectId != -1) {
              final double scaleX = _width / constraints.maxWidth;
              // final double scaleY = _height / constraints.maxHeight; // Not strictly needed if Aspect Ratio is locked

              final int dx = (details.delta.dx * scaleX).toInt();
              final int dy = (details.delta.dy * scaleX)
                  .toInt(); // Use scaleX for uniform scaling if locked

              NativeApi.moveObject(_draggedObjectId, dx, dy);
            }
          },
          onPanEnd: (details) {
            _draggedObjectId = -1;
          },
          child: RawImage(
            image: _image,
            fit: BoxFit.contain,
          ), // Use contain to respect aspect ratio
        );
      },
    );
  }
}
