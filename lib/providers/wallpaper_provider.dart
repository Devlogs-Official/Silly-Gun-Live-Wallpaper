import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../core/app_exceptions.dart';
import '../core/app_logger.dart';
import '../models/wallpaper_model.dart';
import '../services/wallpaper_cache_service.dart';
import '../services/wallpaper_service.dart';

class WallpaperProvider extends ChangeNotifier {
  WallpaperProvider({
    WallpaperService? service,
    WallpaperCacheService? cacheService,
  })  : _service = service ?? WallpaperService(),
        _cacheService = cacheService ?? WallpaperCacheService();

  static const int _pageSize = 20;

  final WallpaperService _service;
  final WallpaperCacheService _cacheService;

  final List<WallpaperModel> _wallpapers = [];
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _cacheRestored = false;
  String? _errorMessage;

  UnmodifiableListView<WallpaperModel> get wallpapers =>
      UnmodifiableListView(_wallpapers);
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _currentPage < _totalPages;
  String? get errorMessage => _errorMessage;

  bool restoreCachedWallpapers() {
    _restoreCacheIfNeeded(notify: false);
    return _wallpapers.isNotEmpty;
  }

  Future<void> fetchInitialWallpapers({bool forceRefresh = false}) async {
    if (_isLoading || _isLoadingMore) return;
    if (_wallpapers.isNotEmpty && !forceRefresh) return;

    _restoreCacheIfNeeded();

    _isLoading = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final page = await _service.fetchWallpapers(page: 1, pageSize: _pageSize);
      _wallpapers
        ..clear()
        ..addAll(page.wallpapers);
      _currentPage = page.currentPage;
      _totalPages = page.totalPages;
      await _saveCache();
    } on AppException catch (error) {
      if (_wallpapers.isEmpty) {
        _errorMessage = error.message;
      }
      AppLogger.error('Initial wallpapers fetch failed', error: error);
    } catch (error, stackTrace) {
      if (_wallpapers.isEmpty) {
        _errorMessage = 'Unable to load wallpapers.';
      }
      AppLogger.error(
        'Unexpected initial wallpapers fetch failure',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoading = false;
      _notifySafely();
    }
  }

  Future<void> fetchMoreWallpapers() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    _notifySafely();

    try {
      final page = await _service.fetchWallpapers(
        page: _currentPage + 1,
        pageSize: _pageSize,
      );
      final existingIds = _wallpapers.map((wallpaper) => wallpaper.id).toSet();
      final newItems = page.wallpapers.where(
        (wallpaper) => existingIds.add(wallpaper.id),
      );

      _wallpapers.addAll(newItems);
      _currentPage = page.currentPage;
      _totalPages = page.totalPages;
      await _saveCache();
    } on AppException catch (error) {
      _errorMessage = error.message;
      AppLogger.error('Pagination fetch failed', error: error);
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to load more wallpapers.';
      AppLogger.error(
        'Unexpected pagination fetch failure',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _isLoadingMore = false;
      _notifySafely();
    }
  }

  Future<void> refreshWallpapers() async {
    _currentPage = 0;
    _totalPages = 1;
    _errorMessage = null;
    await fetchInitialWallpapers(forceRefresh: true);
  }

  void _restoreCacheIfNeeded({bool notify = true}) {
    if (_cacheRestored || _wallpapers.isNotEmpty) return;

    List<WallpaperModel> cachedWallpapers = const [];
    try {
      cachedWallpapers = _cacheService.readWallpapers();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Reading cached wallpapers failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (cachedWallpapers.isEmpty) {
      _cacheRestored = true;
      return;
    }

    _wallpapers
      ..clear()
      ..addAll(cachedWallpapers);
    _currentPage = _cacheService.readCurrentPage();
    _totalPages = _cacheService.readTotalPages();
    _cacheRestored = true;
    if (notify) _notifySafely();
  }

  Future<void> _saveCache() {
    return _cacheService.saveWallpapers(
      wallpapers: _wallpapers,
      currentPage: _currentPage,
      totalPages: _totalPages,
    );
  }

  void _notifySafely() {
    if (hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
