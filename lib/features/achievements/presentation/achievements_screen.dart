import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../audio/audio_assets.dart';
import '../../game_state_provider.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static const List<Achievement> achievements = [
    Achievement(
      id: 'first_steps',
      title: 'First Steps',
      description: 'Loaded your first save file.',
      icon: Icons.explore,
    ),
    Achievement(
      id: 'coin_collector',
      title: 'Wealthy Explorer',
      description: 'Accumulate 10 or more coins.',
      icon: Icons.monetization_on,
    ),
    Achievement(
      id: 'high_scorer',
      title: 'Score Chaser',
      description: 'Score 1,000 points or more.',
      icon: Icons.emoji_events,
    ),
    Achievement(
      id: 'immortal',
      title: 'Immortal Runner',
      description: 'Have 5 or more active lives.',
      icon: Icons.favorite,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final audio = ref.read(audioServiceProvider);

    if (progress == null) {
      return Scaffold(
        backgroundColor: GameColors.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('NO SAVE SLOT LOADED', style: TextStyle(color: GameColors.accentPink)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/menu'), child: const Text('Back to Menu')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GameColors.darkBackground,
      appBar: AppBar(
        backgroundColor: GameColors.darkPanel,
        title: const Text(
          'ACHIEVEMENTS',
          style: TextStyle(
            color: GameColors.accentOrange,
            letterSpacing: 2,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GameColors.accentOrange),
          onPressed: () {
            audio.playSfx(AudioAssets.sfxCoin);
            context.pop();
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: achievements.length,
        itemBuilder: (context, index) {
          final ach = achievements[index];
          // Determine if completed (auto check coin/score triggers for local display as well)
          final isExplicitlyCompleted = progress.completedAchievements.contains(ach.id);
          
          // Let's dynamically resolve completion based on stats in addition to saved badges!
          bool isCompleted = isExplicitlyCompleted;
          if (ach.id == 'first_steps') isCompleted = true; // Since slot is loaded
          if (ach.id == 'coin_collector' && progress.coins >= 10) isCompleted = true;
          if (ach.id == 'high_scorer' && progress.score >= 1000) isCompleted = true;
          if (ach.id == 'immortal' && progress.lives >= 5) isCompleted = true;

          return Card(
            color: isCompleted ? GameColors.darkPanel : GameColors.darkPanel.withOpacity(0.5),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isCompleted ? GameColors.accentOrange : GameColors.borderNeon,
                width: isCompleted ? 1.5 : 1.0,
              ),
              borderRadius: BorderRadius.zero,
            ),
            child: ListTile(
              leading: Icon(
                ach.icon,
                color: isCompleted ? GameColors.accentOrange : GameColors.textMuted,
                size: 32,
              ),
              title: Text(
                ach.title,
                style: TextStyle(
                  color: isCompleted ? GameColors.textPrimary : GameColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              subtitle: Text(
                ach.description,
                style: TextStyle(
                  color: isCompleted ? GameColors.textSecondary : GameColors.textMuted.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                isCompleted ? Icons.check_circle : Icons.lock_outline,
                color: isCompleted ? GameColors.accentGreen : GameColors.textMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}
