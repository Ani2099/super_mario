import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/colors.dart';
import '../../../audio/audio_assets.dart';
import '../../game_state_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final audio = ref.read(audioServiceProvider);

    return Scaffold(
      backgroundColor: GameColors.darkBackground,
      appBar: AppBar(
        backgroundColor: GameColors.darkPanel,
        title: const Text(
          'SETTINGS',
          style: TextStyle(
            color: GameColors.accentGreen,
            letterSpacing: 2,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GameColors.accentGreen),
          onPressed: () {
            audio.playSfx(AudioAssets.sfxCoin);
            context.pop();
          },
        ),
      ),
      body: Center(
        child: Container(
          maxWidth: 600,
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: GameColors.darkPanel,
            border: Border.all(color: GameColors.borderNeon, width: 2),
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'AUDIO SETUP',
                style: TextStyle(
                  color: GameColors.accentCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
              const Divider(color: GameColors.borderNeon, height: 24),

              // Music Volume
              Row(
                children: [
                  const SizedBox(
                    width: 150,
                    child: Text(
                      'MUSIC VOLUME',
                      style: TextStyle(color: GameColors.textSecondary, fontFamily: 'monospace'),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: settings.musicVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: GameColors.accentGreen,
                      inactiveColor: GameColors.darkPanelCard,
                      onChanged: (val) {
                        settingsNotifier.updateMusicVolume(val);
                      },
                    ),
                  ),
                  Text(
                    '${(settings.musicVolume * 100).toInt()}%',
                    style: const TextStyle(color: GameColors.textSecondary, fontFamily: 'monospace'),
                  ),
                ],
              ),

              // SFX Volume
              Row(
                children: [
                  const SizedBox(
                    width: 150,
                    child: Text(
                      'SFX VOLUME',
                      style: TextStyle(color: GameColors.textSecondary, fontFamily: 'monospace'),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: settings.sfxVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: GameColors.accentGreen,
                      inactiveColor: GameColors.darkPanelCard,
                      onChangeEnd: (val) {
                        // Play a test sound to preview volume on release
                        audio.playSfx(AudioAssets.sfxCoin);
                      },
                      onChanged: (val) {
                        settingsNotifier.updateSfxVolume(val);
                      },
                    ),
                  ),
                  Text(
                    '${(settings.sfxVolume * 100).toInt()}%',
                    style: const TextStyle(color: GameColors.textSecondary, fontFamily: 'monospace'),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'GAMEPLAY CONTROLS',
                style: TextStyle(
                  color: GameColors.accentCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              ),
              const Divider(color: GameColors.borderNeon, height: 24),

              // Touch Controls (Virtual Joystick)
              SwitchListTile(
                title: const Text(
                  'VIRTUAL JOYSTICK',
                  style: TextStyle(color: GameColors.textSecondary, fontFamily: 'monospace', fontSize: 14),
                ),
                subtitle: const Text(
                  'Enable virtual controls on mobile touchscreens',
                  style: TextStyle(color: GameColors.textMuted, fontSize: 11),
                ),
                activeColor: GameColors.accentGreen,
                activeTrackColor: GameColors.accentGreen.withOpacity(0.2),
                inactiveThumbColor: GameColors.textMuted,
                inactiveTrackColor: GameColors.darkPanelCard,
                value: settings.useVirtualJoystick,
                onChanged: (val) {
                  audio.playSfx(AudioAssets.sfxCoin);
                  settingsNotifier.toggleJoystick(val);
                },
              ),

              // Vibration Toggle
              SwitchListTile(
                title: const Text(
                  'HAPTIC FEEDBACK',
                  style: TextStyle(color: GameColors.textSecondary, fontFamily: 'monospace', fontSize: 14),
                ),
                activeColor: GameColors.accentGreen,
                activeTrackColor: GameColors.accentGreen.withOpacity(0.2),
                inactiveThumbColor: GameColors.textMuted,
                inactiveTrackColor: GameColors.darkPanelCard,
                value: settings.vibrationEnabled,
                onChanged: (val) {
                  audio.playSfx(AudioAssets.sfxCoin);
                  settingsNotifier.toggleVibration(val);
                },
              ),

              // Difficulty Dropdown
              ListTile(
                title: const Text(
                  'DIFFICULTY SCALE',
                  style: TextStyle(color: GameColors.textSecondary, fontFamily: 'monospace', fontSize: 14),
                ),
                trailing: Theme(
                  data: Theme.of(context).copyWith(
                    canvasColor: GameColors.darkPanel,
                  ),
                  child: DropdownButton<String>(
                    value: settings.difficulty,
                    underline: Container(),
                    style: const TextStyle(color: GameColors.accentGreen, fontFamily: 'monospace'),
                    items: const [
                      DropdownMenuItem(
                        value: 'easy',
                        child: Text('EASY (x0.5 DMG)'),
                      ),
                      DropdownMenuItem(
                        value: 'normal',
                        child: Text('NORMAL (x1.0 DMG)'),
                      ),
                      DropdownMenuItem(
                        value: 'hard',
                        child: Text('HARD (x1.5 DMG)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        audio.playSfx(AudioAssets.sfxCoin);
                        settingsNotifier.setDifficulty(val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
