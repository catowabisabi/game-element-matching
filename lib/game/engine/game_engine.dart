import 'dart:math';

import '../domain/element_type.dart';
import '../domain/tile.dart';
import 'direction.dart';
import 'fusion_result.dart';
import 'game_snapshot.dart';

class GameEngine {
  GameEngine({
    Random? random,
    GameSnapshot? initialSnapshot,
  })  : _random = random ?? Random(),
        snapshot = initialSnapshot ?? _newSnapshot() {
    if (initialSnapshot == null) {
      restart(keepRecord: true);
    }
  }

  final Random _random;
  GameSnapshot snapshot;

  static GameSnapshot _newSnapshot({int record = 0, int coins = 0}) {
    return GameSnapshot(
      grid: List<Tile?>.filled(gridSize * gridSize, null),
      score: 0,
      mana: 0,
      record: record,
      moveCount: 0,
      gameOver: false,
      won: false,
      coins: coins,
    );
  }

  void restart({bool keepRecord = true}) {
    final record = keepRecord ? snapshot.record : 0;
    final coins = keepRecord ? snapshot.coins : 0;
    snapshot = _newSnapshot(record: record, coins: coins);
    _spawnTile();
    _spawnTile();
    snapshot = snapshot.copyWith(lastMessage: '新的元素開始流動');
  }

  bool move(Direction direction) {
    if (snapshot.gameOver || snapshot.won) {
      return false;
    }

    final cleaned = _clearTransientFlags(snapshot.grid);
    final outcome = _moveBoard(cleaned, direction, randomValue: _random.nextDouble());
    if (!outcome.moved) {
      snapshot = snapshot.copyWith(
        grid: cleaned,
        lastMessage: '這邊沒有流動空間',
        clearHint: true,
      );
      return false;
    }

    var nextGrid = outcome.grid;
    var nextMoveCount = snapshot.moveCount + 1;
    if (nextMoveCount % stoneInterval == 0) {
      nextGrid = _spawnStoneOn(nextGrid);
    }
    nextGrid = _spawnTileOn(nextGrid);

    final nextScore = snapshot.score + outcome.scoreGained;
    final coinsEarned = _coinsForMove(outcome.scoreGained, outcome.won);
    final nextRecord = max(snapshot.record, nextScore);
    final isGameOver = outcome.won ? false : _isGameOver(nextGrid);

    snapshot = snapshot.copyWith(
      grid: nextGrid,
      score: nextScore,
      record: nextRecord,
      mana: snapshot.mana + outcome.manaGained,
      moveCount: nextMoveCount,
      won: outcome.won,
      gameOver: isGameOver,
      coins: snapshot.coins + coinsEarned,
      clearHint: true,
      clearMessage: !outcome.won && !isGameOver && coinsEarned == 0,
      lastMessage: outcome.won
          ? '賢者之石誕生了'
          : isGameOver
              ? '棋盤已經沒有反應空間'
          : coinsEarned > 0
              ? '獲得 $coinsEarned 金幣'
              : null,
    );
    return true;
  }

  bool useManaSkill() {
    if (snapshot.gameOver || snapshot.won || snapshot.mana < manaCost) {
      snapshot = snapshot.copyWith(lastMessage: '法力不足');
      return false;
    }

    final grid = List<Tile?>.from(snapshot.grid);
    final target = _skillTarget(grid);
    if (target == -1) {
      snapshot = snapshot.copyWith(lastMessage: '沒有可清除的元素');
      return false;
    }

    grid[target] = null;
    snapshot = snapshot.copyWith(
      grid: grid,
      mana: snapshot.mana - manaCost,
      lastMessage: '法力清出一格空間',
    );
    return true;
  }

