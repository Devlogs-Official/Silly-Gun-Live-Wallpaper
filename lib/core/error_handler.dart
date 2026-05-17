import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/app_snackbar.dart';
import 'app_exceptions.dart';
import 'app_logger.dart';

class ErrorHandler {
  const ErrorHandler._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void initialize() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error(
        'Flutter framework error',
        error: details.exception,
        stackTrace: details.stack,
      );
      showError(details.exception);
    };
  }

  static void handleZoneError(Object error, StackTrace stackTrace) {
    AppLogger.error('Uncaught zone error', error: error, stackTrace: stackTrace);
    showError(error);
  }

  static String messageFor(Object error) {
    if (error is AppException) return error.message;
    if (error is TimeoutException) {
      return 'The request timed out. Please try again.';
    }
    if (error is SocketException) {
      return 'No internet connection. Please try again.';
    }
    if (error is FormatException) {
      return 'We could not read the server response.';
    }
    return 'Something went wrong. Please try again.';
  }

  static void showError(Object error) {
    AppSnackbar.error(messageFor(error));
  }

  static Future<T?> guard<T>(
    Future<T> Function() action, {
    String? fallbackMessage,
    bool showSnackbar = true,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      AppLogger.error('Guarded action failed', error: error, stackTrace: stackTrace);
      if (showSnackbar) {
        AppSnackbar.error(fallbackMessage ?? messageFor(error));
      }
      return null;
    }
  }
}
