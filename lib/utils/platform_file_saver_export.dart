// Conditionally export platform-specific implementations
export 'platform_file_saver_web.dart' if (dart.library.io) 'platform_file_saver_impl.dart';
