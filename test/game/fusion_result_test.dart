import 'package:elementary/game/domain/element_type.dart';
import 'package:elementary/game/domain/tile.dart';
import 'package:elementary/game/engine/fusion_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same basic element evolves and scores by level', () {
    final result = fuseTiles(
      const Tile(type: ElementType.fire, level: 2),
      const Tile(type: ElementType.fire, level: 2),
      1,
    );

    expect(result, isNotNull);
    expect(result!.tile!.type, ElementType.fire);
    expect(result.tile!.level, 3);
    expect(result.score, 70);
  });

  test('level four basic fusion can create sage stone', () {
    final result = fuseTiles(
      const Tile(type: ElementType.water, level: 3),
      const Tile(type: ElementType.water, level: 3),
      0.1,
    );

    expect(result!.tile!.type, ElementType.sage);
    expect(result.score, 5000);
  });

  test('cross element reactions match the HTML prototype', () {
    expect(
      fuseTiles(
        const Tile(type: ElementType.fire),
        const Tile(type: ElementType.earth),
        1,
      )!
          .tile!
          .type,
      ElementType.lava,
    );
    expect(
      fuseTiles(
        const Tile(type: ElementType.water),
        const Tile(type: ElementType.earth),
        1,
      )!
          .tile!
          .type,
      ElementType.plant,
    );
    expect(
      fuseTiles(
        const Tile(type: ElementType.fire),
        const Tile(type: ElementType.water),
        1,
      )!
          .tile!
          .type,
      ElementType.steam,
    );
  });

  test('steam reaction clears both tiles without mana', () {
    final result = fuseTiles(
      const Tile(type: ElementType.steam),
      const Tile(type: ElementType.earth),
      1,
    );

    expect(result, isNotNull);
    expect(result!.tile, isNull);
    expect(result.countsForMana, isFalse);
  });

  test('stone blocks fusion', () {
    final result = fuseTiles(
      const Tile(type: ElementType.stone),
      const Tile(type: ElementType.fire),
      1,
    );

    expect(result, isNull);
  });
}
