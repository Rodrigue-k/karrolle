import 'package:flutter/material.dart';
import 'package:karrolle/bridge/native_api.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import 'package:karrolle/features/studio/logic/history_manager.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';

enum LayerType { rectangle, text, image, ellipse, line, unknown }

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
  final double x;
  final double y;
  final double w;
  final double h;
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

class SimpleObjectState {
  final int id;
  final double x, y, w, h;
  SimpleObjectState(this.id, this.x, this.y, this.w, this.h);
}

class StudioController {
  // Singleton
  static final StudioController _instance = StudioController._internal();
  factory StudioController() => _instance;
  StudioController._internal();

  final ValueNotifier<SelectionState?> selectionNotifier = ValueNotifier(null);
  final ValueNotifier<List<LayerInfo>> layersNotifier = ValueNotifier([]);

  // Transaction state for Undo/Redo
  List<SimpleObjectState>? _groupTransactionStartStates;

  LayerType _typeIdToLayerType(int typeId) {
    switch (typeId) {
      case 0:
        return LayerType.rectangle;
      case 1:
        return LayerType.text;
      case 2:
        return LayerType.image;
      case 3:
        return LayerType.ellipse;
      case 4:
        return LayerType.line;
      default:
        return LayerType.unknown;
    }
  }

  void refreshSelection() {
    try {
      final id = NativeApi.getSelectedId();
      if (id == -1) {
        selectionNotifier.value = null;
        return;
      }

      final state = _getObjectState(id);
      if (state != null) {
        selectionNotifier.value = state;
      }
    } catch (e) {
      AppLog.e("Error refreshing selection", e);
    }
  }

  SelectionState? _getObjectState(int id) {
    try {
      final pX = calloc<Float>();
      final pY = calloc<Float>();
      final pW = calloc<Float>();
      final pH = calloc<Float>();

      NativeApi.getObjectBounds(id, pX, pY, pW, pH);
      final int color = NativeApi.getObjectColor(id);

      final typeId = NativeApi.getObjectType(id);
      LayerType type = _typeIdToLayerType(typeId);

      String text = "";
      double fontSize = 0;
      if (type == LayerType.text) {
        text = NativeApi.getObjectText(id);
        fontSize = NativeApi.getObjectFontSize(id);
      }

      final state = SelectionState(
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

      return state;
    } catch (e) {
      return null;
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

        LayerType type = _typeIdToLayerType(typeId);

        layers.add(LayerInfo(index: i, uid: uid, name: name, type: type));
      }

      layersNotifier.value = layers;
    } catch (e) {
      AppLog.e("Error refreshing layers", e);
    }
  }

  // --- Transaction Management ---

  void startTransaction() {
    final count = NativeApi.getSelectedCount();
    _groupTransactionStartStates = [];

    final pX = calloc<Float>();
    final pY = calloc<Float>();
    final pW = calloc<Float>();
    final pH = calloc<Float>();

    for (int i = 0; i < count; i++) {
      final id = NativeApi.getSelectedIdAt(i);
      NativeApi.getObjectBounds(id, pX, pY, pW, pH);
      _groupTransactionStartStates!.add(
        SimpleObjectState(id, pX.value, pY.value, pW.value, pH.value),
      );
    }

    calloc.free(pX);
    calloc.free(pY);
    calloc.free(pW);
    calloc.free(pH);
  }

  void commitTransaction() {
    if (_groupTransactionStartStates == null ||
        _groupTransactionStartStates!.isEmpty) {
      return;
    }

    final pX = calloc<Float>();
    final pY = calloc<Float>();
    final pW = calloc<Float>();
    final pH = calloc<Float>();

    List<Command> moveCommands = [];

    for (var start in _groupTransactionStartStates!) {
      NativeApi.getObjectBounds(start.id, pX, pY, pW, pH);

      if (start.x != pX.value || start.y != pY.value) {
        // Moved
        moveCommands.add(
          MoveCommand(
            objectId: start.id,
            oldX: start.x,
            oldY: start.y,
            newX: pX.value,
            newY: pY.value,
            w: pW.value,
            h: pH.value,
            setRectFn: (id, x, y, w, h) {
              NativeApi.setObjectRect(id, x, y, w, h);
              refreshSelection();
            },
          ),
        );
      } else if (start.w != pW.value || start.h != pH.value) {
        // Resized
        moveCommands.add(
          ResizeCommand(
            objectId: start.id,
            oldX: start.x,
            oldY: start.y,
            oldW: start.w,
            oldH: start.h,
            newX: pX.value,
            newY: pY.value,
            newW: pW.value,
            newH: pH.value,
            setRectFn: (id, x, y, w, h) {
              NativeApi.setObjectRect(id, x, y, w, h);
              refreshSelection();
            },
          ),
        );
      }
    }

    calloc.free(pX);
    calloc.free(pY);
    calloc.free(pW);
    calloc.free(pH);

    if (moveCommands.isNotEmpty) {
      if (moveCommands.length == 1) {
        HistoryManager().executor(moveCommands.first);
      } else {
        HistoryManager().executor(CompositeCommand(moveCommands));
      }
    }

    _groupTransactionStartStates = null;
  }

