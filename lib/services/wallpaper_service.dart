import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_exceptions.dart';
import '../core/app_logger.dart';
import '../models/wallpaper_model.dart';

class WallpaperPage {
  const WallpaperPage({
    required this.wallpapers,
    required this.currentPage,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
  });

  final List<WallpaperModel> wallpapers;
  final int currentPage;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
}

class WallpaperService {
  WallpaperService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl =
      'https://api.devlogs.pro/apps/sillySmileGunLiveWallpapers/get_silly_wallpapers.php';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  Future<WallpaperPage> fetchWallpapers({
    required int page,
    int pageSize = 20,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'page': page.toString(),
        'page_size': pageSize.toString(),
      },
    );

    AppLogger.api('Fetching wallpapers', data: uri);

    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.body.trim().isEmpty) {
        throw const ApiException('The server returned an empty response.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Server error ${response.statusCode}. Please try again.',
          debugMessage: response.body,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Invalid server response.');
      }

      if (decoded['status'] != true) {
        throw ApiException(
          (decoded['message'] as String?)?.trim().isNotEmpty == true
              ? decoded['message'] as String
              : 'Unable to load wallpapers.',
        );
      }

      final pagination = decoded['pagination'];
      final data = decoded['data'];
      if (pagination is! Map<String, dynamic> || data is! List) {
        throw const ApiException('Incomplete server response.');
      }

      return WallpaperPage(
        wallpapers: data
            .whereType<Map<String, dynamic>>()
            .map(WallpaperModel.fromJson)
            .where((wallpaper) => wallpaper.thumbnailUrl.isNotEmpty)
            .toList(growable: false),
        currentPage: _parseInt(pagination['current_page'], fallback: page),
        pageSize: _parseInt(pagination['page_size'], fallback: pageSize),
        totalRecords: _parseInt(pagination['total_records']),
        totalPages: _parseInt(pagination['total_pages'], fallback: 1),
      );
    } on TimeoutException {
      throw const NetworkException(
        'The request timed out. Check your connection and try again.',
      );
    } on SocketException {
      throw const NetworkException('No internet connection. Please try again.');
    } on FormatException catch (error) {
      throw ApiException(
        'Could not read server response.',
        debugMessage: error.toString(),
      );
    } on http.ClientException catch (error) {
      throw NetworkException(
        'Network error. Check your connection and try again.',
        debugMessage: error.toString(),
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected API failure',
        error: error,
        stackTrace: stackTrace,
      );
      throw const ApiException('Something went wrong while loading wallpapers.');
    }
  }

  void dispose() => _client.close();

  static int _parseInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
