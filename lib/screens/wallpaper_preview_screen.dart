import 'dart:async';

import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../core/app_exceptions.dart';
import '../core/app_logger.dart';
import '../models/wallpaper_model.dart';
import '../services/wallpaper_apply_service.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/video_loader.dart';
import '../widgets/wallpaper_thumbnail_strip.dart';
import 'fullscreen_preview_screen.dart';

class WallpaperPreviewScreen extends StatefulWidget {
  const WallpaperPreviewScreen({
    super.key,
    required this.wallpaper,
    required this.wallpapers,
    required this.initialIndex,
  });

  final WallpaperModel wallpaper;
  final List<WallpaperModel> wallpapers;
  final int initialIndex;

  @override
  State<WallpaperPreviewScreen> createState() => _WallpaperPreviewScreenState();
}

class _WallpaperPreviewScreenState extends State<WallpaperPreviewScreen>
    with WidgetsBindingObserver {
  late final PageController _pageController;
  final WallpaperApplyService _applyService = WallpaperApplyService();
  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, String> _videoErrors = {};
  late int _selectedIndex;
  bool _didPrecacheDependencies = false;
  bool _routePaused = false;
  Timer? _pageChangeDebounce;

  Future<void> _onPageChanged(int index) async {
    _pageChangeDebounce?.cancel();
    _controllers[_selectedIndex]?.pause();
    if (!mounted) return;
    setState(() => _selectedIndex = index);

    _pageChangeDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _initializeVideo(index, play: true);
      if (!mounted) return;
      _preloadNearby(index);
    });
  }



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedIndex = widget.initialIndex.clamp(0, widget.wallpapers.length - 1);
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.82,
    );
    _initializeVideo(_selectedIndex, play: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecacheDependencies) return;
    _didPrecacheDependencies = true;
    _preloadNearby(_selectedIndex);
  }

  Future<void> _initializeVideo(int index, {required bool play}) async {
    if (index < 0 || index >= widget.wallpapers.length) return;
    _videoErrors.remove(index);

    final existing = _controllers[index];
    if (existing != null) {
      if (play) await existing.play();
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.wallpapers[index].imageUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controllers[index] = controller;

    try {
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.initialize().timeout(const Duration(seconds: 18));
      if (!identical(_controllers[index], controller)) {
        await controller.dispose();
        return;
      }
      if (play && !_routePaused) await controller.play();
      if (mounted) setState(() {});
    } catch (error, stackTrace) {
      AppLogger.error('Video initialization failed', error: error, stackTrace: stackTrace);
      _controllers.remove(index);
      await controller.dispose();

      // Only show error UI for non-timeout failures
      final isTimeout = error is TimeoutException;
      if (!isTimeout) {
        _videoErrors[index] = error is VideoPlaybackException
            ? error.message
            : 'Video failed to load. Please try again.';
      }
      if (mounted) setState(() {});
    }
    }


  // void _preloadNearby(int index) {
  //   final keep = {index - 1, index, index + 1};
  //   final disposeIndexes = _controllers.keys
  //       .where((controllerIndex) => !keep.contains(controllerIndex))
  //       .toList();
  //   for (final disposeIndex in disposeIndexes) {
  //     _controllers.remove(disposeIndex)?.dispose();
  //   }
  //
  //   for (final nearbyIndex in [index - 1, index + 1]) {
  //     if (nearbyIndex >= 0 && nearbyIndex < widget.wallpapers.length) {
  //       precacheImage(
  //         CachedNetworkImageProvider(
  //           widget.wallpapers[nearbyIndex].thumbnailUrl,
  //         ),
  //         context,
  //       );
  //       _initializeVideo(nearbyIndex, play: false);
  //     }
  //   }
  // }
  void _preloadNearby(int index) {
    // Dispose controllers that are too far away
    final keep = {index - 1, index, index + 1};
    final disposeIndexes = _controllers.keys
        .where((i) => !keep.contains(i))
        .toList();
    for (final i in disposeIndexes) {
      _controllers.remove(i)?.dispose();
    }

    // Only precache thumbnails — don't pre-initialize video codecs
    for (final nearbyIndex in [index - 1, index + 1]) {
      if (nearbyIndex >= 0 && nearbyIndex < widget.wallpapers.length) {
        precacheImage(
          CachedNetworkImageProvider(
            widget.wallpapers[nearbyIndex].thumbnailUrl,
          ),
          context,
        );
        // Removed: _initializeVideo(nearbyIndex, play: false)
      }
    }
  }
  Future<void> _selectWallpaper(int index) async {
    if (index == _selectedIndex) return;
    if (!mounted) return;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  // Future<void> _onPageChanged(int index) async {
  //   _controllers[_selectedIndex]?.pause();
  //   if (!mounted) return;
  //   setState(() => _selectedIndex = index);
  //   await _initializeVideo(index, play: true);
  //   if (!mounted) return;
  //   _preloadNearby(index);
  // }

  Future<void> _retryVideo(int index) async {
    _controllers.remove(index)?.dispose();
    if (mounted) {
      setState(() {
        _videoErrors.remove(index);
      });
    }
    await _initializeVideo(index, play: index == _selectedIndex);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _controllers[_selectedIndex]?.pause();
      return;
    }
    if (state == AppLifecycleState.resumed && !_routePaused) {
      _controllers[_selectedIndex]?.play();
    }
  }

  void _pauseCurrentVideo() {
    _routePaused = true;
    _controllers[_selectedIndex]?.pause();
  }

  void _resumeCurrentVideo() {
    _routePaused = false;
    _controllers[_selectedIndex]?.play();
  }

  @override
  void dispose() {
    _pageChangeDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _applyService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      // onPopInvokedWithResult: (didPop, result) {
      //   if (didPop) return;
      //   ExitDialog.show(context);
      // },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const Text(
            'Live Wallpapers',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.wallpapers.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final wallpaper = widget.wallpapers[index];
                    final active = index == _selectedIndex;
                    return AnimatedScale(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      scale: active ? 1 : 0.92,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 28, 8, 20),
                        child: _PreviewCard(
                          wallpaper: wallpaper,
                          controller: _controllers[index],
                          active: active,
                          errorMessage: _videoErrors[index],
                          onRetry: () => _retryVideo(index),
                          onExpandOpen: _pauseCurrentVideo,
                          onExpandClosed: _resumeCurrentVideo,
                        ),
                      ),
                    );
                  },
                ),
              ),
              WallpaperThumbnailStrip(
                wallpapers: widget.wallpapers,
                selectedIndex: _selectedIndex,
                onSelected: _selectWallpaper,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.wallpaper,
    required this.controller,
    required this.active,
    required this.errorMessage,
    required this.onRetry,
    required this.onExpandOpen,
    required this.onExpandClosed,
  });

  final WallpaperModel wallpaper;
  final VideoPlayerController? controller;
  final bool active;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onExpandOpen;
  final VoidCallback onExpandClosed;

  @override
  Widget build(BuildContext context) {
    final ready = controller?.value.isInitialized == true;
    final hasError = errorMessage != null;

    return Hero(
      tag: 'wallpaper-${wallpaper.id}',
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // ── Video / thumbnail card ──────────────────────────────
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: ready
                          ? FittedBox(
                        key: const ValueKey('video'),
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller!.value.size.width,
                          height: controller!.value.size.height,
                          child: VideoPlayer(controller!),
                        ),
                      )
                          : SizedBox.expand(
                        key: const ValueKey('thumb'),
                        child: CachedNetworkImage(
                          imageUrl: wallpaper.thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                          const VideoLoader(),
                          errorWidget: (context, url, error) =>
                          const ColoredBox(
                            color: Colors.black,
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                    if (hasError)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.62),
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.play_disabled_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: onRetry,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Expand button — always outside the card ─────────────
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: OpenContainer<void>(
                transitionType: ContainerTransitionType.fadeThrough,
                transitionDuration: const Duration(milliseconds: 460),
                closedElevation: 0,
                openElevation: 0,
                closedColor: Colors.black,
                openColor: Colors.white,
                onClosed: (_) => onExpandClosed(),
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(34),
                ),
                openBuilder: (context, action) => FullscreenPreviewScreen(
                  wallpaper: wallpaper,
                ),
                closedBuilder: (_, openContainer) {
                  return InkWell(
                    onTap: () {
                      onExpandOpen();
                      openContainer();
                    },
                    borderRadius: BorderRadius.circular(34),
                    child: const SizedBox(
                      height: 58,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fullscreen_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Expand',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}