import '../domain/element_type.dart';
import '../domain/tile.dart';

class FusionResult {
  const FusionResult({
    required this.score,
    this.tile,
    this.countsForMana = true,
  });

  final Tile? tile;
  final int score;
  final bool countsForMana;
}

FusionResult? fuseTiles(Tile first, Tile second, double randomValue) {
  if (first.type == ElementType.sage || second.type == ElementType.sage) {
    return const FusionResult(
      tile: Tile(type: ElementType.sage, level: 1),
      score: 10000,
    );
  }

  if (first.type == second.type && first.isBasic) {
    final newLevel = (first.level + 1).clamp(1, 4).toInt();
    if (newLevel == 4 && randomValue < 0.3) {
      return const FusionResult(
        tile: Tile(type: ElementType.sage, level: 1),
        score: 5000,
      );
    }

    return FusionResult(
      tile: Tile(type: first.type, level: newLevel),
      score: const [0, 10, 30, 70, 150][newLevel],
    );
  }

  if (_hasPair(first, second, ElementType.fire, ElementType.earth)) {
    return const FusionResult(
      tile: Tile(type: ElementType.lava),
      score: 100,
    );
  }

  if (_hasPair(first, second, ElementType.water, ElementType.earth)) {
    return const FusionResult(
      tile: Tile(type: ElementType.plant),
      score: 100,
    );
  }

  if (_hasPair(first, second, ElementType.fire, ElementType.water)) {
    return const FusionResult(
      tile: Tile(type: ElementType.steam),
      score: 50,
    );
  }

  if (_hasPair(first, second, ElementType.plant, ElementType.fire)) {
    return const FusionResult(
      tile: Tile(type: ElementType.lava),
      score: 150,
    );
  }

  if (_hasPair(first, second, ElementType.plant, ElementType.water)) {
    return const FusionResult(
      tile: Tile(type: ElementType.plant, level: 2),
      score: 200,
    );
  }

  if (first.type == ElementType.steam || second.type == ElementType.steam) {
    return const FusionResult(
      score: 0,
      countsForMana: false,
    );
  }

  if (first.type == ElementType.stone || second.type == ElementType.stone) {
    return null;
  }

  return null;
}

bool _hasPair(Tile first, Tile second, ElementType a, ElementType b) {
  return first.type == a && second.type == b ||
      first.type == b && second.type == a;
}
