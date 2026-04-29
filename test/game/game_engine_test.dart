import 'dart:math';

import 'package:elementary/game/domain/element_type.dart';
import 'package:elementary/game/domain/tile.dart';
import 'package:elementary/game/engine/direction.dart';
import 'package:elementary/game/engine/game_engine.dart';
import 'package:elementary/game/engine/game_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('swipe left fuses matching fire tiles', () {
    final engine = GameEngine(
      random: Random(1),
      initialSnapshot: _snapshot([
        Tile(type: ElementType.fire),
        Tile(type: ElementType.fire),
        null,
        null,
      ]),
    );

    expect(engine.move(Direction.left), isTrue);
    expect(engine.snapshot.grid[0]!.type, ElementType.fire);
    expect(engine.snapshot.grid[0]!.level, 2);
    expect(engine.snapshot.score, 30);
    expect(engine.snapshot.mana, 1);
  });

  test('stone keeps its position and splits a lane', () {
    final engine = GameEngine(
      random: Random(1),
      initialSnapshot: _snapshot([
        null,
        Tile(type: ElementType.stone, level: 0),
        Tile(type: ElementType.water),
        Tile(type: ElementType.water),
      ]),
    );

    engine.move(Direction.left);

    expect(engine.snapshot.grid[1]!.type, ElementType.stone);
    expect(engine.snapshot.grid[2]!.type, ElementType.water);
    expect(engine.snapshot.grid[2]!.level, 2);
  });

  test('mana skill removes a stone first', () {
    final engine = GameEngine(
      initialSnapshot: _snapshot(
        [
          Tile(type: ElementType.fire),
          Tile(type: ElementType.stone, level: 0),
          null,
          null,
        ],
        mana: manaCost,
      ),
    );

    expect(engine.useManaSkill(), isTrue);
    expect(engine.snapshot.grid[1], isNull);
    expect(engine.snapshot.mana, 0);
  });

  test('buy hint spends coins and chooses a direction', () {
    final engine = GameEngine(
      initialSnapshot: _snapshot(
        [
          Tile(type: ElementType.earth),
          Tile(type: ElementType.earth),
          null,
          null,
        ],
        coins: 20,
      ),
    );

    expect(engine.buyHint(), isTrue);
    expect(engine.snapshot.coins, 10);
    expect(engine.snapshot.hintDirection, isNotNull);
  });
}

GameSnapshot _snapshot(
  List<Tile?> firstRow, {
  int mana = 0,
  int coins = 0,
}) {
  return GameSnapshot(
    grid: [
      ...firstRow,
      ...List<Tile?>.filled(12, null),
    ],
    score: 0,
    mana: mana,
    record: 0,
    moveCount: 0,
    gameOver: false,
    won: false,
    coins: coins,
  );
}
