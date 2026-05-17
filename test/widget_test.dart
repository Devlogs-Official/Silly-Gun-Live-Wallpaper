import 'package:flutter_test/flutter_test.dart';
import 'package:silly_gun_live_wallpaper/models/wallpaper_model.dart';

void main() {
  test('WallpaperModel parses API JSON safely', () {
    final wallpaper = WallpaperModel.fromJson(const {
      'id': 50,
      'name': 'wallpaper_live_050',
      'image_url':
          'https://api.devlogs.pro/apps/sillySmileGunLiveWallpapers/live/original/wallpaper_live_050.mp4',
      'thumbnail_url':
          'https://api.devlogs.pro/apps/sillySmileGunLiveWallpapers/live/thumbnail/wallpaper_live_050.webp',
      'created_at': '2026-05-16 10:21:26',
    });

    expect(wallpaper.id, 50);
    expect(wallpaper.name, 'wallpaper_live_050');
    expect(wallpaper.imageUrl.endsWith('.mp4'), isTrue);
    expect(wallpaper.thumbnailUrl.endsWith('.webp'), isTrue);
    expect(wallpaper.createdAt, isNotNull);
  });
}
