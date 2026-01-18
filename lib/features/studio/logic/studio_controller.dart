import 'package:flutter/material.dart';
import 'package:karrolle/bridge/native_api.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import 'dart:ffi'; // For pointers
import 'package:ffi/ffi.dart'; // For calloc

class SelectionState {
  final int id;
  final int x;
  final int y;
  final int w;
  final int h;

  SelectionState({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

class StudioController {
  // Singleton
  static final StudioController _instance = StudioController._internal();
  factory StudioController() => _instance;
  StudioController._internal();

  final ValueNotifier<SelectionState?> selectionNotifier = ValueNotifier(null);

  void refreshSelection() {
    try {
      final id = NativeApi.getSelectedId();
      if (id == -1) {
        selectionNotifier.value = null;
        return;
      }

      // Fetch bounds
      final pX = calloc<Int32>();
      final pY = calloc<Int32>();
      final pW = calloc<Int32>();
      final pH = calloc<Int32>();

      NativeApi.getObjectBounds(id, pX, pY, pW, pH);

      selectionNotifier.value = SelectionState(
        id: id,
        x: pX.value,
        y: pY.value,
        w: pW.value,
        h: pH.value,
      );

      calloc.free(pX);
      calloc.free(pY);
      calloc.free(pW);
      calloc.free(pH);
    } catch (e) {
      AppLog.e("Error refreshing selection", e);
    }
  }

  // Action methods updates
  void updatePosition(int id, int dx, int dy) {
    if (selectionNotifier.value?.id == id) {
      // Optimistic update or just trigger refresh after frame?
      // Usually we rely on engine loop, but for UI responsiveness valid to trigger info update
      refreshSelection();
    }
  }

  void updateSelectionRect(int x, int y, int w, int h) {
    if (selectionNotifier.value == null) return;
    final id = selectionNotifier.value!.id;

    NativeApi.setObjectRect(id, x, y, w, h);

    // Optimistic update
    selectionNotifier.value = SelectionState(id: id, x: x, y: y, w: w, h: h);
  }
}
