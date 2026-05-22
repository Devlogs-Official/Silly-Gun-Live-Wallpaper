import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

import '../core/app_logger.dart';
import '../models/wallpaper_model.dart';
import '../services/wallpaper_apply_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/bottom_action_buttons.dart';
import '../widgets/video_loader.dart';

class FullscreenPreviewScreen extends StatefulWidget {
  const FullscreenPreviewScreen({
    super.key,
    required this.wallpaper,
  });

  final WallpaperModel wallpaper;

  @override
  State<FullscreenPreviewScreen> createState() =>
      _FullscreenPreviewScreenState();
}

class _FullscreenPreviewScreenState extends State<FullscreenPreviewScreen> {
  static const String _appName = 'Silly Smile Gun Wallpaper';
  static const String _appLink =
      'https://play.google.com/store/apps/details?id=pro.devlogs.sillygunwallpaper.live';

  late final VideoPlayerController _controller;
  final WallpaperApplyService _applyService = WallpaperApplyService();
  bool _ready = false;
  bool _isApplying = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.wallpaper.imageUrl),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.setLooping(true);
      await _controller.setVolume(0);
      await _controller.initialize();
      await _controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _ready = false);
    }
  }

  Future<void> _shareWallpaper() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      // Download video to a temp file
      final response = await http.get(Uri.parse(widget.wallpaper.imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download video: ${response.statusCode}');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${widget.wallpaper.name.replaceAll(RegExp(r'[^\w]'), '_')}.mp4';
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(response.bodyBytes);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path, mimeType: 'video/mp4')],
          subject: _appName,
          text: '$_appName\n\nDownload the app:\n$_appLink',
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Share failed', error: error, stackTrace: stackTrace);
      if (!mounted) return;
      AppSnackbar.error('Unable to share wallpaper. Please try again.');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // Future<void> _applyWallpaper() async {
  //   if (_isApplying) return;
  //   setState(() => _isApplying = true);
  //   _showApplyingDialog();
  //
  //   try {
  //     final message = await _applyService.applyLiveWallpaper(
  //       videoUrl: widget.wallpaper.imageUrl,
  //       fileName: widget.wallpaper.name,
  //     );
  //     if (!mounted) return;
  //     Navigator.of(context, rootNavigator: true).pop();
  //     AppSnackbar.success(message);
  //   } on WallpaperApplyException catch (error) {
  //     if (!mounted) return;
  //     Navigator.of(context, rootNavigator: true).pop();
  //     AppSnackbar.error(error.message);
  //   } catch (error, stackTrace) {
  //     AppLogger.error(
  //       'Apply wallpaper failed',
  //       error: error,
  //       stackTrace: stackTrace,
  //     );
  //     if (!mounted) return;
  //     Navigator.of(context, rootNavigator: true).pop();
  //     AppSnackbar.error('Unable to apply live wallpaper.');
  //   } finally {
  //     if (mounted) setState(() => _isApplying = false);
  //   }
  // }
  Future<void> _applyWallpaper() async {
    if (_isApplying) return;

    setState(() => _isApplying = true);
    _showApplyingDialog();

    try {
      // Download video first
      final response = await http.get(
        Uri.parse(widget.wallpaper.imageUrl),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download wallpaper');
      }

      // Save temporary file
      final tempDir = await getTemporaryDirectory();

      final file = File(
        '${tempDir.path}/${widget.wallpaper.name}.mp4',
      );

      await file.writeAsBytes(response.bodyBytes);

      // Apply LOCAL FILE
      final message = await _applyService.applyLiveWallpaper(
        videoUrl: file.path,
        fileName: widget.wallpaper.name,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      AppSnackbar.success(message);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Apply wallpaper failed',
        error: error,
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      AppSnackbar.error(
        'Unable to apply live wallpaper.',
      );
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }
  void _showApplyingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xEE11151D),
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _applyService.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              )
            else
              const VideoLoader(borderRadius: 0),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 10,
              left: 14,
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.42),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomActionButtons(
        isApplying: _isApplying,
        isSharing: _isSharing,
        onShare: _shareWallpaper,
        onApply: _applyWallpaper,
      ),
    );
  }
}
