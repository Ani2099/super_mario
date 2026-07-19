import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_settings.dart';
import '../models/game_progress.dart';
import '../services/save_service.dart';
import '../services/audio_service.dart';

// Dependency injection providers for services
final saveServiceProvider = Provider<SaveService>((ref) {
  return HiveSaveService();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  return FlameAudioService();
});

// Currently selected save slot (1, 2, or 3). Null means no slot loaded.
final activeSlotProvider = StateProvider<int?>((ref) => null);

// State Notifier for Game Settings
class SettingsNotifier extends StateNotifier<GameSettings> {
  final SaveService _saveService;
  final AudioService _audioService;
  late final Future<void> initialized;

  SettingsNotifier(this._saveService, this._audioService) : super(GameSettings.defaultSettings()) {
    initialized = _init();
  }

  Future<void> _init() async {
    final settings = await _saveService.loadSettings();
    state = settings;
    // Apply loaded volumes to AudioService
    _audioService.setMusicVolume(settings.musicVolume);
    _audioService.setSfxVolume(settings.sfxVolume);
  }

  Future<void> updateMusicVolume(double val) async {
    final newState = state.copyWith(musicVolume: val);
    state = newState;
    _audioService.setMusicVolume(val);
    await _saveService.saveSettings(newState);
  }

  Future<void> updateSfxVolume(double val) async {
    final newState = state.copyWith(sfxVolume: val);
    state = newState;
    _audioService.setSfxVolume(val);
    await _saveService.saveSettings(newState);
  }

  Future<void> toggleJoystick(bool enabled) async {
    final newState = state.copyWith(useVirtualJoystick: enabled);
    state = newState;
    await _saveService.saveSettings(newState);
  }

  Future<void> setDifficulty(String diff) async {
    final newState = state.copyWith(difficulty: diff);
    state = newState;
    await _saveService.saveSettings(newState);
  }

  Future<void> toggleVibration(bool enabled) async {
    final newState = state.copyWith(vibrationEnabled: enabled);
    state = newState;
    await _saveService.saveSettings(newState);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, GameSettings>((ref) {
  final saveService = ref.watch(saveServiceProvider);
  final audioService = ref.watch(audioServiceProvider);
  return SettingsNotifier(saveService, audioService);
});

// State Notifier for Game Progress (tied to current active slot)
class ProgressNotifier extends StateNotifier<GameProgress?> {
  final SaveService _saveService;
  final Ref _ref;

  ProgressNotifier(this._saveService, this._ref) : super(null) {
    // Listen to changes in the active slot
    _ref.listen<int?>(activeSlotProvider, (previous, next) {
      if (next == null) {
        state = null;
      } else {
        _loadSlot(next);
      }
    });

    // Load initial slot if one is already selected when this provider is created
    final initialSlot = _ref.read(activeSlotProvider);
    if (initialSlot != null) {
      _loadSlot(initialSlot);
    }
  }

  Future<void> _loadSlot(int slot) async {
    final progress = await _saveService.loadProgress(slot);
    if (progress == null) {
      // Start a fresh game progress for this slot
      final newProg = GameProgress.newGame();
      state = newProg;
      await _saveService.saveProgress(slot, newProg);
    } else {
      state = progress;
    }
  }

  Future<void> addCoins(int count) async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;

    // Check 100 coin extra life logic (inspired by Mario)
    int newCoins = current.coins + count;
    int extraLives = 0;
    if (newCoins >= 100) {
      extraLives = newCoins ~/ 100;
      newCoins = newCoins % 100;
      _ref.read(audioServiceProvider).playSfx('sfx/powerup.wav'); // Extra life sfx
    }

    final newState = current.copyWith(
      coins: newCoins,
      lives: current.lives + extraLives,
      lastSaved: DateTime.now(),
    );
    state = newState;
    await _saveService.saveProgress(slot, newState);
  }

  Future<void> addScore(int points) async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;

    final newState = current.copyWith(
      score: current.score + points,
      lastSaved: DateTime.now(),
    );
    state = newState;
    await _saveService.saveProgress(slot, newState);
  }

  Future<void> loseLife() async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;

    final newLives = (current.lives - 1).clamp(0, 99);
    final newState = current.copyWith(
      lives: newLives,
      lastSaved: DateTime.now(),
    );
    state = newState;
    await _saveService.saveProgress(slot, newState);
  }

  Future<void> unlockLevel(int level) async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;

    if (!current.unlockedLevels.contains(level)) {
      final updatedLevels = List<int>.from(current.unlockedLevels)..add(level);
      final newState = current.copyWith(
        unlockedLevels: updatedLevels,
        lastSaved: DateTime.now(),
      );
      state = newState;
      await _saveService.saveProgress(slot, newState);
    }
  }

  Future<void> setCurrentLevel(int level) async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;

    final newState = current.copyWith(
      currentLevel: level,
      lastSaved: DateTime.now(),
    );
    state = newState;
    await _saveService.saveProgress(slot, newState);
  }

  Future<void> completeAchievement(String achId) async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;

    if (!current.completedAchievements.contains(achId)) {
      final updated = List<String>.from(current.completedAchievements)..add(achId);
      final newState = current.copyWith(
        completedAchievements: updated,
        lastSaved: DateTime.now(),
      );
      state = newState;
      await _saveService.saveProgress(slot, newState);
    }
  }

  Future<void> addPowerupToInventory(String powerupId) async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;

    final updatedInv = Map<String, int>.from(current.inventory);
    updatedInv[powerupId] = (updatedInv[powerupId] ?? 0) + 1;

    final newState = current.copyWith(
      inventory: updatedInv,
      lastSaved: DateTime.now(),
    );
    state = newState;
    await _saveService.saveProgress(slot, newState);
  }

  Future<void> consumePowerup(String powerupId) async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;

    final count = current.inventory[powerupId] ?? 0;
    if (count <= 0) return;

    final updatedInv = Map<String, int>.from(current.inventory);
    if (count == 1) {
      updatedInv.remove(powerupId);
    } else {
      updatedInv[powerupId] = count - 1;
    }

    final newState = current.copyWith(
      inventory: updatedInv,
      lastSaved: DateTime.now(),
    );
    state = newState;
    await _saveService.saveProgress(slot, newState);
  }

  Future<void> purchaseSkin(String skinId, int cost) async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;
    if (current.coins < cost || current.purchasedSkins.contains(skinId)) return;

    final skins = List<String>.from(current.purchasedSkins)..add(skinId);
    final newState = current.copyWith(
      coins: current.coins - cost,
      purchasedSkins: skins,
      lastSaved: DateTime.now(),
    );
    state = newState;
    await _saveService.saveProgress(slot, newState);
  }

  Future<void> selectSkin(String skinId) async {
    final current = state;
    final slot = _ref.read(activeSlotProvider);
    if (current == null || slot == null) return;
    if (!current.purchasedSkins.contains(skinId)) return;

    final newState = current.copyWith(
      activeSkin: skinId,
      lastSaved: DateTime.now(),
    );
    state = newState;
    await _saveService.saveProgress(slot, newState);
  }

  Future<void> resetProgress() async {
    final slot = _ref.read(activeSlotProvider);
    if (slot == null) return;
    final newProg = GameProgress.newGame();
    state = newProg;
    await _saveService.saveProgress(slot, newProg);
  }
}

final progressProvider = StateNotifierProvider<ProgressNotifier, GameProgress?>((ref) {
  final saveService = ref.watch(saveServiceProvider);
  return ProgressNotifier(saveService, ref);
});
