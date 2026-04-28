enum Direction {
  up,
  down,
  left,
  right,
}

extension DirectionLabel on Direction {
  String get label => switch (this) {
        Direction.up => '上',
        Direction.down => '下',
        Direction.left => '左',
        Direction.right => '右',
      };
}
