import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../audio/audio_assets.dart';
import '../../game_state_provider.dart';
import '../../../engine/base_game.dart';

class GamePlayScreen extends ConsumerStatefulWidget {
  const GamePlayScreen({super.key});

  @override
  ConsumerState<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends ConsumerState<GamePlayScreen> {
  late BaseGame _game;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _game = BaseGame(ref: ref);
  }

  @override
  void dispose() {
    // Stop all BGM when leaving game screen
    ref.read(audioServiceProvider).stopBgm();
    super.dispose();
  }

  void _togglePause() {
    ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _game.pauseEngine();
      } else {
        _game.resumeEngine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeSlot = ref.watch(activeSlotProvider);

    // Guard: If no save slot is selected, redirect back to menu!
    if (activeSlot == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/menu');
      });
      return const Scaffold(
        backgroundColor: GameColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: GameColors.accentGreen)),
      );
    }

    final progress = ref.watch(progressProvider);

    if (progress == null) {
      return const Scaffold(
        backgroundColor: GameColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: GameColors.accentGreen)),
      );
    }

    return Scaffold(
      backgroundColor: GameColors.darkBackground,
      body: Stack(
        children: [
          // Flame Canvas
          Positioned.fill(
            child: GameWidget(
              game: _game,
            ),
          ),

          // HUD Overlay
          Positioned(
            top: 24,
            left: 24,
            right: 24,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lives & Coins Status Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: GameColors.darkPanel.withOpacity(0.85),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: GameColors.accentPink, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'x${progress.lives}',
                          style: const TextStyle(
                            color: GameColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Icon(Icons.monetization_on, color: GameColors.accentYellow, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'x${progress.coins}',
                          style: const TextStyle(
                            color: GameColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Score & Level Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: GameColors.darkPanel.withOpacity(0.85),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'WORLD 1-${progress.currentLevel}',
                          style: const TextStyle(
                            color: GameColors.accentCyan,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'SCORE: ${progress.score.toString().padLeft(6, '0')}',
                          style: const TextStyle(
                            color: GameColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pause Button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: GameColors.darkPanel.withOpacity(0.85),
                    ),
                    icon: const Icon(Icons.pause, color: GameColors.textPrimary),
                    onPressed: _togglePause,
                  ),
                ],
              ),
            ),
          ),

          // Simulation Sandbox Panel (For Demonstration/Verification)
          Positioned(
            bottom: 24,
            left: 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              color: GameColors.darkPanel.withOpacity(0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SIMULATION SANDBOX',
                    style: TextStyle(
                      color: GameColors.accentGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameColors.darkPanelCard,
                          shape: const BeveledRectangleBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: _game.onCoinCollected,
                        child: const Text('+COIN & SCORE', style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameColors.darkPanelCard,
                          shape: const BeveledRectangleBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onPressed: _game.onPlayerDeath,
                        child: const Text('LOSE LIFE', style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Pause Menu Overlay
          if (_isPaused)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.75),
                child: Center(
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: GameColors.darkPanel,
                      border: Border.all(color: GameColors.accentGreen, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'GAME PAUSED',
                          style: TextStyle(
                            color: GameColors.accentGreen,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildPauseButton('RESUME', _togglePause),
                        const SizedBox(height: 12),
                        _buildPauseButton('RESTART LEVEL', () {
                          ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
                          ref.read(progressProvider.notifier).resetProgress();
                          _togglePause();
                        }),
                        const SizedBox(height: 12),
                        _buildPauseButton('SETTINGS', () {
                          ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
                          context.push('/settings');
                        }),
                        const SizedBox(height: 12),
                        _buildPauseButton('EXIT TO MENU', () {
                          ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
                          ref.read(activeSlotProvider.notifier).state = null;
                          context.go('/menu');
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPauseButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: GameColors.borderNeon),
          shape: const BeveledRectangleBorder(),
          foregroundColor: GameColors.textPrimary,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
