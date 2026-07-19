import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/colors.dart';
import '../../../constants/physics_constants.dart';
import '../../features/game_state_provider.dart';
import '../base_game.dart';
import 'platform.dart';

enum PlayerAnimationState {
  idle,
  walk,
  run,
  jump,
  doubleJump,
  fall,
  wallSlide,
  crouch,
  dash,
  hurt,
  death,
}

class Player extends PositionComponent with CollisionCallbacks, KeyboardHandler, HasGameRef<BaseGame> {
  // Movement State
  Vector2 velocity = Vector2.zero();
  bool isGrounded = false;
  bool isWallSliding = false;
  int wallSide = 0; // -1: wall is on left, 1: wall is on right, 0: no wall
  int facingDirection = 1; // -1: left, 1: right

  // Abilities
  int jumpCount = 0;
  bool canDoubleJump = true;
  double dashTimeLeft = 0.0;
  double dashCooldownLeft = 0.0;
  bool isDashing = false;
  bool isCrouching = false;
  
  // Animation state
  PlayerAnimationState animationState = PlayerAnimationState.idle;
  double animationTimer = 0.0;
  double spinAngle = 0.0; // rotation used for double-jump spin
  
  // Hitbox
  late final RectangleHitbox _hitbox;
  final Vector2 _normalSize = Vector2(24, 38);
  final Vector2 _crouchSize = Vector2(24, 20);

  // Inputs (Keyboard / Touchscreen virtual buttons)
  double horizontalInput = 0.0;
  bool jumpInputPressed = false;
  bool runInputPressed = false;
  bool dashInputPressed = false;
  bool crouchInputPressed = false;

  // Hurt / Invulnerability
  double hurtTimeLeft = 0.0;
  bool isDead = false;
  double deathTimer = 0.0;

  // Standing platform momentum
  Vector2 platformVelocity = Vector2.zero();

  Player({required Vector2 position}) : super(position: position, size: Vector2(24, 38)) {
    anchor = Anchor.bottomCenter;
    _hitbox = RectangleHitbox()..collisionType = CollisionType.active;
    add(_hitbox);
  }

  @override
  void update(double dt) {
    super.update(dt);
    animationTimer += dt;

    if (isDead) {
      _updateDeath(dt);
      return;
    }

    _updateTimers(dt);
    _applyInputs(dt);
    _applyPhysics(dt);
    _resolveCollisions(dt);
    _determineAnimationState();
  }

  void _updateTimers(double dt) {
    if (dashTimeLeft > 0) {
      dashTimeLeft -= dt;
      if (dashTimeLeft <= 0) {
        isDashing = false;
        velocity.x = 0;
      }
    }
    if (dashCooldownLeft > 0) {
      dashCooldownLeft -= dt;
    }
    if (hurtTimeLeft > 0) {
      hurtTimeLeft -= dt;
    }
  }

