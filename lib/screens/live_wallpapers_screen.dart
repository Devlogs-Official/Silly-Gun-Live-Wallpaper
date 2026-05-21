import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../providers/wallpaper_provider.dart';
import '../services/connectivity_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/exit_dialog.dart';
import '../widgets/no_internet_widget.dart';
import '../widgets/retry_widget.dart';
import '../widgets/shimmer_grid.dart';
import '../widgets/wallpaper_grid_item.dart';
import 'wallpaper_preview_screen.dart';

class LiveWallpapersScreen extends StatefulWidget {
  const LiveWallpapersScreen({super.key});

  @override
  State<LiveWallpapersScreen> createState() => _LiveWallpapersScreenState();
}

class _LiveWallpapersScreenState extends State<LiveWallpapersScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchInitial();
    });
  }

  Future<void> _fetchInitial() async {
    final connectivity = context.read<ConnectivityService>();
    final provider = context.read<WallpaperProvider>();
    final hasInternet = await connectivity.refresh();
    if (!mounted) return;

    if (!hasInternet) {
      provider.restoreCachedWallpapers();
      if (provider.wallpapers.isEmpty) {
        AppSnackbar.internet('No internet connection.');
      }
      return;
    }

    await provider.fetchInitialWallpapers();
  }

  Future<void> _refreshWallpapers() async {
    final connectivity = context.read<ConnectivityService>();
    final hasInternet = await connectivity.refresh();
    if (!mounted) return;

    if (!hasInternet) {
      context.read<WallpaperProvider>().restoreCachedWallpapers();
      return;
    }

    await context.read<WallpaperProvider>().refreshWallpapers();
  }

  Future<void> _fetchMoreWallpapers() async {
    final provider = context.read<WallpaperProvider>();
    if (provider.isLoading || provider.isLoadingMore || !provider.hasMore) return;

    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.hasInternet && !(await connectivity.refresh())) {
      AppSnackbar.internet('Connect to the internet to load more wallpapers.');
      return;
    }

    await provider.fetchMoreWallpapers();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 600) {
      _fetchMoreWallpapers();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ExitDialog.show(context);
      },
      child: Scaffold(
        backgroundColor:  Colors.white,
        appBar: AppBar(
          title: const Text('Live Wallpapers'),
          centerTitle: true,
          // leading: IconButton(
          //   onPressed: () => ExitDialog.show(context),
          //   icon: const Icon(Icons.arrow_back_ios_new_rounded),
          // ),
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        body: Consumer2<WallpaperProvider, ConnectivityService>(
          builder: (context, provider, connectivity, _) {
            final noData = provider.wallpapers.isEmpty;
            if (provider.isLoading && noData) return const ShimmerGrid();

            if (!connectivity.hasInternet && noData) {
              return NoInternetWidget(
                onRetry: _fetchInitial,
                onExit: () => ExitDialog.show(context),
              );
            }

            if (provider.errorMessage != null && noData) {
              return RetryWidget(
                message: provider.errorMessage!,
                onRetry: _fetchInitial,
              );
            }

            if (!provider.isLoading && noData) {
              return _EmptyState(onRefresh: _refreshWallpapers);
            }

            return _WallpaperGrid(
              scrollController: _scrollController,
              onRefresh: _refreshWallpapers,
            );
          },
        ),
      ),
    );
  }
}

class _WallpaperGrid extends StatelessWidget {
  const _WallpaperGrid({
    required this.scrollController,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      color: const Color(0xFF8FE3CF),
      backgroundColor: const Color(0xFF161B24),
      onRefresh: onRefresh,
      child: Selector<WallpaperProvider, int>(
        selector: (_, provider) =>
            provider.wallpapers.length + (provider.isLoadingMore ? 1 : 0),
        builder: (context, itemCount, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 48) {
                return const SizedBox.shrink();
              }

              return MasonryGridView.count(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  final provider = context.read<WallpaperProvider>();
                  if (index >= provider.wallpapers.length) {
                    return const _BottomLoader();
                  }

                  return WallpaperGridItem(
                    key: ValueKey(provider.wallpapers[index].id),
                    wallpaper: provider.wallpapers[index],
                    index: index,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WallpaperPreviewScreen(
                            wallpaper: provider.wallpapers[index],
                            wallpapers: provider.wallpapers,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 96,
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: Color(0xFF8FE3CF),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      color: const Color(0xFF8FE3CF),
      backgroundColor: const Color(0xFF161B24),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.26),
          Text(
            'No wallpapers found',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
