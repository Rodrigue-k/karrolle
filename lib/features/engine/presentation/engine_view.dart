import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:karrolle/bridge/native_api.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import 'package:karrolle/features/studio/logic/studio_controller.dart';

class EngineView extends StatefulWidget {
  const EngineView({super.key});

  @override
  State<EngineView> createState() => _EngineViewState();
}

class _EngineViewState extends State<EngineView>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  Pointer<Uint32>? _buffer;
  Ticker? _ticker;

  // Engine Resolution (Fixed Internal Session)
  static const int _width = 800;
  static const int _height = 600;

  // Interaction State - Optimized for Zero Latency
  int _draggedObjectId = -1;
  int _draggedHandleId = -1; // -1 = Move, 0-7 = Resize
  int _grabOffsetX = 0;
  int _grabOffsetY = 0;
  int _initialX = 0;
  int _initialY = 0;
  int _initialW = 0;
  int _initialH = 0;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    try {
      // 1. Initialize FFI
      NativeApi.initEngine(_width, _height);

      StudioController().refreshLayers();

      // 2. Allocate Pixel Buffer (Reuse same buffer)
      _buffer = calloc<Uint32>(_width * _height);

      // 3. Load Fonts
      if (Platform.isWindows) {
        final fontFile = File(r'C:\Windows\Fonts\arial.ttf');
        if (await fontFile.exists()) {
          final fontData = await fontFile.readAsBytes();
          NativeApi.loadFont(fontData);
          AppLog.i("Loaded Arial font (${fontData.length} bytes)");
        }
      }

      // 4. Start V-Sync Loop (Ticker)
      // Uses Flutter's scheduler to render EXACTLY when screen refreshes.
      _ticker = createTicker((elapsed) {
        _updateTexture();
      });
      _ticker?.start();
    } catch (e) {
      AppLog.e('Failed to init engine', e);
    }
  }

  void _updateTexture() {
    if (_buffer == null) return;

    // 1. C++ Render directly to memory
    NativeApi.render(_buffer!, _width, _height);

    // 2. Decode pixels to GPU Texture
    ui.decodeImageFromPixels(
      _buffer!.cast<Uint8>().asTypedList(_width * _height * 4),
      _width,
      _height,
      ui.PixelFormat.bgra8888,
      (image) {
        if (mounted) {
          setState(() {
            _image = image;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    if (_buffer != null) {
      calloc.free(_buffer!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_buffer == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Correct BoxFit.contain logic
        final double aspectEngine = _width / _height;
        final double aspectCanvas =
            constraints.maxWidth / constraints.maxHeight;

        double renderW, renderH, offsetX, offsetY;

        if (aspectCanvas > aspectEngine) {
          // Canvas is wider than Engine (Pillarbox)
          renderH = constraints.maxHeight;
          renderW = renderH * aspectEngine;
          offsetX = (constraints.maxWidth - renderW) / 2;
          offsetY = 0;
        } else {
          // Canvas is taller than Engine (Letterbox)
          renderW = constraints.maxWidth;
          renderH = renderW / aspectEngine;
          offsetX = 0;
          offsetY = (constraints.maxHeight - renderH) / 2;
        }

        final double scale =
            _width / renderW; // Map render pixels -> Engine pixels

        return Listener(
          onPointerDown: (event) {
            // Transform local pos -> render pos
            final double localX = event.localPosition.dx - offsetX;
            final double localY = event.localPosition.dy - offsetY;

            // Map to engine space
            final int cursorX = (localX * scale).toInt();
            final int cursorY = (localY * scale).toInt();

            // Debug info
            // AppLog.d("Ptr: ${event.localPosition} -> Local: $localX,$localY -> Eng: $cursorX,$cursorY");

            // Ignore clicks outside the engine area
            if (cursorX < 0 ||
                cursorX >= _width ||
                cursorY < 0 ||
                cursorY >= _height) {
              StudioController()
                  .refreshSelection(); // Deselect if clicking outside?
              return;
            }

            // 1. Check Handle Picking First (If something is already selected)
            int handleId = NativeApi.pickHandle(cursorX, cursorY);

            if (handleId != -1) {
              // Start Resizing
              final id = NativeApi.getSelectedId();
              if (id != -1) {
                final pX = calloc<Int32>();
                final pY = calloc<Int32>();
                final pW = calloc<Int32>();
                final pH = calloc<Int32>();
                NativeApi.getObjectBounds(id, pX, pY, pW, pH);

                _draggedObjectId = id;
                _draggedHandleId = handleId;
                _initialX = pX.value;
                _initialY = pY.value;
                _initialW = pW.value;
                _initialH = pH.value;
                _grabOffsetX = cursorX;
                _grabOffsetY = cursorY;

                calloc.free(pX);
                calloc.free(pY);
                calloc.free(pW);
                calloc.free(pH);
                return;
              }
            }

            // 2. Otherwise Pick Object (Normal Move)
            final id = NativeApi.pick(cursorX, cursorY);

            if (id != -1) {
              final pX = calloc<Int32>();
              final pY = calloc<Int32>();
              final pW = calloc<Int32>();
              final pH = calloc<Int32>();
              NativeApi.getObjectBounds(id, pX, pY, pW, pH);

              _draggedObjectId = id;
              _draggedHandleId = -1;
              _initialX = pX.value;
              _initialY = pY.value;
              _initialW = pW.value;
              _initialH = pH.value;
              _grabOffsetX = cursorX - _initialX;
              _grabOffsetY = cursorY - _initialY;

              calloc.free(pX);
              calloc.free(pY);
              calloc.free(pW);
              calloc.free(pH);
            } else {
              _draggedObjectId = -1;
            }

            StudioController().refreshSelection();
          },
          onPointerMove: (event) {
            if (_draggedObjectId == -1) return;

            final double localX = event.localPosition.dx - offsetX;
            final double localY = event.localPosition.dy - offsetY;
            final int cursorX = (localX * scale).toInt();
            final int cursorY = (localY * scale).toInt();

            if (_draggedHandleId == -1) {
              // MOVE
              final int newX = cursorX - _grabOffsetX;
              final int newY = cursorY - _grabOffsetY;
              NativeApi.setObjectRect(
                _draggedObjectId,
                newX,
                newY,
                _initialW,
                _initialH,
              );
            } else {
              // RESIZE
              int dx = cursorX - _grabOffsetX;
              int dy = cursorY - _grabOffsetY;

              int nx = _initialX;
              int ny = _initialY;
              int nw = _initialW;
              int nh = _initialH;

              switch (_draggedHandleId) {
                case 0:
                  nx += dx;
                  ny += dy;
                  nw -= dx;
                  nh -= dy;
                  break;
                case 1:
                  ny += dy;
                  nh -= dy;
                  break;
                case 2:
                  ny += dy;
                  nw += dx;
                  nh -= dy;
                  break;
                case 3:
                  nw += dx;
                  break;
                case 4:
                  nw += dx;
                  nh += dy;
                  break;
                case 5:
                  nh += dy;
                  break;
                case 6:
                  nx += dx;
                  nw -= dx;
                  nh += dy;
                  break;
                case 7:
                  nx += dx;
                  nw -= dx;
                  break;
              }

              if (nw < 10) nw = 10;
              if (nh < 10) nh = 10;

              NativeApi.setObjectRect(_draggedObjectId, nx, ny, nw, nh);
            }

            StudioController().refreshSelection();
          },
          onPointerUp: (event) {
            _draggedObjectId = -1;
            _draggedHandleId = -1;
            StudioController().refreshSelection();
          },
          child: _image == null
              ? Container(color: const Color(0xFF252526))
              : RawImage(
                  image: _image,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
        );
      },
    );
  }
}
