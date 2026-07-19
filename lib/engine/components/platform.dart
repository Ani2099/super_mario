import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../constants/colors.dart';

// Base Platform class
class PlatformComponent extends PositionComponent with CollisionCallbacks {
  PlatformComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size) {
    // Add Axis-Aligned Bounding Box (AABB) hitbox
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = GameColors.darkPanelCard
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = GameColors.borderNeon
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }
}

// Slope Component
class SlopeComponent extends PositionComponent with CollisionCallbacks {
  final bool isLeftToRightUp; // true: slope goes Up from left to right; false: slope goes Down

  SlopeComponent({
    required Vector2 position,
    required Vector2 size,
    required this.isLeftToRightUp,
  }) : super(position: position, size: size) {
    // We define a triangle hitbox for the slope
    final vertices = isLeftToRightUp
        ? [Vector2(0, size.y), Vector2(size.x, 0), Vector2(size.x, size.y)]
        : [Vector2(0, 0), Vector2(size.x, size.y), Vector2(0, size.y)];

    add(PolygonHitbox(vertices)..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final path = Path();
    if (isLeftToRightUp) {
      path.moveTo(0, size.y);
      path.lineTo(size.x, 0);
      path.lineTo(size.x, size.y);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.x, size.y);
      path.lineTo(0, size.y);
    }
    path.close();

    final paint = Paint()
      ..color = GameColors.darkPanelCard.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = GameColors.accentCyan.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }
}

// Moving Platform Component
class MovingPlatformComponent extends PositionComponent with CollisionCallbacks {
  final Vector2 startPosition;
  final Vector2 endPosition;
  final double speed;
  
  Vector2 velocity = Vector2.zero();
  int _direction = 1; // 1: towards endPosition, -1: towards startPosition

  MovingPlatformComponent({
    required this.startPosition,
    required this.endPosition,
    required Vector2 size,
    required this.speed,
  }) : super(position: startPosition.clone(), size: size) {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    final target = _direction == 1 ? endPosition : startPosition;
    final toTarget = target - position;
    final distance = toTarget.length;
    
    if (distance <= speed * dt) {
      // Reached destination, toggle direction
      position = target.clone();
      _direction = -_direction;
      velocity = Vector2.zero();
    } else {
      // Move towards target
      final dir = toTarget.normalized();
      velocity = dir * speed;
      position += velocity * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = GameColors.darkPanelCard
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = GameColors.accentGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);

    // Render motion lines on top to show it's moving
    final linePaint = Paint()
      ..color = GameColors.accentGreen.withOpacity(0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(size.x * 0.2, size.y * 0.5), Offset(size.x * 0.8, size.y * 0.5), linePaint);
  }
}

// Hazard Component (Spikes)
class HazardComponent extends PositionComponent with CollisionCallbacks {
  HazardComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size) {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final paint = Paint()
      ..color = GameColors.accentPink
      ..style = PaintingStyle.fill;

    // Draw spikes procedurally
    final path = Path();
    for (double i = 0; i < size.x; i += 10) {
      path.moveTo(i, size.y);
      path.lineTo(i + 5, 0);
      path.lineTo(i + 10, size.y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}
