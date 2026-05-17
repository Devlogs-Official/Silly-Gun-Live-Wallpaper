import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_logger.dart';
import 'core/error_handler.dart';
import 'providers/wallpaper_provider.dart';
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
      try {
        await cacheService.init();
      } catch (error, stackTrace) {
        AppLogger.error(
          'Hive cache initialization failed',
          error: error,
          stackTrace: stackTrace,
        );
      }

      final connectivityService = ConnectivityService();
      await connectivityService.initialize();

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

class SillyGunWallpapersApp extends StatelessWidget {
  const SillyGunWallpapersApp({
    super.key,
    required this.cacheService,
    required this.connectivityService,
  });

  final WallpaperCacheService cacheService;
  final ConnectivityService connectivityService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ConnectivityService>(
          create: (_) => connectivityService,
        ),
        ChangeNotifierProvider(
          create: (_) => WallpaperProvider(cacheService: cacheService),
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
        home: const SplashScreen(),
      ),
    );
  }
}
