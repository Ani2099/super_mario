import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../audio/audio_assets.dart';
import '../../game_state_provider.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
  bool _showingSlotSelection = false;
  List<int> _usedSlots = [];
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    // Start menu background music
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioServiceProvider).playBgm(AudioAssets.bgmMenu);
    });
  }

  Future<void> _fetchUsedSlots() async {
    print('👾 [MainMenu] _fetchUsedSlots() started');
    setState(() => _loadingSlots = true);
    try {
      print('👾 [MainMenu] _fetchUsedSlots() calling saveServiceProvider.getUsedSlots()');
      final slots = await ref.read(saveServiceProvider).getUsedSlots();
      print('👾 [MainMenu] _fetchUsedSlots() getUsedSlots() returned: $slots');
      if (mounted) {
        setState(() {
          _usedSlots = slots;
          _loadingSlots = false;
        });
        print('👾 [MainMenu] _fetchUsedSlots() successfully updated slot selection UI');
      }
    } catch (e, stack) {
      print('👾 [MainMenu] _fetchUsedSlots() caught error: $e\n$stack');
      if (mounted) {
        setState(() {
          _usedSlots = const [];
          _loadingSlots = false;
        });
      }
    }
  }

  void _onPlayPressed() {
    ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
    _fetchUsedSlots();
    setState(() {
      _showingSlotSelection = true;
    });
  }

  void _onSlotSelected(int slot) {
    ref.read(audioServiceProvider).playSfx(AudioAssets.sfxPowerupAppears);
    // Load state
    ref.read(activeSlotProvider.notifier).state = slot;
    // Stop Menu BGM before entering game
    ref.read(audioServiceProvider).stopBgm();
    context.go('/game');
  }

  Future<void> _onDeleteSlot(int slot) async {
    ref.read(audioServiceProvider).playSfx(AudioAssets.sfxHurt);
    await ref.read(saveServiceProvider).deleteProgress(slot);
    await _fetchUsedSlots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.darkBackground,
      body: Stack(
        children: [
          // Background Tech Grid design
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: GridPaper(
                color: GameColors.accentCyan,
                interval: 40,
                subdivisions: 1,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showingSlotSelection ? _buildSlotSelection() : _buildMainButtons(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButtons() {
    return Column(
      key: const ValueKey('main_buttons'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: GameColors.accentPink, width: 4),
            color: GameColors.darkPanel,
            boxShadow: [
              BoxShadow(
                color: GameColors.accentPink.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 3,
              )
            ],
          ),
          child: const Text(
            'ANTIGRAVITY',
            style: TextStyle(
              color: GameColors.accentPink,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'A Flame Engine platformer template',
          style: TextStyle(color: GameColors.textMuted, fontSize: 14, letterSpacing: 1.5),
        ),
        const SizedBox(height: 64),
        _buildMenuButton('PLAY GAME', _onPlayPressed),
        const SizedBox(height: 16),
        _buildMenuButton('SHOP', () {
          ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
          context.push('/shop');
        }),
        const SizedBox(height: 16),
        _buildMenuButton('ACHIEVEMENTS', () {
          ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
          context.push('/achievements');
        }),
        const SizedBox(height: 16),
        _buildMenuButton('SETTINGS', () {
          ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
          context.push('/settings');
        }),
      ],
    );
  }

  Widget _buildSlotSelection() {
    return Container(
      key: const ValueKey('slot_selection'),
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: GameColors.darkPanel,
        border: Border.all(color: GameColors.accentCyan, width: 2),
        boxShadow: [
          BoxShadow(
            color: GameColors.accentCyan.withOpacity(0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'CHOOSE SAVE SLOT',
            style: TextStyle(
              color: GameColors.accentCyan,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 24),
          if (_loadingSlots)
            const CircularProgressIndicator(color: GameColors.accentCyan)
          else ...[
            _buildSlotCard(1),
            const SizedBox(height: 12),
            _buildSlotCard(2),
            const SizedBox(height: 12),
            _buildSlotCard(3),
          ],
          const SizedBox(height: 24),
          _buildMenuButton('BACK TO MENU', () {
            ref.read(audioServiceProvider).playSfx(AudioAssets.sfxCoin);
            setState(() {
              _showingSlotSelection = false;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildSlotCard(int slot) {
    final isUsed = _usedSlots.contains(slot);
    return FutureBuilder<dynamic>(
      future: ref.read(saveServiceProvider).loadProgress(slot),
      builder: (context, snapshot) {
        final progress = snapshot.data;
        return Container(
          decoration: BoxDecoration(
            color: GameColors.darkPanelCard,
            border: Border.all(
              color: isUsed ? GameColors.accentGreen : GameColors.textMuted.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ListTile(
            title: Text(
              'SLOT $slot',
              style: TextStyle(
                color: isUsed ? GameColors.accentGreen : GameColors.textMuted,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            subtitle: isUsed && progress != null
                ? Text(
                    'Level ${progress.currentLevel} | Score: ${progress.score} | Coins: ${progress.coins}',
                    style: const TextStyle(color: GameColors.textSecondary, fontSize: 12),
                  )
                : const Text(
                    'EMPTY SLOT',
                    style: TextStyle(color: GameColors.textMuted, fontSize: 12),
                  ),
            trailing: isUsed
                ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: GameColors.accentPink),
                    onPressed: () => _onDeleteSlot(slot),
                  )
                : null,
            onTap: () => _onSlotSelected(slot),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(String label, VoidCallback onPressed) {
    return Container(
      width: 250,
      height: 50,
      decoration: BoxDecoration(
        color: GameColors.darkPanelCard,
        border: Border.all(color: GameColors.borderNeon, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 4,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          highlightColor: GameColors.accentCyan.withOpacity(0.1),
          splashColor: GameColors.accentCyan.withOpacity(0.2),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: GameColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
