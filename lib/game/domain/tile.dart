import 'element_type.dart';

class Tile {
  static int _nextId = 0;

  Tile({
    required this.type,
    this.level = 1,
    this.justMerged = false,
    this.justSpawned = false,
    int? id,
  }) : id = id ?? _nextId++;

  // id can be null for deserialized tiles that don't have stable identity
  final int id;
  final ElementType type;
  final int level;
  final bool justMerged;
  final bool justSpawned;

  bool get isBlocker => type == ElementType.stone;
  bool get isBasic =>
      type == ElementType.fire ||
      type == ElementType.water ||
      type == ElementType.earth;

  Tile copyWith({
    int? id,
    ElementType? type,
    int? level,
    bool? justMerged,
    bool? justSpawned,
  }) {
    return Tile(
      type: type ?? this.type,
      level: level ?? this.level,
      justMerged: justMerged ?? this.justMerged,
      justSpawned: justSpawned ?? this.justSpawned,
      id: id ?? this.id,
    );
  }

  Map<String, Object?> toJson() => {
        'type': type.name,
        'level': level,
      };

  static Tile fromJson(Map<String, Object?> json) {
    return Tile(
      type: ElementType.values.byName(json['type'] as String),
      level: json['level'] as int? ?? 1,
    );
  }
}
