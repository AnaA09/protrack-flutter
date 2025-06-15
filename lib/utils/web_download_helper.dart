import 'dart:html' as html;
import 'dart:typed_data';

/// Helper class for web-specific PDF download functionality
class WebDownloadHelper {
  /// Download PDF bytes as a file in the browser
  static void downloadPdfInBrowser(Uint8List pdfBytes, String fileName) {
    // Create a Blob with the PDF data
    final blob = html.Blob([pdfBytes], 'application/pdf');
    
    // Create a URL for the Blob
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Create an anchor element and set attributes
    final anchor = html.AnchorElement(href: url)
      ..target = 'blank'
      ..download = fileName
      ..click();
    
    // Clean up resources
    html.Url.revokeObjectUrl(url);
  }
}
