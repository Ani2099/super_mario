import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/router.dart';
import 'constants/colors.dart';
import 'services/save_service.dart';
import 'services/audio_service.dart';
import 'features/game_state_provider.dart';

void main() async {
  // Ensure widget binding is initialized before we run async operations in Splash
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize concrete services
  final saveService = HiveSaveService();
  await saveService.init();

  final audioService = FlameAudioService();
  await audioService.init();

  runApp(
    ProviderScope(
      overrides: [
        saveServiceProvider.overrideWithValue(saveService),
        audioServiceProvider.overrideWithValue(audioService),
      ],
      child: const AntigravityApp(),
    ),
  );
}

class AntigravityApp extends StatelessWidget {
  const AntigravityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Antigravity Runner',
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GameColors.darkBackground,
        primaryColor: GameColors.accentGreen,
        dividerColor: GameColors.borderNeon,
        colorScheme: const ColorScheme.dark(
          primary: GameColors.accentGreen,
          secondary: GameColors.accentCyan,
          surface: GameColors.darkPanel,
          error: GameColors.accentPink,
        ),
        // Monospace fonts give a cool retro arcade aesthetic
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'monospace', color: GameColors.textPrimary),
          bodyMedium: TextStyle(fontFamily: 'monospace', color: GameColors.textSecondary),
        ),
      ),
    );
  }
}