  bool buyHint() {
    const hintCost = 10;
    if (snapshot.coins < hintCost) {
      snapshot = snapshot.copyWith(lastMessage: '提示需要 $hintCost 金幣');
      return false;
    }

    final direction = recommendDirection();
    if (direction == null) {
      snapshot = snapshot.copyWith(lastMessage: '現在沒有好走法');
      return false;
    }

    snapshot = snapshot.copyWith(
      coins: snapshot.coins - hintCost,
      hintDirection: direction,
      lastMessage: '元素建議往${direction.label}',
    );
    return true;
  }

  Direction? recommendDirection() {
    Direction? bestDirection;
    var bestValue = -1;
    for (final direction in Direction.values) {
      final outcome = _moveBoard(
        _clearTransientFlags(snapshot.grid),
        direction,
        randomValue: 1,
      );
      if (!outcome.moved) {
        continue;
      }

      final value = outcome.scoreGained * 10 +
          outcome.manaGained * 25 +
          outcome.grid.where((tile) => tile == null).length * 4 +
          (outcome.won ? 100000 : 0);
      if (value > bestValue) {
        bestValue = value;
        bestDirection = direction;
      }
    }
    return bestDirection;
  }

  MoveOutcome _moveBoard(
    List<Tile?> grid,
    Direction direction, {
    required double randomValue,
  }) {
    final next = List<Tile?>.filled(gridSize * gridSize, null);
    var scoreGained = 0;
    var manaGained = 0;
    var won = false;

    for (var lane = 0; lane < gridSize; lane++) {
      final line = _readLine(grid, direction, lane);
      final lineOutcome = _moveLine(
        line,
        towardEnd: direction == Direction.right || direction == Direction.down,
        randomValue: randomValue,
      );
      scoreGained += lineOutcome.scoreGained;
      manaGained += lineOutcome.manaGained;
      won = won || lineOutcome.won;
      _writeLine(next, direction, lane, lineOutcome.grid);
    }

    return MoveOutcome(
      grid: next,
      moved: !_sameGrid(grid, next),
      scoreGained: scoreGained,
      manaGained: manaGained,
      won: won,
    );
  }

  MoveOutcome _moveLine(
    List<Tile?> line, {
    required bool towardEnd,
    required double randomValue,
  }) {
    final result = List<Tile?>.filled(gridSize, null);
    var segmentStart = 0;
    var scoreGained = 0;
    var manaGained = 0;
    var won = false;

    void flushSegment(int start, int endExclusive) {
      final positions = List<int>.generate(endExclusive - start, (i) => start + i);
      if (positions.isEmpty) {
        return;
      }

      final sourceTiles = [
        for (final position in positions)
          if (line[position] != null) line[position]!,
      ];
      final mergeTiles = towardEnd ? sourceTiles.reversed.toList() : sourceTiles;
      final mergedTiles = <Tile?>[];

      for (var i = 0; i < mergeTiles.length; i++) {
        final current = mergeTiles[i];
        if (i + 1 < mergeTiles.length) {
          final fusion = fuseTiles(current, mergeTiles[i + 1], randomValue);
          if (fusion != null) {
            if (fusion.tile != null) {
              final fusedTile = fusion.tile!.copyWith(justMerged: true);
              mergedTiles.add(fusedTile);
              won = won || fusedTile.type == ElementType.sage;
            }
            scoreGained += fusion.score;
            if (fusion.countsForMana) {
              manaGained++;
            }
            i++;
            continue;
          }
        }
        mergedTiles.add(current);
      }

      while (mergedTiles.length < positions.length) {
        mergedTiles.add(null);
      }

      final placedTiles = towardEnd ? mergedTiles.reversed.toList() : mergedTiles;
      for (var i = 0; i < positions.length; i++) {
        result[positions[i]] = placedTiles[i];
      }
    }

    for (var index = 0; index < gridSize; index++) {
      final tile = line[index];
      if (tile?.type == ElementType.stone) {
        flushSegment(segmentStart, index);
        result[index] = tile;
        segmentStart = index + 1;
      }
    }
    flushSegment(segmentStart, gridSize);

    return MoveOutcome(
      grid: result,
      moved: !_sameLine(line, result),
      scoreGained: scoreGained,
      manaGained: manaGained,
      won: won,
    );
  }

