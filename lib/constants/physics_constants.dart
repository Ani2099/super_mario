class PhysicsConstants {
  // Global Physics
  static const double gravity = 800.0;
  static const double maxFallSpeed = 400.0;

  // Player Movement Physics
  static const double walkSpeed = 150.0;
  static const double runSpeed = 250.0;
  static const double acceleration = 600.0;
  static const double friction = 800.0;
  static const double airControl = 0.6; // multiplier for lateral control in mid-air

  // Jumping Physics
  static const double jumpForce = -320.0;
  static const double doubleJumpForce = -280.0;
  static const double wallJumpXForce = 220.0;
  static const double wallJumpYForce = -280.0;
  static const double minJumpForce = -100.0; // For variable jump height support

  // Dashing
  static const double dashSpeed = 450.0;
  static const double dashDuration = 0.2; // seconds
  static const double dashCooldown = 0.8; // seconds

  // Special States
  static const double wallSlideSpeed = 60.0; // slow fall speed when sliding down walls
  static const double slopeSlideThreshold = 0.8; // angle threshold
}