  void _applyInputs(double dt) {
    if (isDashing) return;

    // 1. Dashing Trigger
    if (dashInputPressed && dashCooldownLeft <= 0 && !isCrouching) {
      isDashing = true;
      dashTimeLeft = PhysicsConstants.dashDuration;
      dashCooldownLeft = PhysicsConstants.dashCooldown;
      velocity.x = facingDirection * PhysicsConstants.dashSpeed;
      velocity.y = 0; // ignore gravity during dash
      gameRef.ref.read(audioServiceProvider).playSfx('sfx/dash.wav');
      return;
    }

    // 2. Crouching Trigger
    if (crouchInputPressed && isGrounded) {
      if (!isCrouching) {
        isCrouching = true;
        size = _crouchSize;
      }
    } else {
      if (isCrouching) {
        // Only stand up if there's space above (assumed for now)
        isCrouching = false;
        size = _normalSize;
      }
    }

    // 3. Horizontal Walk / Run
    double maxSpeed = isCrouching
        ? PhysicsConstants.walkSpeed * 0.5
        : (runInputPressed ? PhysicsConstants.runSpeed : PhysicsConstants.walkSpeed);

    if (horizontalInput != 0) {
      facingDirection = horizontalInput > 0 ? 1 : -1;
      
      // Air acceleration is slower
      double accel = isGrounded ? PhysicsConstants.acceleration : PhysicsConstants.acceleration * PhysicsConstants.airControl;
      velocity.x += horizontalInput * accel * dt;
      velocity.x = velocity.x.clamp(-maxSpeed, maxSpeed);
    } else {
      // Decelerate/Friction
      double decel = isGrounded ? PhysicsConstants.friction : PhysicsConstants.friction * 0.3;
      if (velocity.x > 0) {
        velocity.x = (velocity.x - decel * dt).clamp(0, double.infinity);
      } else if (velocity.x < 0) {
        velocity.x = (velocity.x + decel * dt).clamp(-double.infinity, 0);
      }
    }

    // 4. Jumping
    if (jumpInputPressed) {
      jumpInputPressed = false; // consume input
      if (isGrounded) {
        _jump(PhysicsConstants.jumpForce);
      } else if (isWallSliding) {
        _wallJump();
      } else if (canDoubleJump && jumpCount < 2) {
        _jump(PhysicsConstants.doubleJumpForce, isDouble: true);
      }
    }
  }

  void _jump(double force, {bool isDouble = false}) {
    velocity.y = force;
    isGrounded = false;
    jumpCount++;
    if (isDouble) {
      canDoubleJump = false;
      spinAngle = 0.0;
      gameRef.ref.read(audioServiceProvider).playSfx('sfx/jump.wav'); // Double jump SFX
    } else {
      gameRef.ref.read(audioServiceProvider).playSfx('sfx/jump.wav');
    }
  }

  void _wallJump() {
    velocity.x = -wallSide * PhysicsConstants.wallJumpXForce;
    velocity.y = PhysicsConstants.wallJumpYForce;
    facingDirection = -wallSide;
    isWallSliding = false;
    jumpCount = 1; // wall jump counts as first jump, allows double jump
    canDoubleJump = true;
    gameRef.ref.read(audioServiceProvider).playSfx('sfx/jump.wav');
  }

  void _applyPhysics(double dt) {
    if (isDashing) return;

    // Apply gravity
    double grav = PhysicsConstants.gravity;
    
    // Slide slowly on walls
    double terminalVelocity = PhysicsConstants.maxFallSpeed;
    if (isWallSliding && velocity.y > 0) {
      terminalVelocity = PhysicsConstants.wallSlideSpeed;
    }

    velocity.y += grav * dt;
    velocity.y = velocity.y.clamp(-double.infinity, terminalVelocity);

    // Apply platform momentum
    Vector2 netVelocity = velocity + platformVelocity;
    position += netVelocity * dt;
  }

