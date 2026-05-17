import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';

import '../core/app_logger.dart';

class WallpaperApplyException implements Exception {
  const WallpaperApplyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class WallpaperApplyService {
  WallpaperApplyService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> applyLiveWallpaper({
    required String videoUrl,
    required String fileName,
  }) async {
    if (!Platform.isAndroid) {
      throw const WallpaperApplyException(
        'Live wallpaper applying is supported on Android only.',
      );
    }

    await _requestPermissions();
    final file = await _downloadVideo(videoUrl: videoUrl, fileName: fileName);

    try {
      final message = await WallpaperManagerPlus().setLiveWallpaper(file);
      return message ?? 'Live wallpaper picker opened.';
    } catch (error, stackTrace) {
      AppLogger.error(
        'Opening live wallpaper picker failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const WallpaperApplyException(
        'Could not open the live wallpaper picker.',
      );
    }
  }

  Future<void> _requestPermissions() async {
    final notificationStatus = await Permission.notification.request();
    if (notificationStatus.isPermanentlyDenied) {
      await openAppSettings();
    }

    // final storageStatus = await Permission.storage.request();
    // if (storageStatus.isPermanentlyDenied) {
    //   await openAppSettings();
    //   throw const WallpaperApplyException(
    //     'Storage permission is required to prepare the live wallpaper.',
    //   );
    // }
    //
    // if (storageStatus.isDenied) {
    //   throw const WallpaperApplyException(
    //     'Storage permission was denied.',
    //   );
    // }
  }

  Future<File> _downloadVideo({
    required String videoUrl,
    required String fileName,
  }) async {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null) {
      throw const WallpaperApplyException('Invalid wallpaper video URL.');
    }

    try {
      final directory = await getTemporaryDirectory();
      final safeName = fileName.replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
      final file = File('${directory.path}/$safeName.mp4');

      if (await file.exists() && await file.length() > 0) {
        return file;
      }

      final response =
      await _client.get(uri).timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const WallpaperApplyException('Could not download wallpaper video.');
      }

      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file;
    } on TimeoutException {
      throw const WallpaperApplyException('Video download timed out.');
    } on WallpaperApplyException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Preparing live wallpaper failed',
        error: error,
        stackTrace: stackTrace,
      );
      throw const WallpaperApplyException('Unable to prepare live wallpaper.');
    }
  }

  void dispose() => _client.close();
}
