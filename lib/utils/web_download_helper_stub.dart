import 'dart:typed_data';

/// Stub implementation for non-web platforms to avoid dart:html import issues
class WebDownloadHelper {
  /// Stub method for non-web platforms
  static void downloadPdfInBrowser(Uint8List pdfBytes, String fileName) {
    // This should never be called on non-web platforms
    throw UnsupportedError('WebDownloadHelper is only available on web platforms');
  }
}
