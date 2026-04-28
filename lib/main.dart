import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

// ======== 元素合成 Element Fusion - 手機版 ========

const int GRID_SIZE = 4;
const int STONE_INTERVAL = 10;
const int MANA_COST = 3;

enum ElementType { none, fire, water, earth, plant, lava, steam, stone, sage }
enum Direction { left, right, up, down }

class Tile {
  final ElementType type;
  final int level;
  final bool merged;
  Tile({required this.type, this.level = 1, this.merged = false});
  Tile copyWith({ElementType? type, int? level, bool? merged}) =>
    Tile(type: type ?? this.type, level: level ?? this.level, merged: merged ?? this.merged);
}

class GameState {
  List<Tile?> grid = List.filled(GRID_SIZE * GRID_SIZE, null);
  int score = 0, mana = 0, record = 0, moveCount = 0;
  bool gameOver = false, won = false;
}

void main() => runApp(const ElementFusionApp());

class ElementFusionApp extends StatelessWidget {
  const ElementFusionApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Element Fusion',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange), useMaterial3: true),
    home: const GameScreen(),
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState _state;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _state = GameState();
    _loadRecord();
    _initGame();
  }

  Future<void> _loadRecord() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _state.record = prefs.getInt('elementFusionRecord') ?? 0);
  }

  Future<void> _saveRecord() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('elementFusionRecord', _state.record);
  }

  void _initGame() {
    setState(() {
      _state.grid = List.filled(GRID_SIZE * GRID_SIZE, null);
      _state.score = 0; _state.mana = 0; _state.moveCount = 0;
      _state.gameOver = false; _state.won = false;
    });
    _spawnTile(); _spawnTile();
  }

  Tile? getFusionResult(Tile? t1, Tile? t2) {
    if (t1 == null || t2 == null) return null;
    final type1 = t1.type, type2 = t2.type;
    if (type1 == ElementType.sage || type2 == ElementType.sage) return Tile(type: ElementType.sage);
    if (type1 == type2 && type1 != ElementType.none && type1 != ElementType.plant &&
        type1 != ElementType.lava && type1 != ElementType.steam && type1 != ElementType.stone) {
      final newLevel = (t1.level + 1).clamp(1, 4);
      if (newLevel == 4 && _random.nextDouble() < 0.3) { _state.won = true; return Tile(type: ElementType.sage); }
      return Tile(type: type1, level: newLevel);
    }
    if ((type1 == ElementType.fire && type2 == ElementType.earth) || (type1 == ElementType.earth && type2 == ElementType.fire)) return Tile(type: ElementType.lava);
    if ((type1 == ElementType.water && type2 == ElementType.earth) || (type1 == ElementType.earth && type2 == ElementType.water)) return Tile(type: ElementType.plant);
    if ((type1 == ElementType.fire && type2 == ElementType.water) || (type1 == ElementType.water && type2 == ElementType.fire)) return Tile(type: ElementType.steam);
    return null;
  }

  void _spawnTile() {
    final empty = <int>[for (int i = 0; i < _state.grid.length; i++) if (_state.grid[i] == null) i];
    if (empty.isEmpty) return;
    final types = [ElementType.fire, ElementType.water, ElementType.earth];
    _state.grid[empty[_random.nextInt(empty.length)]] = Tile(type: types[_random.nextInt(types.length)]);
  }

  void _spawnStone() {
    final empty = <int>[for (int i = 0; i < _state.grid.length; i++) if (_state.grid[i] == null) i];
    if (empty.isEmpty) return;
    _state.grid[empty[_random.nextInt(empty.length)]] = Tile(type: ElementType.stone);
  }

  bool _move(Direction dir) {
    if (_state.gameOver || _state.won) return false;
    bool moved = false, hasMerge = false; int merges = 0;
    final old = List<Tile?>.from(_state.grid);

    if (dir == Direction.left || dir == Direction.right) {
      for (int row = 0; row < GRID_SIZE; row++) {
        final line = <Tile?>[for (int c = 0; c < GRID_SIZE; c++) _state.grid[row * GRID_SIZE + c]];
        final result = _mergeLine(line, dir == Direction.right);
        for (int c = 0; c < GRID_SIZE; c++) _state.grid[row * GRID_SIZE + c] = result[c];
      }
    } else {
      for (int col = 0; col < GRID_SIZE; col++) {
        final line = <Tile?>[for (int r = 0; r < GRID_SIZE; r++) _state.grid[r * GRID_SIZE + col]];
        final result = _mergeLine(line, dir == Direction.down);
        for (int r = 0; r < GRID_SIZE; r++) _state.grid[r * GRID_SIZE + col] = result[r];
      }
    }

    for (int i = 0; i < _state.grid.length; i++) {
      if ((old[i]?.type != _state.grid[i]?.type) || (old[i]?.level != _state.grid[i]?.level)) {
        moved = true;
        if (_state.grid[i]?.merged == true) { hasMerge = true; merges++; }
      }
    }

    if (moved) {
      _state.moveCount++;
      if (hasMerge) _state.mana++;
      if (_state.moveCount % STONE_INTERVAL == 0) _spawnStone();
      _state.score += merges * 10;
      if (_state.score > _state.record) { _state.record = _state.score; _saveRecord(); }
      _spawnTile(); _checkGameOver();
    }
    setState(() {});
    return moved;
  }

  List<Tile?> _mergeLine(List<Tile?> line, bool rev) {
    if (rev) line = line.reversed.toList();
    final tiles = line.where((t) => t != null).toList();
    final result = <Tile?>[];
    for (int i = 0; i < tiles.length; i++) {
      if (i + 1 < tiles.length) {
        final fusion = getFusionResult(tiles[i], tiles[i + 1]);
        if (fusion != null) { result.add(fusion.copyWith(merged: true)); i++; continue; }
      }
      result.add(tiles[i]);
    }
    while (result.length < GRID_SIZE) result.add(null);
    return rev ? result.reversed.toList() : result;
  }

  void _checkGameOver() {
    if (_state.grid.any((t) => t == null)) return;
    for (int i = 0; i < GRID_SIZE; i++) {
      for (int j = 0; j < GRID_SIZE; j++) {
        final cur = _state.grid[i * GRID_SIZE + j];
        if (cur == null) continue;
        if (j + 1 < GRID_SIZE && getFusionResult(cur, _state.grid[i * GRID_SIZE + j + 1]) != null) return;
        if (i + 1 < GRID_SIZE && getFusionResult(cur, _state.grid[(i + 1) * GRID_SIZE + j]) != null) return;
      }
    }
    setState(() => _state.gameOver = true);
  }

  void _useManaSkill() {
    if (_state.mana < MANA_COST) return;
    setState(() => _state.mana -= MANA_COST);
    final stoneIdx = _state.grid.indexWhere((t) => t?.type == ElementType.stone);
    if (stoneIdx >= 0) { setState(() => _state.grid[stoneIdx] = null); return; }
    int minLvl = 999, minIdx = -1;
    for (int i = 0; i < _state.grid.length; i++) {
      if (_state.grid[i] != null && _state.grid[i]!.level < minLvl && _state.grid[i]!.type != ElementType.sage) {
        minLvl = _state.grid[i]!.level; minIdx = i;
      }
    }
    if (minIdx >= 0) setState(() => _state.grid[minIdx] = null);
  }

  String _name(ElementType t) {
    switch (t) {
      case ElementType.fire: return '火';
      case ElementType.water: return '水';
      case ElementType.earth: return '土';
      case ElementType.plant: return '植物';
      case ElementType.lava: return '岩漿';
      case ElementType.steam: return '蒸氣';
      case ElementType.stone: return '石';
      case ElementType.sage: return '賢者';
      default: return '';
    }
  }

  Color _color(ElementType t, int lvl) {
    if (t == ElementType.stone) return Colors.grey;
    if (t == ElementType.sage) return Colors.purple;
    if (t == ElementType.plant) return Colors.green;
    if (t == ElementType.lava) return Colors.orange;
    if (t == ElementType.steam) return Colors.grey.shade300;
    final c = {
      ElementType.fire: [Colors.red.shade400, Colors.red, Colors.red.shade700, Colors.red.shade900],
      ElementType.water: [Colors.blue.shade400, Colors.blue, Colors.blue.shade700, Colors.blue.shade900],
      ElementType.earth: [Colors.brown.shade300, Colors.brown, Colors.brown.shade700, Colors.brown.shade900],
    }[t] ?? [Colors.grey];
    return c[(lvl - 1).clamp(0, 3)];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0f0f1a),
    appBar: AppBar(
      title: const Text('元素合成', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF1a1a2e),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.bolt, color: _state.mana >= MANA_COST ? Colors.cyan : Colors.grey),
          onPressed: _state.mana >= MANA_COST ? _useManaSkill : null,
          tooltip: '法力技能 (需 $MANA_COST 法力)',
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _initGame,
          tooltip: '重新開始',
        ),
      ],
    ),
    body: Column(children: [
      const SizedBox(height: 10),
      _statsBar(),
      const SizedBox(height: 10),
      Expanded(child: Center(child: _grid())),
      _legend(),
      const SizedBox(height: 10),
    ]),
  );

  Widget _statsBar() => Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _statBox('分數', _state.score.toString(), Colors.orange),
      _statBox('法力', _state.mana.toString(), Colors.cyan),
      _statBox('最高', _state.record.toString(), Colors.purple),
    ]),
  );

  Widget _statBox(String l, String v, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      Text(v, style: TextStyle(color: c, fontSize: 24, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _grid() {
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if (d.primaryVelocity != null) {
          if (d.primaryVelocity! < -100) _move(Direction.up);
          else if (d.primaryVelocity! > 100) _move(Direction.down);
        }
      },
      onHorizontalDragEnd: (d) {
        if (d.primaryVelocity != null) {
          if (d.primaryVelocity! < -100) _move(Direction.left);
          else if (d.primaryVelocity! > 100) _move(Direction.right);
        }
      },
      onTap: _useManaSkill,
      child: Stack(children: [
        _gridView(),
        if (_state.gameOver || _state.won) _overlay(),
      ]),
    );
  }

  Widget _gridView() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 80),
      itemCount: 16,
      itemBuilder: (_, i) {
        final tile = _state.grid[i];
        if (tile == null) return Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)));
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_color(tile.type, tile.level), _color(tile.type, tile.level).withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: _color(tile.type, tile.level).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
            border: tile.type == ElementType.stone ? Border.all(color: Colors.grey.shade600, width: 2) : null,
          ),
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_name(tile.type), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            if (tile.level > 1 && tile.type != ElementType.plant && tile.type != ElementType.lava && tile.type != ElementType.steam && tile.type != ElementType.stone && tile.type != ElementType.sage)
              Text('Lv${tile.level}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            if (tile.type == ElementType.sage) const Text('★', style: TextStyle(color: Colors.yellow, fontSize: 24)),
          ])),
        );
      },
    ),
  );

  Widget _overlay() => Container(
    decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(12)),
    child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(_state.won ? '🎉 勝利!' : '遊戲結束', style: TextStyle(color: _state.won ? Colors.purple : Colors.red, fontSize: 32)),
      const SizedBox(height: 10),
      Text('分數: ${_state.score}', style: const TextStyle(color: Colors.grey, fontSize: 18)),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _initGame, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('重新開始')),
    ])),
  );

  Widget _legend() => Wrap(
    spacing: 8, runSpacing: 5, alignment: WrapAlignment.center,
    children: const [
      _LegendItem(color: Colors.red, name: '火'),
      _LegendItem(color: Colors.blue, name: '水'),
      _LegendItem(color: Colors.brown, name: '土'),
      _LegendItem(color: Colors.green, name: '植物'),
      _LegendItem(color: Colors.orange, name: '岩漿'),
      _LegendItem(color: Colors.grey, name: '蒸氣'),
      _LegendItem(color: Colors.grey, name: '石'),
      _LegendItem(color: Colors.purple, name: '賢者'),
    ],
  );
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String name;
  const _LegendItem({required this.color, required this.name});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 4),
    Text(name, style: const TextStyle(color: Colors.grey, fontSize: 11)),
  ]);
}
