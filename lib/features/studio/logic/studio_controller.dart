import 'package:flutter/material.dart';
import 'package:karrolle/bridge/native_api.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

enum LayerType { rectangle, text, image, unknown }

class LayerInfo {
  final int index;
  final int uid;
  final String name;
  final LayerType type;

  LayerInfo({
    required this.index,
    required this.uid,
    required this.name,
    required this.type,
  });
}

class SelectionState {
  final int id;
  final int x;
  final int y;
  final int w;
  final int h;
  final int color;
  final String text;
  final double fontSize;
  final LayerType type;

  SelectionState({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.color,
    required this.text,
    required this.fontSize,
    required this.type,
  });
}

class StudioController {
  // Singleton
  static final StudioController _instance = StudioController._internal();
  factory StudioController() => _instance;
  StudioController._internal();

  final ValueNotifier<SelectionState?> selectionNotifier = ValueNotifier(null);
  final ValueNotifier<List<LayerInfo>> layersNotifier = ValueNotifier([]);

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
      final int color = NativeApi.getObjectColor(id);

      // Determine type
      final typeId = NativeApi.getObjectType(id);
      LayerType type = LayerType.unknown;
      if (typeId == 0)
        type = LayerType.rectangle;
      else if (typeId == 1)
        type = LayerType.text;

      String text = "";
      double fontSize = 0;
      if (type == LayerType.text) {
        text = NativeApi.getObjectText(id);
        fontSize = NativeApi.getObjectFontSize(id);
      }

      selectionNotifier.value = SelectionState(
        id: id,
        x: pX.value,
        y: pY.value,
        w: pW.value,
        h: pH.value,
        color: color,
        text: text,
        fontSize: fontSize,
        type: type,
      );

      calloc.free(pX);
      calloc.free(pY);
      calloc.free(pW);
      calloc.free(pH);
    } catch (e) {
      AppLog.e("Error refreshing selection", e);
    }
  }

  void refreshLayers() {
    try {
      final count = NativeApi.getObjectCount();
      final List<LayerInfo> layers = [];

      for (int i = 0; i < count; i++) {
        final name = NativeApi.getObjectName(i);
        final typeId = NativeApi.getObjectType(i);
        final uid = NativeApi.getObjectUid(i);

        LayerType type = LayerType.unknown;
        if (typeId == 0)
          type = LayerType.rectangle;
        else if (typeId == 1)
          type = LayerType.text;
        else if (typeId == 2)
          type = LayerType.image;

        layers.add(LayerInfo(index: i, uid: uid, name: name, type: type));
      }

      layersNotifier.value = layers;
    } catch (e) {
      AppLog.e("Error refreshing layers", e);
    }
  }

  // Action methods updates
  void updatePosition(int id, int dx, int dy) {
    if (selectionNotifier.value?.id == id) {
      refreshSelection();
    }
  }

  void updateSelectionRect(int x, int y, int w, int h) {
    if (selectionNotifier.value == null) return;
    final state = selectionNotifier.value!;
    final id = state.id;

    NativeApi.setObjectRect(id, x, y, w, h);

    // Optimistic update
    selectionNotifier.value = SelectionState(
      id: id,
      x: x,
      y: y,
      w: w,
      h: h,
      color: state.color,
      text: state.text,
      fontSize: state.fontSize,
      type: state.type,
    );
  }

  void updateSelectionColor(int color) {
    if (selectionNotifier.value == null) return;
    final state = selectionNotifier.value!;
    final id = state.id;

    NativeApi.setObjectColor(id, color);

    // Optimistic update
    selectionNotifier.value = SelectionState(
      id: id,
      x: state.x,
      y: state.y,
      w: state.w,
      h: state.h,
      color: color,
      text: state.text,
      fontSize: state.fontSize,
      type: state.type,
    );
  }

  void updateSelectionText(String text) {
    if (selectionNotifier.value == null) return;
    final state = selectionNotifier.value!;
    final id = state.id;

    NativeApi.setObjectText(id, text);
    refreshSelection(); // Geometry might change
  }

  void updateSelectionFontSize(double size) {
    if (selectionNotifier.value == null) return;
    final state = selectionNotifier.value!;
    final id = state.id;

    NativeApi.setObjectFontSize(id, size);
    refreshSelection(); // Geometry changes
  }

  void removeObject(int uid) {
    try {
      NativeApi.removeObject(uid);
      refreshLayers();
      refreshSelection();
    } catch (e) {
      AppLog.e("Failed to remove object", e);
    }
  }

  void selectObject(int uid) {
    try {
      NativeApi.selectObject(uid);
      refreshSelection();
    } catch (e) {
      AppLog.e("Failed to select object", e);
    }
  }
}
