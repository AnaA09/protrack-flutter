import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

/// Helper class for saving files on native platforms
class PlatformFileSaver {
  /// Save a file on native platforms and open it
  static Future<void> saveFile(Uint8List fileBytes, String fileName) async {
    try {
      // Get the appropriate directory based on platform
      final directory = await _getAppropriateDirectory();
      
      if (directory == null) {
        throw Exception('Could not determine appropriate directory for saving files');
      }
      
      // Create file path
      final filePath = '${directory.path}/$fileName';
      
      // Write bytes to file
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      
      // Open the file
      await OpenFile.open(filePath);
    } catch (e) {
      throw Exception('Error saving file: $e');
    }
  }
  
  /// Get the appropriate directory based on platform
  static Future<Directory?> _getAppropriateDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    } else {
      return getDownloadsDirectory();
    }
  }
}
