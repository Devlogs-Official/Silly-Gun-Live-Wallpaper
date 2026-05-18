// import 'package:animated_text_kit/animated_text_kit.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';
//
// import '../providers/wallpaper_provider.dart';
// import '../services/connectivity_service.dart';
// import '../widgets/no_internet_widget.dart';
// import 'live_wallpapers_screen.dart';
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _controller;
//   late final Animation<double> _scaleAnimation;
//   late final Animation<double> _fadeAnimation;
//   bool _preloadStarted = false;
//   bool _showRetry = false;
//   bool _checkingInternet = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..forward();
//     _scaleAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeOutBack,
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _controller,
//       curve: Curves.easeOut,
//     );
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted || _preloadStarted) return;
//       _preloadStarted = true;
//       _preload();
//     });
//   }
//
//   Future<void> _preload() async {
//     if (mounted) {
//       setState(() {
//         _showRetry = false;
//         _checkingInternet = true;
//       });
//     }
//
//     final startedAt = DateTime.now();
//     final connectivity = context.read<ConnectivityService>();
//     final provider = context.read<WallpaperProvider>();
//     final hasInternet = await connectivity.refresh();
//
//     if (!mounted) return;
//     if (!hasInternet) {
//       provider.restoreCachedWallpapers();
//       if (provider.wallpapers.isNotEmpty) {
//         await _honorMinimumSplashDuration(startedAt);
//         if (!mounted) return;
//         _goToHome();
//         return;
//       }
//
//       setState(() {
//         _showRetry = true;
//         _checkingInternet = false;
//       });
//       return;
//     }
//
//     await provider.fetchInitialWallpapers(forceRefresh: true);
//
//     await _honorMinimumSplashDuration(startedAt);
//
//     if (!mounted) return;
//     if (provider.wallpapers.isEmpty && provider.errorMessage != null) {
//       setState(() {
//         _showRetry = true;
//         _checkingInternet = false;
//       });
//       return;
//     }
//
//     _goToHome();
//   }
//
//   Future<void> _honorMinimumSplashDuration(DateTime startedAt) async {
//     final elapsed = DateTime.now().difference(startedAt);
//     const minimumSplashDuration = Duration(seconds: 2);
//     if (elapsed < minimumSplashDuration) {
//       await Future<void>.delayed(minimumSplashDuration - elapsed);
//     }
//   }
//
//   void _goToHome() {
//     if (!mounted) return;
//     Navigator.of(context).pushReplacement(
//       PageRouteBuilder<void>(
//         transitionDuration: const Duration(milliseconds: 520),
//         pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
//           opacity: animation,
//           child: const LiveWallpapersScreen(),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _exitApp() => SystemNavigator.pop();
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<WallpaperProvider>();
//     final connectivity = context.watch<ConnectivityService>();
//
//     return Scaffold(
//       backgroundColor: const Color(0xFF07080C),
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           const DecoratedBox(
//             decoration: BoxDecoration(
//               gradient: RadialGradient(
//                 center: Alignment(0, -0.35),
//                 radius: 0.9,
//                 colors: [
//                   Color(0xFF16231F),
//                   Color(0xFF07080C),
//                 ],
//               ),
//             ),
//           ),
//           if (_showRetry && !connectivity.hasInternet)
//             NoInternetWidget(
//               isRetrying: _checkingInternet || provider.isLoading,
//               onRetry: _preload,
//               onExit: _exitApp,
//             )
//           else
//           Center(
//             child: FadeTransition(
//               opacity: _fadeAnimation,
//               child: ScaleTransition(
//                 scale: _scaleAnimation,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 28),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Shimmer.fromColors(
//                         baseColor: Colors.white,
//                         highlightColor: const Color(0xFF8FE3CF),
//                         child: Container(
//                           width: 92,
//                           height: 92,
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(26),
//                           ),
//                           child: const Icon(
//                             Icons.wallpaper_rounded,
//                             color: Colors.black,
//                             size: 48,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 26),
//                       AnimatedTextKit(
//                         repeatForever: true,
//                         animatedTexts: [
//                           FadeAnimatedText(
//                             'Live Wallpapers',
//                             textAlign: TextAlign.center,
//                             textStyle: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 30,
//                               fontWeight: FontWeight.w900,
//                               letterSpacing: 0,
//                             ),
//                             duration: const Duration(milliseconds: 1800),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 28),
//                       if (_showRetry) ...[
//                         Text(
//                           provider.errorMessage ?? 'Unable to load wallpapers.',
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                             color: Color(0xFFD7DEE9),
//                             height: 1.4,
//                           ),
//                         ),
//                         const SizedBox(height: 18),
//                         FilledButton.icon(
//                           onPressed: _preload,
//                           icon: const Icon(Icons.refresh_rounded),
//                           label: const Text('Retry'),
//                         ),
//                       ] else
//                         const SizedBox(
//                           width: 30,
//                           height: 30,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2.8,
//                             color: Color(0xFF8FE3CF),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:silly_gun_live_wallpaper/screens/live_wallpapers_screen.dart';
import 'package:video_player/video_player.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(
      'assets/splash.mp4',
    )..initialize().then((_) {
      if (!mounted) return;

      setState(() {});

      _controller
        ..setLooping(true)
        ..setVolume(0)
        ..play();
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    _navigationTimer = Timer(
      const Duration(seconds: 5),
          () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LiveWallpapersScreen(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [

          /// VIDEO BACKGROUND
          if (_controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          else
            Container(color: Colors.black),

          /// DARK OVERLAY
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.82),
                ],
              ),
            ),
          ),

          /// CONTENT
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [

                    const Spacer(),

                    /// APP NAME
                    DefaultTextStyle(
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontFamily: 'Nunito',
                      ),
                      child: AnimatedTextKit(
                        isRepeatingAnimation: false,
                        animatedTexts: [
                          FadeAnimatedText(
                            'Silly Smile Gun Wallpaper',
                            textAlign: TextAlign.center,
                            duration: Duration(milliseconds: 2200),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// SUBTITLE
                    Text(
                      'Best Silly Smile Gun Live Wallpapers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15,
                        height: 1.4,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Nunito',
                      ),
                    ),

                    const SizedBox(height: 60),

                    /// LINEAR LOADER
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: const SizedBox(
                        width: 180,
                        child: LinearProgressIndicator(
                          minHeight: 5,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.redAccent,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}