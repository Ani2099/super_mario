import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import '../../../engine/base_game.dart';

class VirtualControls extends StatelessWidget {
  final BaseGame game;

  const VirtualControls({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    // Only display if the player is spawned
    final player = game.descendants().whereType().firstOrNull;
    if (player == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left Side: D-Pad / Directional Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Left button
                  _buildControlKey(
                    icon: Icons.arrow_back,
                    onPressStart: () => player.horizontalInput = -1.0,
                    onPressEnd: () => player.horizontalInput = 0.0,
                  ),
                  const SizedBox(width: 12),
                  // Crouch / Down button
                  _buildControlKey(
                    icon: Icons.arrow_downward,
                    onPressStart: () => player.crouchInputPressed = true,
                    onPressEnd: () => player.crouchInputPressed = false,
                  ),
                  const SizedBox(width: 12),
                  // Right button
                  _buildControlKey(
                    icon: Icons.arrow_forward,
                    onPressStart: () => player.horizontalInput = 1.0,
                    onPressEnd: () => player.horizontalInput = 0.0,
                  ),
                ],
              ),

              // Right Side: Action Buttons (A for Jump, B for Dash)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // B Button: Dash
                  _buildActionKey(
                    label: 'DASH',
                    color: GameColors.accentPink,
                    onPressStart: () => player.dashInputPressed = true,
                    onPressEnd: () => player.dashInputPressed = false,
                  ),
                  const SizedBox(width: 20),
                  // A Button: Jump
                  _buildActionKey(
                    label: 'JUMP',
                    color: GameColors.accentGreen,
                    onPressStart: () {
                      player.jumpInputPressed = true;
                    },
                    onPressEnd: () {
                      // Variable jump: release logic
                      if (player.velocity.y < -100) {
                        player.velocity.y = -100;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlKey({
    required IconData icon,
    required VoidCallback onPressStart,
    required VoidCallback onPressEnd,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) => onPressEnd(),
      onTapCancel: () => onPressEnd(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: GameColors.darkPanel.withOpacity(0.6),
          border: Border.all(color: GameColors.accentCyan.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Icon(icon, color: GameColors.accentCyan, size: 28),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required String label,
    required Color color,
    required VoidCallback onPressStart,
    required VoidCallback onPressEnd,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressStart(),
      onTapUp: (_) => onPressEnd(),
      onTapCancel: () => onPressEnd(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GameColors.darkPanel.withOpacity(0.6),
              border: Border.all(color: color.withOpacity(0.8), width: 3),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            ),
            child: Center(
              child: Text(
                label[0], // J or D
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
