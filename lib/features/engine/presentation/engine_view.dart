import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:karrolle/bridge/native_api.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import 'package:karrolle/features/studio/logic/studio_controller.dart';

class EngineView extends StatefulWidget {
  final int width;
  final int height;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const EngineView({
    super.key,
    this.width = 1920,
    this.height = 1080,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<EngineView> createState() => _EngineViewState();
}

class _EngineViewState extends State<EngineView>
    with SingleTickerProviderStateMixin {
  ui.Image? _image;
  Pointer<Uint32>? _buffer;
  Ticker? _ticker;

  late int _width;
  late int _height;

  // Interaction State
  int _draggedObjectId = -1;
  int _draggedHandleId = -1;
  int _grabOffsetX = 0;
  int _grabOffsetY = 0;
  int _initialX = 0;
  int _initialY = 0;
  int _initialW = 0;
  int _initialH = 0;

  @override
  void initState() {
    super.initState();
    _width = widget.width;
    _height = widget.height;
    _initEngine();
  }

  @override
  void didUpdateWidget(EngineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width || oldWidget.height != widget.height) {
      _resizeEngine(widget.width, widget.height);
    }
  }

  void _resizeEngine(int newWidth, int newHeight) {
    if (_buffer != null) {
      calloc.free(_buffer!);
    }

    _width = newWidth;
    _height = newHeight;
    _buffer = calloc<Uint32>(_width * _height);

    NativeApi.initEngine(_width, _height);
    StudioController().refreshLayers();
  }

  Future<void> _initEngine() async {
    try {
      NativeApi.initEngine(_width, _height);
      StudioController().refreshLayers();

      _buffer = calloc<Uint32>(_width * _height);

      // Load font
      if (Platform.isWindows) {
        final fontFile = File(r'C:\Windows\Fonts\arial.ttf');
        if (await fontFile.exists()) {
          final fontData = await fontFile.readAsBytes();
          NativeApi.loadFont(fontData);
          AppLog.i("Loaded Arial font (${fontData.length} bytes)");
        }
      }

      // Start render loop
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

    NativeApi.render(_buffer!, _width, _height);

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
        final double aspectEngine = _width / _height;
        final double aspectCanvas =
            constraints.maxWidth / constraints.maxHeight;

        double renderW, renderH, offsetX, offsetY;

        if (aspectCanvas > aspectEngine) {
          renderH = constraints.maxHeight;
          renderW = renderH * aspectEngine;
          offsetX = (constraints.maxWidth - renderW) / 2;
          offsetY = 0;
        } else {
          renderW = constraints.maxWidth;
          renderH = renderW / aspectEngine;
          offsetX = 0;
          offsetY = (constraints.maxHeight - renderH) / 2;
        }

        final double scale = _width / renderW;

        return Listener(
          onPointerDown: (event) =>
              _handlePointerDown(event, offsetX, offsetY, scale),
          onPointerMove: (event) =>
              _handlePointerMove(event, offsetX, offsetY, scale),
          onPointerUp: (event) => _handlePointerUp(event),
          child: _image == null
              ? Container(color: Colors.white)
              : RawImage(
                  image: _image,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
        );
      },
    );
  }

  void _handlePointerDown(
    PointerDownEvent event,
    double offsetX,
    double offsetY,
    double scale,
  ) {
    final double localX = event.localPosition.dx - offsetX;
    final double localY = event.localPosition.dy - offsetY;
    final int cursorX = (localX * scale).toInt();
    final int cursorY = (localY * scale).toInt();

    if (cursorX < 0 || cursorX >= _width || cursorY < 0 || cursorY >= _height) {
      StudioController().refreshSelection();
      return;
    }

    // Check handle picking first
    int handleId = NativeApi.pickHandle(cursorX, cursorY);

    if (handleId != -1) {
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

        // Notify parent that we're dragging
        widget.onDragStart?.call();
        return;
      }
    }

    // Pick object
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

      // Notify parent that we're dragging
      widget.onDragStart?.call();
    } else {
      _draggedObjectId = -1;
    }

    StudioController().refreshSelection();
  }

  void _handlePointerMove(
    PointerMoveEvent event,
    double offsetX,
    double offsetY,
    double scale,
  ) {
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
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_draggedObjectId != -1) {
      // Notify parent that drag ended
      widget.onDragEnd?.call();
    }
    _draggedObjectId = -1;
    _draggedHandleId = -1;
    StudioController().refreshSelection();
  }
}