  List<Tile?> _readLine(List<Tile?> grid, Direction direction, int lane) {
    if (direction == Direction.left || direction == Direction.right) {
      return [
        for (var col = 0; col < gridSize; col++) grid[_index(lane, col)],
      ];
    }
    return [
      for (var row = 0; row < gridSize; row++) grid[_index(row, lane)],
    ];
  }

  void _writeLine(
    List<Tile?> grid,
    Direction direction,
    int lane,
    List<Tile?> line,
  ) {
    if (direction == Direction.left || direction == Direction.right) {
      for (var col = 0; col < gridSize; col++) {
        grid[_index(lane, col)] = line[col];
      }
    } else {
      for (var row = 0; row < gridSize; row++) {
        grid[_index(row, lane)] = line[row];
      }
    }
  }

  void _spawnTile() {
    snapshot = snapshot.copyWith(grid: _spawnTileOn(snapshot.grid));
  }

  List<Tile?> _spawnTileOn(List<Tile?> source) {
    final grid = List<Tile?>.from(source);
    final empty = _emptyIndexes(grid);
    if (empty.isEmpty) {
      return grid;
    }

    final roll = _random.nextDouble();
    final type = roll < 0.4
        ? ElementType.fire
        : roll < 0.7
            ? ElementType.water
            : ElementType.earth;
    grid[empty[_random.nextInt(empty.length)]] = Tile(
      type: type,
      justSpawned: true,
    );
    return grid;
  }

  List<Tile?> _spawnStoneOn(List<Tile?> source) {
    final grid = List<Tile?>.from(source);
    final empty = _emptyIndexes(grid);
    if (empty.isEmpty) {
      return grid;
    }

    grid[empty[_random.nextInt(empty.length)]] = const Tile(
      type: ElementType.stone,
      level: 0,
      justSpawned: true,
    );
    return grid;
  }

  List<int> _emptyIndexes(List<Tile?> grid) {
    return [
      for (var i = 0; i < grid.length; i++)
        if (grid[i] == null) i,
    ];
  }

  int _skillTarget(List<Tile?> grid) {
    final stoneIndex = grid.indexWhere((tile) => tile?.type == ElementType.stone);
    if (stoneIndex != -1) {
      return stoneIndex;
    }

    var bestIndex = -1;
    var bestLevel = 999;
    for (var i = 0; i < grid.length; i++) {
      final tile = grid[i];
      if (tile == null || tile.type == ElementType.sage) {
        continue;
      }
      if (tile.level < bestLevel) {
        bestLevel = tile.level;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  bool _isGameOver(List<Tile?> grid) {
    if (grid.any((tile) => tile == null)) {
      return false;
    }

    for (final direction in Direction.values) {
      final outcome = _moveBoard(grid, direction, randomValue: 1);
      if (outcome.moved) {
        return false;
      }
    }
    return true;
  }

  int _coinsForMove(int scoreGained, bool won) {
    return scoreGained ~/ 100 + (won ? 50 : 0);
  }

  List<Tile?> _clearTransientFlags(List<Tile?> grid) {
    return [
      for (final tile in grid)
        tile?.copyWith(justMerged: false, justSpawned: false),
    ];
  }

  bool _sameGrid(List<Tile?> a, List<Tile?> b) {
    for (var i = 0; i < a.length; i++) {
      if (!_sameTile(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  bool _sameLine(List<Tile?> a, List<Tile?> b) {
    for (var i = 0; i < a.length; i++) {
      if (!_sameTile(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  bool _sameTile(Tile? a, Tile? b) {
    return a?.type == b?.type && a?.level == b?.level;
  }

  int _index(int row, int col) => row * gridSize + col;
}
