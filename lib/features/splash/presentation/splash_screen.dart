import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game_state_provider.dart';
import '../../../constants/colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _loadingText = "BOOTING SYSTEM...";

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() => _loadingText = "MOUNTING SAVE STORAGE...");
      final saveService = ref.read(saveServiceProvider);
      await saveService.init();

      setState(() => _loadingText = "TUNING AUDIO SYNTHESIS...");
      final audioService = ref.read(audioServiceProvider);
      await audioService.init();

      // Trigger settings load to apply volume settings early
      setState(() => _loadingText = "LOADING CONFIGURATIONS...");
      await ref.read(settingsProvider.notifier).initialized;

      setState(() => _loadingText = "READY!");
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        context.go('/menu');
      }
    } catch (e) {
      setState(() => _loadingText = "FATAL HARDWARE FAILURE: $e");
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.darkBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Retro gaming logo style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: GameColors.accentGreen, width: 4),
                  color: GameColors.darkPanel,
                  boxShadow: [
                    BoxShadow(
                      color: GameColors.accentGreen.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Text(
                  'ANTIGRAVITY RUNNER',
                  style: TextStyle(
                    color: GameColors.accentGreen,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 150,
                child: LinearProgressIndicator(
                  color: GameColors.accentGreen,
                  backgroundColor: GameColors.darkPanel,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _loadingText,
                style: const TextStyle(
                  color: GameColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