  // --- Actions ---

  void updateSelectionRect(double x, double y, double w, double h) {
    if (selectionNotifier.value == null) return;
    final state = selectionNotifier.value!;
    final id = state.id;

    HistoryManager().executor(
      MoveCommand(
        objectId: id,
        oldX: state.x,
        oldY: state.y,
        newX: x,
        newY: y,
        w: w,
        h: h,
        setRectFn: (id, nx, ny, nw, nh) {
          NativeApi.setObjectRect(id, nx, ny, nw, nh);
          refreshSelection();
        },
      ),
    );

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
    final oldColor = state.color;

    NativeApi.setObjectColor(id, color);

    // Create history command immediately as this is usually atomic (from picker)
    HistoryManager().executor(
      ColorCommand(
        objectId: id,
        oldColor: oldColor,
        newColor: color,
        setColorFn: (id, c) {
          NativeApi.setObjectColor(id, c);
          // Refresh selection directly to update UI
          final s = _getObjectState(id);
          if (s != null && selectionNotifier.value?.id == id) {
            selectionNotifier.value = s;
          }
        },
      ),
    );

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
    refreshSelection();
  }

  void updateSelectionFontSize(double size) {
    if (selectionNotifier.value == null) return;
    final state = selectionNotifier.value!;
    final id = state.id;

    NativeApi.setObjectFontSize(id, size);
    refreshSelection();
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

  void clearSelection() {
    NativeApi.clearSelection();
    selectionNotifier.value = null;
  }

  void selectObject(int uid, {bool addToSelection = false}) {
    try {
      NativeApi.selectObject(uid, addToSelection: addToSelection);
      refreshSelection();
    } catch (e) {
      AppLog.e("Failed to select object", e);
    }
  }

  // --- Add Objects (with Undo) ---

  void addRectangle() {
    final id = NativeApi.addRect(100.0, 100.0, 200.0, 150.0, 0xFF4F46E5);
    _registerAddCommand(id, "Rectangle");
    refreshLayers();
    NativeApi.selectObject(id);
    refreshSelection();
  }

  void addEllipse() {
    final id = NativeApi.addEllipse(100.0, 100.0, 150.0, 150.0, 0xFFEF4444);
    _registerAddCommand(id, "Ellipse");
    refreshLayers();
    NativeApi.selectObject(id);
    refreshSelection();
  }

  void addLine() {
    final id = NativeApi.addLine(100, 100, 300, 300, 0xFF000000, thickness: 3);
    _registerAddCommand(id, "Line");
    refreshLayers();
    NativeApi.selectObject(id);
    refreshSelection();
  }

  void addText() {
    final id = NativeApi.addText(
      200.0,
      200.0,
      "Double Click to Edit",
      0xFF000000,
      24.0,
    );
    _registerAddCommand(id, "Text");
    refreshLayers();
    NativeApi.selectObject(id);
    refreshSelection();
  }

  void importPptx() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pptx'],
      );

      if (result != null && result.files.single.path != null) {
        NativeApi.importPptx(result.files.single.path!);
        refreshLayers();
        refreshSelection();
      }
    } catch (e) {
      AppLog.e("Failed to import PPTX", e);
    }
  }

  void _registerAddCommand(int id, String type) {
    HistoryManager().executor(
      AddObjectCommand(
        objectId: id,
        addFn: () {
          // Re-adding is complex because ID might change or we need to restore properties
          // For simple Undo of Add -> Delete. Redo of Add -> we need to restore.
          // Simplified: We don't support full redo of Add yet without proper serialization
          // But Undo (Delete) works.
        },
        removeFn: (uid) {
          NativeApi.removeObject(uid);
          refreshLayers();
          refreshSelection();
        },
        objectType: type,
      ),
    );
  }
}

extension HistoryManagerExecutor on HistoryManager {
  void executor(Command cmd) {
    executeCommand(cmd);
  }
}
