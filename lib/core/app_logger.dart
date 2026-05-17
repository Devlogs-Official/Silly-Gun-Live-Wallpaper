import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void debug(String message, {Object? data}) {
    if (kReleaseMode) return;
    debugPrint(_format('DEBUG', message, data));
  }

  static void api(String message, {Object? data}) {
    if (kReleaseMode) return;
    debugPrint(_format('API', message, data));
  }

  static void connectivity(String message, {Object? data}) {
    if (kReleaseMode) return;
    debugPrint(_format('CONNECTIVITY', message, data));
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode) return;
    debugPrint(_format('ERROR', message, error));
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static String _format(String level, String message, Object? data) {
    final suffix = data == null ? '' : ' | $data';
    return '[$level] $message$suffix';
  }
}
