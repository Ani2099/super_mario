import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_settings.dart';
import '../models/game_progress.dart';

abstract class SaveService {
  Future<void> init();
  Future<GameSettings> loadSettings();
  Future<void> saveSettings(GameSettings settings);
  Future<GameProgress?> loadProgress(int slot);
  Future<void> saveProgress(int slot, GameProgress progress);
  Future<void> deleteProgress(int slot);
  Future<List<int>> getUsedSlots();
}

class HiveSaveService implements SaveService {
  static const String _settingsBoxName = 'settings_box';
  static const String _progressBoxName = 'progress_box';
  static const String _settingsKey = 'current_settings';

  late Box _settingsBox;
  late Box _progressBox;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _progressBox = await Hive.openBox(_progressBoxName);
  }

  @override
  Future<GameSettings> loadSettings() async {
    final data = _settingsBox.get(_settingsKey);
    if (data == null) {
      return GameSettings.defaultSettings();
    }
    // Hive might return a Map<dynamic, dynamic>
    if (data is Map) {
      return GameSettings.fromMap(data);
    }
    return GameSettings.defaultSettings();
  }

  @override
  Future<void> saveSettings(GameSettings settings) async {
    await _settingsBox.put(_settingsKey, settings.toMap());
  }

  @override
  Future<GameProgress?> loadProgress(int slot) async {
    final data = _progressBox.get('slot_$slot');
    if (data == null) {
      return null;
    }
    if (data is Map) {
      return GameProgress.fromMap(data);
    }
    return null;
  }

  @override
  Future<void> saveProgress(int slot, GameProgress progress) async {
    await _progressBox.put('slot_$slot', progress.toMap());
  }

  @override
  Future<void> deleteProgress(int slot) async {
    await _progressBox.delete('slot_$slot');
  }

  @override
  Future<List<int>> getUsedSlots() async {
    final usedSlots = <int>[];
    for (int i = 1; i <= 3; i++) {
      if (_progressBox.containsKey('slot_$i')) {
        usedSlots.add(i);
      }
    }
    return usedSlots;
  }
}
