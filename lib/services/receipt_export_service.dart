import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptExportService {
  static const MethodChannel _galleryChannel = MethodChannel(
    'com.scrapcal.scrapcal/gallery',
  );

  /// Captures the widget attached to [boundaryKey] into crisp PNG bytes.
  static Future<Uint8List> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    final context = boundaryKey.currentContext;
    if (context == null) {
      throw StateError('Receipt boundary context is not ready.');
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('Target widget is not a RenderRepaintBoundary.');
    }

    final ui.Image image = await renderObject.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to encode PNG bytes.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static String buildFileName(DateTime timestamp) {
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${timestamp.year}${two(timestamp.month)}${two(timestamp.day)}_${two(timestamp.hour)}${two(timestamp.minute)}${two(timestamp.second)}';
    return 'SCRAPCAL_Resibo_$stamp.png';
  }

  /// Saves PNG bytes into Android Gallery (Pictures/SCRAPCAL) via native MediaStore.
  static Future<String> savePngToGallery({
    required Uint8List pngBytes,
    required String fileName,
  }) async {
    final savedPath = await _galleryChannel.invokeMethod<String>(
      'savePngToGallery',
      <String, dynamic>{'bytes': pngBytes, 'fileName': fileName},
    );
    if (savedPath == null || savedPath.isEmpty) {
      throw StateError('Gallery save returned empty path.');
    }
    return savedPath;
  }

  /// Writes PNG bytes to a temporary file and opens the native Android Share Sheet.
  static Future<void> sharePng({
    required Uint8List pngBytes,
    required String fileName,
    String? text,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pngBytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
        text: text,
      ),
    );
  }
}
