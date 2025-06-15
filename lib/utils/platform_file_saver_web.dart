import 'dart:typed_data';

/// Stub implementation of platform file saver for web
class PlatformFileSaver {
  /// This should never be called on web
  static Future<void> saveFile(Uint8List fileBytes, String fileName) async {
    throw UnsupportedError('PlatformFileSaver is not supported on web');
  }
}
