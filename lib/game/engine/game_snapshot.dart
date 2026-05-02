import '../domain/tile.dart';
import 'direction.dart';

const int gridSize = 4;
const int stoneInterval = 10;
const int manaCost = 3;

class GameSnapshot {
  const GameSnapshot({
    required this.grid,
    required this.score,
    required this.mana,
    required this.record,
    required this.moveCount,
    required this.gameOver,
    required this.won,
    required this.coins,
    this.hintDirection,
    this.lastMessage,
    this.shieldActive = false,
  });

  final List<Tile?> grid;
  final int score;
  final int mana;
  final int record;
  final int moveCount;
  final bool gameOver;
  final bool won;
  final int coins;
  final Direction? hintDirection;
  final String? lastMessage;
  final bool shieldActive;

  int get emptyCount => grid.where((tile) => tile == null).length;

  Map<String, Object?> toJson() => {
        'grid': grid.map((tile) => tile?.toJson()).toList(),
        'score': score,
        'mana': mana,
        'record': record,
        'moveCount': moveCount,
        'gameOver': gameOver,
        'won': won,
        'coins': coins,
        'shieldActive': shieldActive,
      };

  static GameSnapshot fromJson(Map<String, Object?> json) {
    final rawGrid = json['grid'] as List<Object?>? ?? const [];
    return GameSnapshot(
      grid: List<Tile?>.generate(gridSize * gridSize, (index) {
        final rawTile = index < rawGrid.length ? rawGrid[index] : null;
        if (rawTile is Map<String, Object?>) {
          return Tile.fromJson(rawTile);
        }
        if (rawTile is Map) {
          return Tile.fromJson(Map<String, Object?>.from(rawTile));
        }
        return null;
      }),
      score: json['score'] as int? ?? 0,
      mana: json['mana'] as int? ?? 0,
      record: json['record'] as int? ?? 0,
      moveCount: json['moveCount'] as int? ?? 0,
      gameOver: json['gameOver'] as bool? ?? false,
      won: json['won'] as bool? ?? false,
      coins: json['coins'] as int? ?? 0,
      shieldActive: json['shieldActive'] as bool? ?? false,
    );
  }

  GameSnapshot copyWith({
    List<Tile?>? grid,
    int? score,
    int? mana,
    int? record,
    int? moveCount,
    bool? gameOver,
    bool? won,
    int? coins,
    Direction? hintDirection,
    bool clearHint = false,
    String? lastMessage,
    bool clearMessage = false,
    bool? shieldActive,
  }) {
    return GameSnapshot(
      grid: grid ?? this.grid,
      score: score ?? this.score,
      mana: mana ?? this.mana,
      record: record ?? this.record,
      moveCount: moveCount ?? this.moveCount,
      gameOver: gameOver ?? this.gameOver,
      won: won ?? this.won,
      coins: coins ?? this.coins,
      hintDirection: clearHint ? null : hintDirection ?? this.hintDirection,
      lastMessage: clearMessage ? null : lastMessage ?? this.lastMessage,
      shieldActive: shieldActive ?? this.shieldActive,
    );
  }
}

class MoveOutcome {
  const MoveOutcome({
    required this.grid,
    required this.moved,
    required this.scoreGained,
    required this.manaGained,
    required this.won,
  });

  final List<Tile?> grid;
  final bool moved;
  final int scoreGained;
  final int manaGained;
  final bool won;
}
