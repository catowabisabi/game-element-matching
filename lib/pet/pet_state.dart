import '../game/domain/element_type.dart';

class PetState {
  const PetState({
    required this.name,
    required this.stage,
    required this.experience,
    required this.hunger,
    required this.mood,
    required this.affinity,
  });

  final String name;
  final int stage;
  final int experience;
  final int hunger;
  final int mood;
  final ElementType affinity;

  String get formName => switch ((affinity, stage)) {
        (ElementType.fire, 1) => '小火靈',
        (ElementType.fire, 2) => '焰角獸',
        (ElementType.fire, _) => '鳳凰',
        (ElementType.water, 1) => '水滴靈',
        (ElementType.water, 2) => '潮汐獸',
        (ElementType.water, _) => '海龍',
        (ElementType.earth, 1) => '泥芽獸',
        (ElementType.earth, 2) => '岩甲獸',
        (ElementType.earth, _) => '大地守護者',
        (_, 1) => '元素幼體',
        (_, 2) => '星石獸',
        (_, _) => '賢者獸',
      };

  int get nextEvolutionExperience => switch (stage) {
        1 => 60,
        2 => 160,
        _ => 999999,
      };

  double get evolutionProgress {
    if (stage >= 3) {
      return 1;
    }
    return (experience / nextEvolutionExperience).clamp(0, 1).toDouble();
  }

  PetState feed(ElementType recentElement) {
    final nextAffinity = recentElement == ElementType.lava
        ? ElementType.fire
        : recentElement == ElementType.plant
            ? ElementType.earth
            : recentElement == ElementType.steam
                ? ElementType.water
                : recentElement;
    var nextExperience = experience + 12 + mood ~/ 10;
    var nextStage = stage;
    if (nextStage == 1 && nextExperience >= 60) {
      nextStage = 2;
    } else if (nextStage == 2 && nextExperience >= 160) {
      nextStage = 3;
    }

    return copyWith(
      stage: nextStage,
      experience: nextExperience,
      hunger: (hunger + 28).clamp(0, 100).toInt(),
      mood: (mood + 18).clamp(0, 100).toInt(),
      affinity: nextAffinity,
    );
  }

  PetState afterGame(int score) {
    return copyWith(
      experience: experience + score ~/ 250,
      hunger: (hunger - 8).clamp(0, 100).toInt(),
      mood: (mood + 4).clamp(0, 100).toInt(),
    );
  }

  PetState copyWith({
    String? name,
    int? stage,
    int? experience,
    int? hunger,
    int? mood,
    ElementType? affinity,
  }) {
    return PetState(
      name: name ?? this.name,
      stage: stage ?? this.stage,
      experience: experience ?? this.experience,
      hunger: hunger ?? this.hunger,
      mood: mood ?? this.mood,
      affinity: affinity ?? this.affinity,
    );
  }

  Map<String, Object?> toJson() => {
        'name': name,
        'stage': stage,
        'experience': experience,
        'hunger': hunger,
        'mood': mood,
        'affinity': affinity.name,
      };

  static PetState fromJson(Map<String, Object?> json) {
    return PetState(
      name: json['name'] as String? ?? 'Elementary',
      stage: json['stage'] as int? ?? 1,
      experience: json['experience'] as int? ?? 0,
      hunger: json['hunger'] as int? ?? 70,
      mood: json['mood'] as int? ?? 70,
      affinity: ElementType.values.byName(json['affinity'] as String? ?? 'fire'),
    );
  }

  static PetState initial() {
    return const PetState(
      name: 'Elementary',
      stage: 1,
      experience: 0,
      hunger: 70,
      mood: 70,
      affinity: ElementType.fire,
    );
  }
}
