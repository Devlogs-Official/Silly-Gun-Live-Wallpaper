import 'package:flutter/material.dart';

enum AppSnackbarType { success, error, warning, internet }

class AppSnackbar {
  const AppSnackbar._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void success(String message) {
    _show(message, AppSnackbarType.success);
  }

  static void error(String message) {
    _show(message, AppSnackbarType.error);
  }

  static void warning(String message) {
    _show(message, AppSnackbarType.warning);
  }

  static void internet(String message) {
    _show(message, AppSnackbarType.internet);
  }

  static void _show(String message, AppSnackbarType type) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    final style = switch (type) {
      AppSnackbarType.success => _SnackbarStyle(
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF8FE3CF),
        ),
      AppSnackbarType.error => _SnackbarStyle(
          icon: Icons.error_rounded,
          color: const Color(0xFFFF7A7A),
        ),
      AppSnackbarType.warning => _SnackbarStyle(
          icon: Icons.warning_rounded,
          color: const Color(0xFFFFC857),
        ),
      AppSnackbarType.internet => _SnackbarStyle(
          icon: Icons.wifi_rounded,
          color: const Color(0xFF7CC7FF),
        ),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: Colors.transparent,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          duration: const Duration(seconds: 3),
          content: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xF211151D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: style.color.withValues(alpha: 0.32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.34),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(style.icon, color: style.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _SnackbarStyle {
  const _SnackbarStyle({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}
