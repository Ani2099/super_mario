import 'package:flame/cache.dart';
import 'package:flame_audio/flame_audio.dart';
import '../audio/audio_assets.dart';
import '../utils/logger.dart';

class GameAssetLoader {
  // Preload UI and basic sprite sheet images
  static Future<void> preloadImages(Images imagesCache) async {
    try {
      GameLogger.info('Preloading sprite atlases...');
      // In future prompts, we will add sprite sheet files here, e.g.:
      // await imagesCache.load('character_sheet.png');
    } catch (e) {
      GameLogger.error('Failed to preload images: $e');
    }
  }

  // Preload sound effects into cache for instant playback
  static Future<void> preloadAudio() async {
    try {
      GameLogger.info('Preloading audio assets...');
      final sfxList = [
        AudioAssets.sfxJump,
        AudioAssets.sfxCoin,
        AudioAssets.sfxStomp,
        AudioAssets.sfxPowerup,
        AudioAssets.sfxPowerupAppears,
        AudioAssets.sfxHurt,
        AudioAssets.sfxDeath,
        AudioAssets.sfxDash,
        AudioAssets.sfxBlockBreak,
        AudioAssets.sfxPipe,
        AudioAssets.sfxGameOver,
      ];
      
      await FlameAudio.audioCache.loadAll(sfxList);
    } catch (e) {
      GameLogger.error('Failed to preload audio cache: $e');
    }
  }
}
