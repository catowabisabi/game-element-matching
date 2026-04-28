import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../pet/pet_state.dart';
import '../../services/audio_service.dart';
import '../../services/local_store.dart';
import '../domain/element_type.dart';
import '../domain/tile.dart';
import '../engine/direction.dart';
import '../engine/game_engine.dart';
import '../engine/game_snapshot.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({required this.store, super.key});

  final LocalStore store;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameEngine _engine;
  final _audio = AudioService();
  PetState _pet = PetState.initial();
  bool _loading = true;
  bool _showPet = false;

  GameSnapshot get _game => _engine.snapshot;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine();
    _audio.playBgm();
    _load();
  }

  Future<void> _load() async {
    final savedGame = await widget.store.loadGame();
    final savedPet = await widget.store.loadPet();
    if (!mounted) {
      return;
    }
    setState(() {
      _engine = GameEngine(initialSnapshot: savedGame);
      _pet = savedPet;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await widget.store.saveGame(_engine.snapshot);
    await widget.store.savePet(_pet);
  }

  Future<void> _move(Direction direction) async {
    final beforeGameOver = _game.gameOver || _game.won;
    final result = _engine.move(direction);
    if (!result) return;

    _audio.playMove();
    setState(() {});
    await _save();
    if (!beforeGameOver && (_game.gameOver || _game.won)) {
      if (_game.won) {
        _audio.playWin();
      } else {
        _audio.playGameOver();
      }
      _pet = _pet.afterGame(_game.score);
      setState(() {});
      await _save();
    }
  }

  void _restart() {
    setState(() => _engine.restart());
    _save();
  }

  void _useManaSkill() {
    setState(() => _engine.useManaSkill());
    _save();
  }

  void _buyHint() {
    setState(() => _engine.buyHint());
    _save();
  }

  void _feedPet() {
    const feedCost = 5;
    if (_game.coins < feedCost) {
      setState(() {
        _engine.snapshot = _game.copyWith(lastMessage: '餵食需要 $feedCost 金幣');
      });
      return;
    }

    final recentElement = _dominantElement();
    setState(() {
      _engine.snapshot = _game.copyWith(
        coins: _game.coins - feedCost,
        lastMessage: '${_pet.formName} 吃飽了',
      );
      _pet = _pet.feed(recentElement);
    });
    _save();
  }

  ElementType _dominantElement() {
    final counts = <ElementType, int>{};
    for (final tile in _game.grid.whereType<Tile>()) {
      if (tile.type == ElementType.stone || tile.type == ElementType.sage) {
        continue;
      }
      counts[tile.type] = (counts[tile.type] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return _pet.affinity;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final dx = velocity.dx;
    final dy = velocity.dy;
    if (math.max(dx.abs(), dy.abs()) < 280) {
      return;
    }

    if (dy < -dx.abs() && dy < -180) {
      if (_showPet) {
        return;
      }
      setState(() => _showPet = true);
      return;
    }
    if (dy > dx.abs() && dy > 180) {
      if (_showPet) {
        setState(() => _showPet = false);
        return;
      }
    }

    if (_showPet) {
      return;
    }

    if (dx.abs() > dy.abs()) {
      _move(dx < 0 ? Direction.left : Direction.right);
    } else {
      _move(dy < 0 ? Direction.up : Direction.down);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xff10121f),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff10121f),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanEnd: _handlePanEnd,
        onDoubleTap: _showPet ? _feedPet : _useManaSkill,
        onLongPress: _showPet ? _feedPet : _buyHint,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff10121f),
                Color(0xff16223b),
                Color(0xff211832),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: _showPet ? _petLayer() : _gameLayer(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gameLayer() {
    return Column(
      key: const ValueKey('game'),
      children: [
        _topBar(),
        _statsBand(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _board(),
                  const SizedBox(height: 8),
                  Text(
                    '👆 上滑查看寵物',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _legend(),
        _messageBand(),
      ],
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Elementary',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xffffb452),
              ),
            ),
          ),
          _iconAction(Icons.refresh_rounded, _restart),
          const SizedBox(width: 4),
          FloatingActionButton.small(
            onPressed: () => setState(() => _showPet = true),
            backgroundColor: const Color(0xff6fe08b).withOpacity(0.9),
            foregroundColor: Colors.white,
            tooltip: '查看寵物',
            child: const Icon(Icons.pets_rounded),
          ),
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, VoidCallback action) {
    return IconButton(
      onPressed: action,
      icon: Icon(icon),
      color: Colors.white.withOpacity(0.88),
      tooltip: '',
    );
  }

  Widget _statsBand() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _statBox('分數', _game.score, const Color(0xffffb452))),
          const SizedBox(width: 8),
          Expanded(child: _statBox('法力', _game.mana, const Color(0xff65d6ff))),
          const SizedBox(width: 8),
          Expanded(child: _statBox('金幣', _game.coins, const Color(0xff6fe08b))),
          const SizedBox(width: 8),
          Expanded(child: _statBox('紀錄', _game.record, const Color(0xffc991ff))),
        ],
      ),
    );
  }

  Widget _statBox(String label, int value, Color color) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.56),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _board() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox.square(
          dimension: math.min(side, 520),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gridSize * gridSize,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final tile = _game.grid[index];
                    return _TileCell(
                      tile: tile,
                      highlighted: _isHintEdge(index),
                    );
                  },
                ),
              ),
              if (_game.gameOver || _game.won) _resultOverlay(),
            ],
          ),
        );
      },
    );
  }

  bool _isHintEdge(int index) {
    final hint = _game.hintDirection;
    if (hint == null) {
      return false;
    }
    final row = index ~/ gridSize;
    final col = index % gridSize;
    return switch (hint) {
      Direction.up => row == 0,
      Direction.down => row == gridSize - 1,
      Direction.left => col == 0,
      Direction.right => col == gridSize - 1,
    };
  }

  Widget _resultOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.82),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _game.won ? '賢者之石完成' : '元素停滯',
                style: TextStyle(
                  color: _game.won ? const Color(0xffc991ff) : const Color(0xffff6f6f),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '分數 ${_game.score}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              IconButton.filled(
                onPressed: _restart,
                icon: const Icon(Icons.refresh_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xffff8a2b),
                  foregroundColor: Colors.white,
                  fixedSize: const Size(56, 56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend() {
    final items = [
      ElementType.fire,
      ElementType.water,
      ElementType.earth,
      ElementType.plant,
      ElementType.lava,
      ElementType.steam,
      ElementType.stone,
      ElementType.sage,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: item.colorForLevel(1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _messageBand() {
    final message = _game.lastMessage;
    return SizedBox(
      height: 48,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            message ?? '滑動合成，長按提示，雙擊施法，上滑看寵物',
            key: ValueKey(message),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(message == null ? 0.42 : 0.74),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _petLayer() {
    final petColor = _pet.affinity.colorForLevel(_pet.stage);
    return Column(
      key: const ValueKey('pet'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Pet Layer',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff6fe08b),
                  ),
                ),
              ),
              _iconAction(Icons.keyboard_arrow_down_rounded, () {
                setState(() => _showPet = false);
              }),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.92, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            petColor.withOpacity(0.96),
                            petColor.withOpacity(0.52),
                            Colors.black.withOpacity(0.16),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.24),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: petColor.withOpacity(0.38),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _pet.affinity.shortLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    _pet.formName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '階段 ${_pet.stage}  ·  親和 ${_pet.affinity.label}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.58),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _petMeter('飽足', _pet.hunger / 100, const Color(0xffffb452)),
                  const SizedBox(height: 12),
                  _petMeter('心情', _pet.mood / 100, const Color(0xff65d6ff)),
                  const SizedBox(height: 12),
                  _petMeter('進化', _pet.evolutionProgress, const Color(0xffc991ff)),
                  const SizedBox(height: 28),
                  Text(
                    '長按或雙擊餵食  ·  5 金幣',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.44),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _messageBand(),
      ],
    );
  }

  Widget _petMeter(String label, double value, Color color) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: value.clamp(0, 1).toDouble(),
                color: color,
                backgroundColor: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TileCell extends StatelessWidget {
  const _TileCell({
    required this.tile,
    required this.highlighted,
  });

  final Tile? tile;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final tile = this.tile;
    if (tile == null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xffffb452).withOpacity(0.16)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
          border: highlighted
              ? Border.all(color: const Color(0xffffb452).withOpacity(0.4))
              : null,
        ),
      );
    }

    final color = tile.type.colorForLevel(tile.level);
    final textColor = tile.type == ElementType.steam
        ? const Color(0xff20242d)
        : Colors.white;

    return AnimatedOpacity(
      opacity: tile.justSpawned || tile.justMerged ? 0.74 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: tile.justSpawned ? 0.74 : 1,
          end: tile.justMerged ? 1.05 : 1,
        ),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.98),
                Color.lerp(color, Colors.black, 0.24)!,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlighted
                  ? const Color(0xffffe1a6)
                  : Colors.white.withOpacity(tile.type == ElementType.stone ? 0.18 : 0.08),
              width: highlighted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(tile.justMerged ? 0.8 : 0.34),
                blurRadius: tile.justMerged ? 24 : (tile.type == ElementType.sage ? 22 : 12),
                spreadRadius: tile.justMerged ? 8 : 0,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(7),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tile.type == ElementType.sage ? '賢者' : tile.type.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (tile.isBasic && tile.level > 1) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lv.${tile.level}',
                        style: TextStyle(
                          color: textColor.withOpacity(0.9),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
