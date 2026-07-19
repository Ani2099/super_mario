import 'package:flutter/foundation.dart';

class GameLogger {
  static void info(String message) {
    if (kDebugMode) {
      print('👾 [INFO] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ [WARN] $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('🛑 [ERROR] $message');
      if (error != null) print('Details: $error');
      if (stackTrace != null) print(stackTrace);
    }
  }
}
