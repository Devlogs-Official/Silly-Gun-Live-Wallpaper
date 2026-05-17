abstract class AppException implements Exception {
  const AppException(this.message, {this.debugMessage});

  final String message;
  final String? debugMessage;

  @override
  String toString() => debugMessage ?? message;
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.debugMessage});
}

class ApiException extends AppException {
  const ApiException(super.message, {super.debugMessage});
}

class CacheException extends AppException {
  const CacheException(super.message, {super.debugMessage});
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message, {super.debugMessage});
}

class VideoPlaybackException extends AppException {
  const VideoPlaybackException(super.message, {super.debugMessage});
}

class WallpaperActionException extends AppException {
  const WallpaperActionException(super.message, {super.debugMessage});
}
