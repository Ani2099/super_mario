class GameSettings {
  final double musicVolume;
  final double sfxVolume;
  final bool useVirtualJoystick;
  final bool vibrationEnabled;
  final String difficulty; // 'easy', 'normal', 'hard'
  final String themeMode; // 'dark', 'light'

  const GameSettings({
    required this.musicVolume,
    required this.sfxVolume,
    required this.useVirtualJoystick,
    required this.vibrationEnabled,
    required this.difficulty,
    required this.themeMode,
  });

  // Default initial settings
  factory GameSettings.defaultSettings() {
    return const GameSettings(
      musicVolume: 0.5,
      sfxVolume: 0.7,
      useVirtualJoystick: true,
      vibrationEnabled: true,
      difficulty: 'normal',
      themeMode: 'dark',
    );
  }

  GameSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? useVirtualJoystick,
    bool? vibrationEnabled,
    String? difficulty,
    String? themeMode,
  }) {
    return GameSettings(
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      useVirtualJoystick: useVirtualJoystick ?? this.useVirtualJoystick,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      difficulty: difficulty ?? this.difficulty,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'musicVolume': musicVolume,
      'sfxVolume': sfxVolume,
      'useVirtualJoystick': useVirtualJoystick,
      'vibrationEnabled': vibrationEnabled,
      'difficulty': difficulty,
      'themeMode': themeMode,
    };
  }

  factory GameSettings.fromMap(Map<dynamic, dynamic> map) {
    return GameSettings(
      musicVolume: (map['musicVolume'] as num?)?.toDouble() ?? 0.5,
      sfxVolume: (map['sfxVolume'] as num?)?.toDouble() ?? 0.7,
      useVirtualJoystick: map['useVirtualJoystick'] as bool? ?? true,
      vibrationEnabled: map['vibrationEnabled'] as bool? ?? true,
      difficulty: map['difficulty'] as String? ?? 'normal',
      themeMode: map['themeMode'] as String? ?? 'dark',
    );
  }
}
