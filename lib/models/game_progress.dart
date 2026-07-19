class GameProgress {
  final int coins;
  final int lives;
  final int score;
  final int currentLevel;
  final List<int> unlockedLevels;
  final List<String> completedAchievements;
  final List<String> purchasedSkins;
  final String activeSkin;
  final Map<String, int> inventory;
  final DateTime lastSaved;

  const GameProgress({
    required this.coins,
    required this.lives,
    required this.score,
    required this.currentLevel,
    required this.unlockedLevels,
    required this.completedAchievements,
    required this.purchasedSkins,
    required this.activeSkin,
    required this.inventory,
    required this.lastSaved,
  });

  // Default initial progress for a new game
  factory GameProgress.newGame() {
    return GameProgress(
      coins: 0,
      lives: 3,
      score: 0,
      currentLevel: 1,
      unlockedLevels: const [1],
      completedAchievements: const [],
      purchasedSkins: const ['default_hero'],
      activeSkin: 'default_hero',
      inventory: const {},
      lastSaved: DateTime.now(),
    );
  }

  GameProgress copyWith({
    int? coins,
    int? lives,
    int? score,
    int? currentLevel,
    List<int>? unlockedLevels,
    List<String>? completedAchievements,
    List<String>? purchasedSkins,
    String? activeSkin,
    Map<String, int>? inventory,
    DateTime? lastSaved,
  }) {
    return GameProgress(
      coins: coins ?? this.coins,
      lives: lives ?? this.lives,
      score: score ?? this.score,
      currentLevel: currentLevel ?? this.currentLevel,
      unlockedLevels: unlockedLevels ?? this.unlockedLevels,
      completedAchievements: completedAchievements ?? this.completedAchievements,
      purchasedSkins: purchasedSkins ?? this.purchasedSkins,
      activeSkin: activeSkin ?? this.activeSkin,
      inventory: inventory ?? this.inventory,
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coins': coins,
      'lives': lives,
      'score': score,
      'currentLevel': currentLevel,
      'unlockedLevels': unlockedLevels,
      'completedAchievements': completedAchievements,
      'purchasedSkins': purchasedSkins,
      'activeSkin': activeSkin,
      'inventory': inventory,
      'lastSaved': lastSaved.toIso8601String(),
    };
  }

  factory GameProgress.fromMap(Map<dynamic, dynamic> map) {
    return GameProgress(
      coins: map['coins'] as int? ?? 0,
      lives: map['lives'] as int? ?? 3,
      score: map['score'] as int? ?? 0,
      currentLevel: map['currentLevel'] as int? ?? 1,
      unlockedLevels: (map['unlockedLevels'] as List?)?.cast<int>() ?? const [1],
      completedAchievements: (map['completedAchievements'] as List?)?.cast<String>() ?? const [],
      purchasedSkins: (map['purchasedSkins'] as List?)?.cast<String>() ?? const ['default_hero'],
      activeSkin: map['activeSkin'] as String? ?? 'default_hero',
      inventory: (map['inventory'] as Map?)?.cast<String, int>() ?? const {},
      lastSaved: map['lastSaved'] != null
          ? DateTime.tryParse(map['lastSaved'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
