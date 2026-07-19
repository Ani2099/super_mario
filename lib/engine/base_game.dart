import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/game_state_provider.dart';
import '../audio/audio_assets.dart';
import 'components/player.dart';
import 'components/platform.dart';

class BaseGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  final WidgetRef ref;

  BaseGame({required this.ref});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Configure camera and viewport to match standard aspect ratio (e.g. 16:9)
    camera.viewport = FixedResolutionViewport(resolution: Vector2(800, 450));

    // 1. Add solid ground and boundary walls
    add(PlatformComponent(position: Vector2(0, 420), size: Vector2(800, 30))); // Ground
    add(PlatformComponent(position: Vector2(0, 0), size: Vector2(20, 450)));   // Left wall
    add(PlatformComponent(position: Vector2(780, 0), size: Vector2(20, 450)));  // Right wall

    // 2. Add floating platforms
    add(PlatformComponent(position: Vector2(100, 320), size: Vector2(150, 20)));
    add(PlatformComponent(position: Vector2(200, 230), size: Vector2(100, 20)));

    // 3. Add a slope (left-to-right rising slope)
    add(SlopeComponent(
      position: Vector2(450, 320),
      size: Vector2(150, 100),
      isLeftToRightUp: true,
    ));
    // Flat top platform after the slope
    add(PlatformComponent(position: Vector2(600, 320), size: Vector2(180, 100)));

    // 4. Add moving platform
    add(MovingPlatformComponent(
      startPosition: Vector2(350, 180),
      endPosition: Vector2(550, 180),
      size: Vector2(80, 15),
      speed: 60,
    ));

    // 5. Add hazard spikes
    add(HazardComponent(position: Vector2(300, 400), size: Vector2(100, 20)));

    // 6. Spawn the Player
    final player = Player(position: Vector2(100, 380));
    add(player);

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
