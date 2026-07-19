import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/game_state_provider.dart';
import '../audio/audio_assets.dart';

class BaseGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  final WidgetRef ref;

  BaseGame({required this.ref});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Configure camera and viewport to match standard aspect ratio (e.g. 16:9)
    camera.viewport = FixedResolutionViewport(resolution: Vector2(800, 450));

    // Play background music (Overworld theme)
    ref.read(audioServiceProvider).playBgm(AudioAssets.bgmOverworld);
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Base game update tick
  }

  // Helper trigger to increment coins from inside Flame components
  void onCoinCollected() {
    ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
    ref.read(progressProvider.notifier).addCoins(1);
    ref.read(progressProvider.notifier).addScore(100);
  }

  // Helper trigger when player dies
  void onPlayerDeath() {
    ref.read(audioServiceProvider).playSfx(AudioAssets.sfxDeath);
    ref.read(progressProvider.notifier).loseLife();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Esc key triggers pause
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      if (paused) {
        resumeEngine();
      } else {
        pauseEngine();
      }
      return KeyEventResult.handled;
    }
    return super.onKeyEvent(event, keysPressed);
  }
}
