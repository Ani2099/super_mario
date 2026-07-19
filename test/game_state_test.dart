import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_mario/models/game_settings.dart';
import 'package:super_mario/models/game_progress.dart';
import 'package:super_mario/services/save_service.dart';
import 'package:super_mario/services/audio_service.dart';
import 'package:super_mario/features/game_state_provider.dart';

// Simple mock SaveService for unit testing
class MockSaveService implements SaveService {
  GameSettings settings = GameSettings.defaultSettings();
  final Map<int, GameProgress> progressMap = {};
  final List<int> usedSlots = [];

  @override
  Future<void> init() async {}

  @override
  Future<GameSettings> loadSettings() async => settings;

  @override
  Future<void> saveSettings(GameSettings newSettings) async {
    settings = newSettings;
  }

  @override
  Future<GameProgress?> loadProgress(int slot) async => progressMap[slot];

  @override
  Future<void> saveProgress(int slot, GameProgress progress) async {
    progressMap[slot] = progress;
    if (!usedSlots.contains(slot)) usedSlots.add(slot);
  }

  @override
  Future<void> deleteProgress(int slot) async {
    progressMap.remove(slot);
    usedSlots.remove(slot);
  }

  @override
  Future<List<int>> getUsedSlots() async => usedSlots;
}

// Simple mock AudioService for unit testing
class MockAudioService implements AudioService {
  double musicVolumeVal = 0.5;
  double sfxVolumeVal = 0.7;
  bool isMutedVal = false;
  String? bgmPlaying;
  final List<String> playedSfx = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> playBgm(String filename) async {
    bgmPlaying = filename;
  }

  @override
  Future<void> stopBgm() async {
    bgmPlaying = null;
  }

  @override
  Future<void> playSfx(String filename) async {
    playedSfx.add(filename);
  }

  @override
  void setMusicVolume(double volume) {
    musicVolumeVal = volume;
  }

  @override
  void setSfxVolume(double volume) {
    sfxVolumeVal = volume;
  }

  @override
  void toggleMute() {
    isMutedVal = !isMutedVal;
  }

  @override
  bool get isMuted => isMutedVal;

  @override
  double get musicVolume => musicVolumeVal;

  @override
  double get sfxVolume => sfxVolumeVal;
}

void main() {
  group('Models Serialization Tests', () {
    test('GameSettings default initialization and copyWith', () {
      final s = GameSettings.defaultSettings();
      expect(s.musicVolume, 0.5);
      expect(s.difficulty, 'normal');

      final copied = s.copyWith(musicVolume: 0.9, difficulty: 'hard');
      expect(copied.musicVolume, 0.9);
      expect(copied.difficulty, 'hard');
      expect(copied.sfxVolume, s.sfxVolume); // unchanged
    });

    test('GameSettings Map serialization and deserialization', () {
      final s = const GameSettings(
        musicVolume: 0.2,
        sfxVolume: 0.8,
        useVirtualJoystick: false,
        vibrationEnabled: false,
        difficulty: 'easy',
        themeMode: 'light',
      );

      final map = s.toMap();
      final fromMap = GameSettings.fromMap(map);

      expect(fromMap.musicVolume, 0.2);
      expect(fromMap.sfxVolume, 0.8);
      expect(fromMap.useVirtualJoystick, isFalse);
      expect(fromMap.difficulty, 'easy');
    });

    test('GameProgress initialization and map conversion', () {
      final p = GameProgress.newGame();
      expect(p.coins, 0);
      expect(p.lives, 3);
      expect(p.unlockedLevels, contains(1));

      final map = p.toMap();
      final fromMap = GameProgress.fromMap(map);
      expect(fromMap.coins, 0);
      expect(fromMap.lives, 3);
      expect(fromMap.unlockedLevels, contains(1));
    });
  });

  group('Riverpod Settings State Management Tests', () {
    late ProviderContainer container;
    late MockSaveService mockSave;
    late MockAudioService mockAudio;

    setUp(() {
      mockSave = MockSaveService();
      mockAudio = MockAudioService();

      container = ProviderContainer(
        overrides: [
          saveServiceProvider.overrideWithValue(mockSave),
          audioServiceProvider.overrideWithValue(mockAudio),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('SettingsNotifier updates states, invokes AudioService, and stores to SaveService', () async {
      // Trigger initialization and await it
      await container.read(settingsProvider.notifier).initialized;

      var settings = container.read(settingsProvider);
      expect(settings.musicVolume, 0.5);

      // Update volume
      await container.read(settingsProvider.notifier).updateMusicVolume(0.85);
      settings = container.read(settingsProvider);

      expect(settings.musicVolume, 0.85);
      expect(mockAudio.musicVolumeVal, 0.85);
      expect(mockSave.settings.musicVolume, 0.85);

      // Set difficulty
      await container.read(settingsProvider.notifier).setDifficulty('hard');
      settings = container.read(settingsProvider);

      expect(settings.difficulty, 'hard');
      expect(mockSave.settings.difficulty, 'hard');
    });
  });

  group('Riverpod Game Progress State Management Tests', () {
    late ProviderContainer container;
    late MockSaveService mockSave;
    late MockAudioService mockAudio;

    setUp(() {
      mockSave = MockSaveService();
      mockAudio = MockAudioService();

      container = ProviderContainer(
        overrides: [
          saveServiceProvider.overrideWithValue(mockSave),
          audioServiceProvider.overrideWithValue(mockAudio),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('ProgressNotifier initializes on active slot selection, updates stats, and handles coin-life triggers', () async {
      // Initially null
      expect(container.read(progressProvider), isNull);

      // Select slot 1
      container.read(activeSlotProvider.notifier).state = 1;
      // Wait for state listeners to execute microtasks
      await Future.delayed(Duration.zero);

      final progress1 = container.read(progressProvider);
      expect(progress1, isNotNull);
      expect(progress1!.currentLevel, 1);
      expect(progress1.coins, 0);

      // Add coins
      await container.read(progressProvider.notifier).addCoins(15);
      final progress2 = container.read(progressProvider);
      expect(progress2, isNotNull);
      expect(progress2!.coins, 15);
      expect(mockSave.progressMap[1]!.coins, 15);

      // Test coin rollover logic (100 coins = extra life)
      await container.read(progressProvider.notifier).addCoins(90); // 15 + 90 = 105
      final progress3 = container.read(progressProvider);
      expect(progress3, isNotNull);
      expect(progress3!.coins, 5); // 105 % 100
      expect(progress3.lives, 4); // 3 lives + 1 extra life

      // Unlock a level
      await container.read(progressProvider.notifier).unlockLevel(2);
      final progress4 = container.read(progressProvider);
      expect(progress4, isNotNull);
      expect(progress4!.unlockedLevels, contains(2));

      // Purchase a skin
      await container.read(progressProvider.notifier).purchaseSkin('ninja_skin', 5); // cost 5, current coins 5
      final progress5 = container.read(progressProvider);
      expect(progress5, isNotNull);
      expect(progress5!.coins, 0);
      expect(progress5.purchasedSkins, contains('ninja_skin'));
    });
  });
}
