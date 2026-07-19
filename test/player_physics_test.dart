import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:super_mario/engine/base_game.dart';
import 'package:super_mario/engine/components/player.dart';
import 'package:super_mario/constants/physics_constants.dart';
import 'package:super_mario/features/game_state_provider.dart';
import 'game_state_test.dart'; // reuse MockSaveService and MockAudioService

class TestGame extends BaseGame {
  TestGame({required super.ref});
}

class MockWidgetRef extends Mock implements WidgetRef {}

void main() {
  late ProviderContainer container;
  late TestGame game;
  late Player player;
  late MockWidgetRef mockRef;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        saveServiceProvider.overrideWithValue(MockSaveService()),
        audioServiceProvider.overrideWithValue(MockAudioService()),
      ],
    );

    mockRef = MockWidgetRef();
    // Stub the exact provider reads used in the Player component
    when(() => mockRef.read(audioServiceProvider)).thenReturn(container.read(audioServiceProvider));
    when(() => mockRef.read(progressProvider)).thenReturn(container.read(progressProvider));
    when(() => mockRef.read(progressProvider.notifier)).thenReturn(container.read(progressProvider.notifier));
    
    // We instantiate game and player components directly
    game = TestGame(ref: mockRef);
    player = Player(position: Vector2(100, 300));
    
    game.add(player);
    game.update(0); // process lifecycle queue to set gameRef and mount the player
  });

  group('Player Controller Physics Unit Tests', () {
    test('Verify gravity pulls player down in mid-air', () {
      player.isGrounded = false;
      player.velocity = Vector2(0, 0);

      // Trigger update tick (100ms)
      player.update(0.1);

      expect(player.velocity.y, greaterThan(0));
      expect(player.position.y, greaterThan(300));
    });

    test('Verify jumping applies upward vertical force', () {
      player.isGrounded = true;
      player.jumpCount = 0;
      player.jumpInputPressed = true;

      // Trigger update tick
      player.update(0.01);

      expect(player.velocity.y, lessThan(0));
      expect(player.jumpCount, 1);
      expect(player.isGrounded, isFalse);
    });

    test('Verify double jump applies mid-air boost', () {
      player.isGrounded = false;
      player.jumpCount = 1;
      player.canDoubleJump = true;
      player.jumpInputPressed = true;

      // Trigger update tick
      player.update(0.01);

      expect(player.velocity.y, lessThan(0));
      expect(player.jumpCount, 2);
      expect(player.canDoubleJump, isFalse);
    });

    test('Verify crouching reduces player size and scale', () {
      player.isGrounded = true;
      player.crouchInputPressed = true;

      // Trigger update tick
      player.update(0.01);

      expect(player.isCrouching, isTrue);
      expect(player.size.y, 20); // Crouch height constant

      player.crouchInputPressed = false;
      player.update(0.01);

      expect(player.isCrouching, isFalse);
      expect(player.size.y, 38); // Restored normal height
    });

    test('Verify dashing triggers dash speed and locks gravity', () {
      player.isGrounded = true;
      player.facingDirection = 1;
      player.dashInputPressed = true;
      player.dashCooldownLeft = 0.0;

      // Trigger update tick
      player.update(0.01);

      expect(player.isDashing, isTrue);
      expect(player.velocity.x, PhysicsConstants.dashSpeed);
      expect(player.velocity.y, 0); // Gravity is locked
    });
  });
}
