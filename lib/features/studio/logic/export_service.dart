import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';

import 'package:karrolle/bridge/native_api.dart';
import 'package:karrolle/core/logger/app_logger.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Export service for saving documents as various formats
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Export current canvas as PNG
  Future<String?> exportAsPng({
    required int width,
    required int height,
    String? suggestedName,
  }) async {
    try {
      // Pick save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export as PNG',
        fileName: suggestedName ?? 'export.png',
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (result == null) return null;

      // Render to buffer
      final buffer = calloc<Uint32>(width * height);
      NativeApi.render(buffer, width, height);

      // Convert BGRA to RGBA
      final pixels = buffer.asTypedList(width * height);
      final rgbaPixels = Uint8List(width * height * 4);

      for (int i = 0; i < pixels.length; i++) {
        final bgra = pixels[i];
        final b = (bgra >> 0) & 0xFF;
        final g = (bgra >> 8) & 0xFF;
        final r = (bgra >> 16) & 0xFF;
        final a = (bgra >> 24) & 0xFF;

        rgbaPixels[i * 4 + 0] = r;
        rgbaPixels[i * 4 + 1] = g;
        rgbaPixels[i * 4 + 2] = b;
        rgbaPixels[i * 4 + 3] = a;
      }

      calloc.free(buffer);

      // Encode as PNG using dart:ui
      final image = await _createImage(rgbaPixels, width, height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode image as PNG');
      }

      // Save to file
      final file = File(result);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      AppLog.i('Exported PNG to: $result');
      return result;
    } catch (e) {
      AppLog.e('Failed to export PNG', e);
      return null;
    }
  }

  /// Create ui.Image from RGBA pixels
  Future<ui.Image> _createImage(Uint8List pixels, int width, int height) async {
    final completer = ui.ImmutableBuffer.fromUint8List(pixels);
    final buffer = await completer;

    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: width,
      height: height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Export current canvas as PDF
  Future<String?> exportAsPdf({
    required int width,
    required int height,
    String? suggestedName,
    String? title,
  }) async {
    try {
      // Pick save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export as PDF',
        fileName: suggestedName ?? 'export.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) return null;

      // Render to buffer
      final buffer = calloc<Uint32>(width * height);
      NativeApi.render(buffer, width, height);

      // Convert BGRA to RGBA
      final pixels = buffer.asTypedList(width * height);
      final rgbaPixels = Uint8List(width * height * 4);

      for (int i = 0; i < pixels.length; i++) {
        final bgra = pixels[i];
        final b = (bgra >> 0) & 0xFF;
        final g = (bgra >> 8) & 0xFF;
        final r = (bgra >> 16) & 0xFF;
        final a = (bgra >> 24) & 0xFF;

        rgbaPixels[i * 4 + 0] = r;
        rgbaPixels[i * 4 + 1] = g;
        rgbaPixels[i * 4 + 2] = b;
        rgbaPixels[i * 4 + 3] = a;
      }

      calloc.free(buffer);

      // Get PNG bytes
      final image = await _createImage(rgbaPixels, width, height);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode image');
      }

      // Create PDF
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(byteData.buffer.asUint8List());

      // Calculate page size to match aspect ratio
      final pageFormat = PdfPageFormat(
        width.toDouble(),
        height.toDouble(),
        marginAll: 0,
      );

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
          },
        ),
      );

      // Save PDF
      final file = File(result);
      await file.writeAsBytes(await pdf.save());

      AppLog.i('Exported PDF to: $result');
      return result;
    } catch (e) {
      AppLog.e('Failed to export PDF', e);
      return null;
    }
  }

  /// Export all pages as PDF
  Future<String?> exportAllPagesAsPdf({
    required int width,
    required int height,
    required int pageCount,
    required Future<void> Function(int) goToPage,
    String? suggestedName,
  }) async {
    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export All Pages as PDF',
        fileName: suggestedName ?? 'presentation.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) return null;

      final pdf = pw.Document();
      final pageFormat = PdfPageFormat(
        width.toDouble(),
        height.toDouble(),
        marginAll: 0,
      );

      for (int i = 0; i < pageCount; i++) {
        // Navigate to page
        await goToPage(i);

        // Small delay to ensure render is complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Render page
        final buffer = calloc<Uint32>(width * height);
        NativeApi.render(buffer, width, height);

        final pixels = buffer.asTypedList(width * height);
        final rgbaPixels = Uint8List(width * height * 4);

        for (int j = 0; j < pixels.length; j++) {
          final bgra = pixels[j];
          rgbaPixels[j * 4 + 0] = (bgra >> 16) & 0xFF;
          rgbaPixels[j * 4 + 1] = (bgra >> 8) & 0xFF;
          rgbaPixels[j * 4 + 2] = (bgra >> 0) & 0xFF;
          rgbaPixels[j * 4 + 3] = (bgra >> 24) & 0xFF;
        }

        calloc.free(buffer);

        final image = await _createImage(rgbaPixels, width, height);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final pdfImage = pw.MemoryImage(byteData.buffer.asUint8List());
          pdf.addPage(
            pw.Page(
              pageFormat: pageFormat,
              build: (context) =>
                  pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)),
            ),
          );
        }
      }

      final file = File(result);
      await file.writeAsBytes(await pdf.save());

      AppLog.i('Exported all pages to PDF: $result');
      return result;
    } catch (e) {
      AppLog.e('Failed to export PDF', e);
      return null;
    }
  }
}
