import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_logger.dart';
import 'core/error_handler.dart';
import 'providers/wallpaper_provider.dart';
import 'screens/live_wallpapers_screen.dart';
import 'screens/splash_screen.dart';
import 'services/connectivity_service.dart';
import 'services/wallpaper_cache_service.dart';
import 'widgets/app_snackbar.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      ErrorHandler.initialize();

      final cacheService = WallpaperCacheService();
      final connectivityService = ConnectivityService();
      runApp(
        SillyGunWallpapersApp(
          cacheService: cacheService,
          connectivityService: connectivityService,
        ),
      );
    },
    ErrorHandler.handleZoneError,
  );
}

class SillyGunWallpapersApp extends StatefulWidget {
  const SillyGunWallpapersApp({
    super.key,
    required this.cacheService,
    required this.connectivityService,
  });

  final WallpaperCacheService cacheService;
  final ConnectivityService connectivityService;

  @override
  State<SillyGunWallpapersApp> createState() => _SillyGunWallpapersAppState();
}

class _SillyGunWallpapersAppState extends State<SillyGunWallpapersApp> {
  static const _minimumSplashDuration = Duration(seconds: 5);

  late final WallpaperProvider _wallpaperProvider = WallpaperProvider(
    cacheService: widget.cacheService,
  );
  late final Future<void> _initialization = _initializeServices();

  Future<void> _initializeServices() async {
    final minimumSplash = Future<void>.delayed(_minimumSplashDuration);

    try {
      await widget.cacheService.init();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Hive cache initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await widget.connectivityService.initialize();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Connectivity initialization failed',
        error: error,
        stackTrace: stackTrace,
      );
    }

    await minimumSplash;
  }

  @override
  void dispose() {
    _wallpaperProvider.dispose();
    widget.connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>.value(
          value: widget.connectivityService,
        ),
        ChangeNotifierProvider<WallpaperProvider>.value(
          value: _wallpaperProvider,
        ),
      ],
      child: MaterialApp(
        navigatorKey: ErrorHandler.navigatorKey,
        scaffoldMessengerKey: AppSnackbar.messengerKey,
        debugShowCheckedModeBanner: false,
        title: 'Live Wallpapers',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: 'Nunito',
          scaffoldBackgroundColor: const Color(0xFF07080C),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8FE3CF),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF07080C),
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF11151D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
        home: FutureBuilder<void>(
          future: _initialization,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SplashScreen();
            }

            return const LiveWallpapersScreen();
          },
        ),
      ),
    );
  }
}