  void _resolveCollisions(double dt) {
    // We assume bounding resolution handles grounded states
    // In complex engines this is done using overlapping intersections depth calculations.
    // For our clean framework, we will rely on Flame collision callbacks to resolve position.
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (isDead) return;

    if (other is PlatformComponent || other is MovingPlatformComponent) {
      // Find intersection depth
      final rectPlayer = _hitbox.toAbsoluteRect();
      final rectPlatform = other.absolutePosition & other.size;
      
      final overlap = rectPlayer.intersect(rectPlatform);
      if (overlap.isEmpty) return;

      // Handle Moving Platform momentum transfer
      if (other is MovingPlatformComponent) {
        platformVelocity = other.velocity;
      }

      // Vertical vs Horizontal collision resolution
      if (overlap.width > overlap.height) {
        // Vertical collision
        if (rectPlayer.bottom >= rectPlatform.top && rectPlayer.center.dy < rectPlatform.top) {
          // Landing on top
          position.y = rectPlatform.top;
          velocity.y = 0;
          isGrounded = true;
          jumpCount = 0;
          canDoubleJump = true;
          isWallSliding = false;
        } else if (rectPlayer.top <= rectPlatform.bottom && rectPlayer.center.dy > rectPlatform.bottom) {
          // Hitting head
          position.y = rectPlatform.bottom + size.y;
          velocity.y = 0;
        }
      } else {
        // Horizontal collision
        if (rectPlayer.right >= rectPlatform.left && rectPlayer.center.dx < rectPlatform.left) {
          position.x = rectPlatform.left - size.x / 2;
          velocity.x = 0;
          if (!isGrounded && velocity.y > 0) {
            isWallSliding = true;
            wallSide = 1;
          }
        } else if (rectPlayer.left <= rectPlatform.right && rectPlayer.center.dx > rectPlatform.right) {
          position.x = rectPlatform.right + size.x / 2;
          velocity.x = 0;
          if (!isGrounded && velocity.y > 0) {
            isWallSliding = true;
            wallSide = -1;
          }
        }
      }
    } else if (other is SlopeComponent) {
      // Slope height mapping algorithm
      final rectPlayer = _hitbox.toAbsoluteRect();
      final relativeX = (rectPlayer.center.dx - other.absolutePosition.x).clamp(0, other.size.x);
      
      // Calculate Y coordinate on the slope line
      double slopeTopY;
      if (other.isLeftToRightUp) {
        // Slope goes Up from left to right: Y decreases as X increases (in Flame coordinates, Y=0 is Top)
        slopeTopY = other.absolutePosition.y + (other.size.y - (relativeX / other.size.x) * other.size.y);
      } else {
        // Slope goes Down from left to right: Y increases as X increases
        slopeTopY = other.absolutePosition.y + ((relativeX / other.size.x) * other.size.y);
      }

      if (rectPlayer.bottom >= slopeTopY - 6) {
        position.y = slopeTopY;
        velocity.y = 0;
        isGrounded = true;
        jumpCount = 0;
        canDoubleJump = true;
      }
    } else if (other is HazardComponent) {
      takeDamage();
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);
    if (other is PlatformComponent || other is MovingPlatformComponent) {
      if (other is MovingPlatformComponent) {
        platformVelocity = Vector2.zero();
      }
      isGrounded = false;
      isWallSliding = false;
      wallSide = 0;
    } else if (other is SlopeComponent) {
      isGrounded = false;
    }
  }

  // Triggered externally when taking damage
  void takeDamage() {
    if (hurtTimeLeft > 0 || isDead) return;
    
    hurtTimeLeft = 1.0; // 1 second invulnerability
    velocity.x = -facingDirection * 150.0;
    velocity.y = -200.0; // knockback bounce
    isGrounded = false;
    
    gameRef.ref.read(audioServiceProvider).playSfx('sfx/hurt.wav');
    
    // Sync with Riverpod save game lives
    final progress = gameRef.ref.read(progressProvider);
    if (progress != null && progress.lives <= 1) {
      triggerDeath();
    } else {
      gameRef.ref.read(progressProvider.notifier).loseLife();
    }
  }

  void triggerDeath() {
    isDead = true;
    velocity = Vector2(0, -350); // launch into air
    deathTimer = 0.0;
    gameRef.ref.read(audioServiceProvider).playSfx('sfx/death.wav');
  }

  void _updateDeath(double dt) {
    deathTimer += dt;
    velocity.y += PhysicsConstants.gravity * dt;
    position += velocity * dt;
    spinAngle += 5 * dt;

    if (deathTimer > 2.5) {
      // Respawn: reset lives, score penalty, or load slot
      isDead = false;
      spinAngle = 0;
      velocity = Vector2.zero();
      position = Vector2(100, 300); // return to start
      gameRef.ref.read(progressProvider.notifier).resetProgress(); // reset to 3 lives
    }
  }

