import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../audio/audio_assets.dart';
import '../../game_state_provider.dart';

class ShopItem {
  final String id;
  final String name;
  final int cost;
  final String description;

  const ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
  });
}

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  static const List<ShopItem> skins = [
    ShopItem(id: 'default_hero', name: 'Original Hero', cost: 0, description: 'The classic gravity runner.'),
    ShopItem(id: 'ninja_skin', name: 'Cyber Ninja', cost: 50, description: 'Agile stealth jumper.'),
    ShopItem(id: 'retro_skin', name: 'Retro Plumber', cost: 100, description: 'Inspired by 8-bit legends.'),
    ShopItem(id: 'cosmic_skin', name: 'Cosmic Knight', cost: 200, description: 'Armor made of pure stardust.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
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
          'CHARACTER SHOP',
          style: TextStyle(
            color: GameColors.accentCyan,
            letterSpacing: 2,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GameColors.accentCyan),
          onPressed: () {
            audio.playSfx(AudioAssets.sfxCoin);
            context.pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: GameColors.accentYellow, size: 24),
                const SizedBox(width: 6),
                Text(
                  '${progress.coins}',
                  style: const TextStyle(
                    color: GameColors.accentYellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: skins.length,
          itemBuilder: (context, index) {
            final item = skins[index];
            final hasPurchased = progress.purchasedSkins.contains(item.id);
            final isActive = progress.activeSkin == item.id;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GameColors.darkPanel,
                border: Border.all(
                  color: isActive ? GameColors.accentGreen : GameColors.borderNeon,
                  width: isActive ? 2.5 : 1.5,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: GameColors.accentGreen.withOpacity(0.15),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: GameColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(color: GameColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isActive)
                        const Text(
                          'EQUIPPED',
                          style: TextStyle(
                            color: GameColors.accentGreen,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                        )
                      else if (hasPurchased)
                        TextButton(
                          onPressed: () {
                            audio.playSfx(AudioAssets.sfxPowerupAppears);
                            notifier.selectSkin(item.id);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: GameColors.accentCyan,
                          ),
                          child: const Text('EQUIP', style: TextStyle(fontFamily: 'monospace')),
                        )
                      else
                        ElevatedButton(
                          onPressed: progress.coins >= item.cost
                              ? () {
                                  audio.playSfx(AudioAssets.sfxPowerup);
                                  notifier.purchaseSkin(item.id, item.cost);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GameColors.accentPink,
                            disabledBackgroundColor: GameColors.darkPanelCard,
                            shape: const BeveledRectangleBorder(),
                          ),
                          child: Text(
                            'BUY: ${item.cost}',
                            style: TextStyle(
                              color: progress.coins >= item.cost ? Colors.white : GameColors.textMuted,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Icon(
                        _getSkinIcon(item.id),
                        color: isActive ? GameColors.accentGreen : GameColors.textMuted,
                        size: 28,
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _getSkinIcon(String skinId) {
    switch (skinId) {
      case 'ninja_skin':
        return Icons.psychology;
      case 'retro_skin':
        return Icons.videogame_asset;
      case 'cosmic_skin':
        return Icons.rocket_launch;
      default:
        return Icons.directions_run;
    }
  }
}
