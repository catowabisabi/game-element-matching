import 'package:flutter/material.dart';

enum ElementType {
  fire,
  water,
  earth,
  plant,
  lava,
  steam,
  stone,
  sage,
}

extension ElementTypeDisplay on ElementType {
  String get label => switch (this) {
        ElementType.fire => '火',
        ElementType.water => '水',
        ElementType.earth => '土',
        ElementType.plant => '植物',
        ElementType.lava => '岩漿',
        ElementType.steam => '蒸氣',
        ElementType.stone => '石頭',
        ElementType.sage => '賢者之石',
      };

  String get shortLabel => switch (this) {
        ElementType.fire => '火',
        ElementType.water => '水',
        ElementType.earth => '土',
        ElementType.plant => '植',
        ElementType.lava => '岩',
        ElementType.steam => '蒸',
        ElementType.stone => '石',
        ElementType.sage => '賢',
      };

  Color colorForLevel(int level) {
    final clamped = level.clamp(1, 4).toInt();
    return switch (this) {
      ElementType.fire => [
          const Color(0xffff4b45),
          const Color(0xffff6f3d),
          const Color(0xffff9148),
          const Color(0xffffc857),
        ][clamped - 1],
      ElementType.water => [
          const Color(0xff2f8cff),
          const Color(0xff42b4ff),
          const Color(0xff65d6ff),
          const Color(0xffa7ecff),
        ][clamped - 1],
      ElementType.earth => [
          const Color(0xff8a6239),
          const Color(0xffa57343),
          const Color(0xffc08452),
          const Color(0xffd9a066),
        ][clamped - 1],
      ElementType.plant => const Color(0xff36c46b),
      ElementType.lava => const Color(0xffff6a1a),
      ElementType.steam => const Color(0xffd7dde6),
      ElementType.stone => const Color(0xff565b66),
      ElementType.sage => const Color(0xff9d5cff),
    };
  }
}