  void _determineAnimationState() {
    if (hurtTimeLeft > 0) {
      animationState = PlayerAnimationState.hurt;
    } else if (isDashing) {
      animationState = PlayerAnimationState.dash;
    } else if (isCrouching) {
      animationState = PlayerAnimationState.crouch;
    } else if (isWallSliding) {
      animationState = PlayerAnimationState.wallSlide;
    } else if (velocity.y < 0) {
      animationState = jumpCount == 2 ? PlayerAnimationState.doubleJump : PlayerAnimationState.jump;
    } else if (velocity.y > 0 && !isGrounded) {
      animationState = PlayerAnimationState.fall;
    } else if (velocity.x.abs() > PhysicsConstants.walkSpeed + 10) {
      animationState = PlayerAnimationState.run;
    } else if (velocity.x.abs() > 10) {
      animationState = PlayerAnimationState.walk;
    } else {
      animationState = PlayerAnimationState.idle;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Apply procedural animation transformations (spin, squish)
    canvas.save();

    // Center character canvas for rotations
    canvas.translate(0, -size.y / 2);

    if (animationState == PlayerAnimationState.doubleJump || isDead) {
      canvas.rotate(spinAngle);
    }

    final rect = Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y);
    
    // Resolve skin color
    Color bodyColor = GameColors.accentCyan;
    final activeSkin = gameRef.ref.read(progressProvider)?.activeSkin;
    if (activeSkin == 'ninja_skin') bodyColor = Colors.purpleAccent;
    if (activeSkin == 'retro_skin') bodyColor = GameColors.accentOrange;
    if (activeSkin == 'cosmic_skin') bodyColor = GameColors.accentPink;

    // Apply flash if hurt
    if (hurtTimeLeft > 0 && (animationTimer * 15).toInt() % 2 == 0) {
      bodyColor = Colors.redAccent;
    }

    final paint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw the procedural character (retro blocky look)
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);

    // Draw faces/eyes to show walking direction
    final eyePaint = Paint()..color = Colors.black;
    final dir = facingDirection.toDouble();
    if (isCrouching) {
      // Crouching eye slit
      canvas.drawRect(Rect.fromLTWH(dir * 4 - 2, -4, 4, 1.5), eyePaint);
    } else {
      // Normal eyes
      canvas.drawCircle(Offset(dir * 4, -8), 2, eyePaint);
      canvas.drawCircle(Offset(dir * 4 + dir * 6, -8), 2, eyePaint);
    }

    // Draw motion trail effect if dashing
    if (animationState == PlayerAnimationState.dash) {
      final trailPaint = Paint()
        ..color = GameColors.accentCyan.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(-dir * 24, -size.y / 2, size.x, size.y), trailPaint);
    }

    canvas.restore();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (isDead) return false;

    // Walk/Run inputs
    horizontalInput = 0.0;
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      horizontalInput -= 1.0;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      horizontalInput += 1.0;
    }

    // Jump Input
    if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.arrowUp)) {
      jumpInputPressed = true;
    }
    // Variable Jump Cut (release jump key early to cut vertical speed)
    if (event is KeyUpEvent && (event.logicalKey == LogicalKeyboardKey.space || event.logicalKey == LogicalKeyboardKey.keyW || event.logicalKey == LogicalKeyboardKey.arrowUp)) {
      if (velocity.y < PhysicsConstants.minJumpForce) {
        velocity.y = PhysicsConstants.minJumpForce;
      }
    }

    // Run Boost Input
    runInputPressed = keysPressed.contains(LogicalKeyboardKey.shiftLeft) || keysPressed.contains(LogicalKeyboardKey.shiftRight);

    // Crouch Input
    crouchInputPressed = keysPressed.contains(LogicalKeyboardKey.keyS) || keysPressed.contains(LogicalKeyboardKey.arrowDown);

    // Dash Input
    if (event is KeyDownEvent && (event.logicalKey == LogicalKeyboardKey.keyJ || event.logicalKey == LogicalKeyboardKey.keyZ || event.logicalKey == LogicalKeyboardKey.controlLeft)) {
      dashInputPressed = true;
    }
    if (event is KeyUpEvent && (event.logicalKey == LogicalKeyboardKey.keyJ || event.logicalKey == LogicalKeyboardKey.keyZ || event.logicalKey == LogicalKeyboardKey.controlLeft)) {
      dashInputPressed = false;
    }

    return true;
  }
}
