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

// --- Tutorial Overlay ---

class TutorialStep {
  final String text;
  final Alignment? targetAlignment;
  final Offset? targetOffset;
  final double? targetSize;

  const TutorialStep({
    required this.text,
    this.targetAlignment,
    this.targetOffset,
    this.targetSize,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onDismiss;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onDismiss,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 340),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      _controller.reverse().then((_) {
        if (mounted) {
          setState(() => _currentStep++);
          _controller.forward();
        }
      });
    } else {
      _controller.reverse().then((_) => widget.onDismiss());
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_currentStep];
    return GestureDetector(
      onTap: _nextStep,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Semi-transparent dark overlay
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(color: Colors.black.withOpacity(0.72)),
              ),
              // Content
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  alignment: step.targetAlignment ?? Alignment.center,
                  child: _buildTooltip(step),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTooltip(TutorialStep step) {
    return Align(
      alignment: step.targetAlignment ?? Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xff1e2540),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              step.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_currentStep + 1}/${widget.steps.length}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.44),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '點擊繼續',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.44),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Swipe Animation Overlay ---

class SwipeArrow extends StatefulWidget {
  final Alignment alignment;
  final IconData icon;

  const SwipeArrow({
    super.key,
    required this.alignment,
    required this.icon,
  });

  @override
  State<SwipeArrow> createState() => _SwipeArrowState();
}

class _SwipeArrowState extends State<SwipeArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final offset = widget.alignment.x * 16 * _animation.value;
        final offsetY = widget.alignment.y * 16 * _animation.value;
        return Transform.translate(
          offset: Offset(offset, offsetY),
          child: Icon(
            widget.icon,
            color: Colors.white.withOpacity(0.7),
            size: 40,
          ),
        );
      },
    );
  }
}

// --- Tooltip Popup ---

class TooltipPopup extends StatefulWidget {
  final String text;
  final VoidCallback onDismiss;

  const TooltipPopup({
    super.key,
    required this.text,
    required this.onDismiss,
  });

  @override
  State<TooltipPopup> createState() => _TooltipPopupState();
}

class _TooltipPopupState extends State<TooltipPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 260),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xff2a3555),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

enum _MainTab { game, pet, shop, settings }

class GameScreen extends StatefulWidget {
  const GameScreen({required this.store, super.key});

  final LocalStore store;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late GameEngine _engine;
  final _audio = AudioService();
  PetState _pet = PetState.initial();
  bool _loading = true;
  bool _showPet = false;
  _MainTab _tab = _MainTab.game;
  double _bgmVolume = 0.22;
  double _sfxVolume = 0.72;
  final GlobalKey<_PetAnimationWidgetState> _petAnimKey = GlobalKey();

  // Tutorial state
  bool _showTutorial = false;
  bool _seenTutorial = false;
  String? _activeTooltip;
  bool _showPetTooltips = false;
  int _hintCount = 0;
  int _manaCount = 0;
  int _feedCount = 0;

  // Animated board state - tracks tiles with their positions for animation
  Map<int, _AnimatedTile> _animatedTiles = {};
  // Grid dimensions for animation calculation
  double _cellSize = 0;
  double _spacing = 10;

  // Invalid move feedback
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _shakeBorder = false;

  GameSnapshot get _game => _engine.snapshot;

  @override
  void initState() {
    super.initState();
    _engine = GameEngine();
    _audio.playBgm();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(_shakeController);
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _shakeBorder = false);
      }
    });
    _load();
  }

  Future<void> _load() async {
    final savedGame = await widget.store.loadGame();
    final savedPet = await widget.store.loadPet();
    _seenTutorial = await widget.store.getSeenTutorial();
    if (!mounted) {
      return;
    }
    setState(() {
      _engine = GameEngine(initialSnapshot: savedGame);
      _pet = savedPet;
      _loading = false;
      if (!_seenTutorial) {
        _showTutorial = true;
      }
    });
  }

  Future<void> _save() async {
    await widget.store.saveGame(_engine.snapshot);
    await widget.store.savePet(_pet);
  }

  void _selectTab(_MainTab tab) {
    setState(() {
      _tab = tab;
      _showPet = tab == _MainTab.pet;
      if (_showPet && !_seenTutorial) {
        _showPetTooltips = true;
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _move(Direction direction) async {
    final beforeGameOver = _game.gameOver || _game.won;
    final result = _engine.move(direction);
    if (!result) {
      // Invalid move - show feedback
      setState(() {
        _shakeBorder = true;
      });
      _shakeController.forward(from: 0);
      setState(() {});
      return;
    }

    _audio.playMove();
    setState(() {});
    await _save();
    if (!beforeGameOver && (_game.gameOver || _game.won)) {
      if (_game.won) {
        _audio.playWin();
        // Trigger happy animation on win
        _petAnimKey.currentState?.triggerHappyAnimation();
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
    final result = _engine.useManaSkill();
    if (result && _manaCount == 0) {
      _manaCount = 1;
      _activeTooltip = '法力技能消耗3法力移除最低級元素';
    }
    setState(() {});
    _save();
  }

  void _buyHint() {
    final result = _engine.buyHint();
    if (result && _hintCount == 0) {
      _hintCount = 1;
      _activeTooltip = '提示用10金幣顯示推薦方向';
    }
    setState(() {});
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
    final fed = _feedCount == 0;
    if (fed) {
      _feedCount = 1;
      _activeTooltip = '餵食寵物需要5金幣';
    }
    final oldStage = _pet.stage;
    setState(() {
      _engine.snapshot = _game.copyWith(
        coins: _game.coins - feedCost,
        lastMessage: '${_pet.formName} 吃飽了',
      );
      _pet = _pet.feed(recentElement);
    });
    _save();

    // Trigger eat animation
    _petAnimKey.currentState?.triggerEatAnimation();

    // Trigger evolve animation if stage changed
    if (_pet.stage > oldStage) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _petAnimKey.currentState?.triggerEvolveAnimation();
      });
    }
  }

  void _showShop() {
    _audio.playShop();
    _selectTab(_MainTab.shop);
  }

  void _buyShopItem(_ShopItem item) {
    setState(() {
      switch (item) {
        case _ShopItem.hint:
          _buyHint();
          break;
        case _ShopItem.mana:
          _engine.buyMana();
          break;
        case _ShopItem.food:
          _feedPet();
          break;
        case _ShopItem.shield:
          _engine.buyShield();
          break;
        case _ShopItem.reroll:
          _engine.buyReroll();
          break;
      }
    });
    _audio.playShop();
    _save();
  }

  void _showDemoPurchase(String title, String price, int coins) {
    _audio.playShop();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff151b2c),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _DemoPurchaseSheet(
        title: title,
        price: price,
        onConfirm: () {
          setState(() {
            _engine.snapshot = _game.copyWith(
              coins: _game.coins + coins,
              lastMessage: 'Demo purchase complete: +$coins coins',
            );
          });
          _audio.playWin();
          _save();
          Navigator.of(context).pop();
        },
      ),
    );
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
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanEnd: _tab == _MainTab.game ? _handlePanEnd : null,
            onDoubleTap: _tab == _MainTab.pet
                ? _feedPet
                : _tab == _MainTab.game
                    ? _useManaSkill
                    : null,
            onLongPress: _tab == _MainTab.pet
                ? _feedPet
                : _tab == _MainTab.game
                    ? _buyHint
                    : null,
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
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ));
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: _activeLayer(),
                ),
              ),
            ),
          ),
          if (_showTutorial)
            TutorialOverlay(
              steps: _tutorialSteps,
              onDismiss: _dismissTutorial,
            ),
          if (_activeTooltip != null)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: TooltipPopup(
                  text: _activeTooltip!,
                  onDismiss: () => setState(() => _activeTooltip = null),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        backgroundColor: const Color(0xff12182a),
        indicatorColor: const Color(0xff6fe08b).withOpacity(0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Game',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_rounded),
            label: 'Pet',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
        onDestinationSelected: (index) => _selectTab(_MainTab.values[index]),
      ),
    );
  }

  Widget _activeLayer() {
    return switch (_tab) {
      _MainTab.game => _gameLayer(),
      _MainTab.pet => _petLayer(),
      _MainTab.shop => _shopPage(),
      _MainTab.settings => _settingsPage(),
    };
  }

  List<TutorialStep> get _tutorialSteps => [
        const TutorialStep(
          text: '滑動螢幕移動元素\n左右下方向滑動，上方為寵物按鈕',
          targetAlignment: Alignment.center,
        ),
        const TutorialStep(
          text: '相同元素合併升級\n火＋火 →更高級火元素',
          targetAlignment: Alignment.center,
        ),
        const TutorialStep(
          text: '長按顯示提示\n花費10金幣推薦方向',
          targetAlignment: Alignment.center,
        ),
        const TutorialStep(
          text: '雙擊使用法力技能\n消耗3法力移除最低級元素',
          targetAlignment: Alignment.center,
        ),
        const TutorialStep(
          text: '點擊右上角寵物按鈕\n查看並餵食寵物',
          targetAlignment: Alignment.topRight,
        ),
      ];

  Future<void> _dismissTutorial() async {
    await widget.store.setSeenTutorial(true);
    if (mounted) {
      setState(() {
        _showTutorial = false;
        _seenTutorial = true;
      });
    }
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
                    '👆 點擊右上角寵物按鈕',
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
          _iconAction(Icons.shopping_bag_rounded, _showShop),
          const SizedBox(width: 4),
          _iconAction(Icons.refresh_rounded, _restart),
          const SizedBox(width: 4),
          FloatingActionButton.small(
            onPressed: () => _selectTab(_MainTab.pet),
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
          Expanded(
              child: _statBox('紀錄', _game.record, const Color(0xffc991ff))),
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
        final outerBoardSize = math.min(side, 520).toDouble();
        const boardPadding = 10.0;
        final boardSize = math.max(0.0, outerBoardSize - boardPadding * 2);
        // Calculate cell size based on 4x4 grid with 10px spacing
        final totalSpacing = 10 * (gridSize - 1); // 30
        _cellSize = (boardSize - totalSpacing) / gridSize;
        _spacing = 10;

        // Build animated tile map from current game state
        final newAnimatedTiles = <int, _AnimatedTile>{};
        for (var i = 0; i < _game.grid.length; i++) {
          final tile = _game.grid[i];
          if (tile != null) {
            // Check if this tile was already being tracked (survived a move)
            final existing = _animatedTiles[tile.id];
            if (existing != null) {
              // Update tile data but keep tracking at new position
              newAnimatedTiles[tile.id] = _AnimatedTile(
                id: tile.id,
                tile: tile,
                targetIndex: i,
                currentIndex: existing.currentIndex,
                isNew: false,
              );
            } else {
              // New tile (just spawned)
              newAnimatedTiles[tile.id] = _AnimatedTile(
                id: tile.id,
                tile: tile,
                targetIndex: i,
                currentIndex: i,
                isNew: tile.justSpawned,
              );
            }
          }
        }
        _animatedTiles = newAnimatedTiles;

        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _shakeBorder
                        ? const Color(0xffff6f6f)
                        : Colors.white.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: SizedBox.square(
            dimension: boardSize,
            child: Stack(
              children: [
                // Background grid
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: gridSize * gridSize,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    return _buildEmptyCell(index);
                  },
                ),
                // Animated tiles layer
                ..._animatedTiles.values.map((animatedTile) {
                  final row = animatedTile.targetIndex ~/ gridSize;
                  final col = animatedTile.targetIndex % gridSize;

                  return AnimatedPositioned(
                    key: ValueKey(animatedTile.id),
                    duration:
                        Duration(milliseconds: animatedTile.isNew ? 300 : 200),
                    curve: animatedTile.isNew
                        ? Curves.easeOutBack
                        : Curves.easeOutCubic,
                    left: col * (_cellSize + _spacing),
                    top: row * (_cellSize + _spacing),
                    child: _TileCell(
                      tile: animatedTile.tile,
                      highlighted: _isHintEdge(animatedTile.targetIndex),
                      cellSize: _cellSize,
                    ),
                  );
                }),
                if (_game.gameOver || _game.won) _resultOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCell(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: _isHintEdge(index)
            ? const Color(0xffffb452).withOpacity(0.16)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: _isHintEdge(index)
            ? Border.all(color: const Color(0xffffb452).withOpacity(0.4))
            : null,
      ),
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
                  color: _game.won
                      ? const Color(0xffc991ff)
                      : const Color(0xffff6f6f),
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
            message ?? '滑動合成，長按提示，雙擊施法，點擊右上角寵物按鈕',
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

  Widget _shopPage() {
    return SingleChildScrollView(
      key: const ValueKey('shop'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            icon: Icons.storefront_rounded,
            title: 'Shop',
            subtitle: 'Buy food, boosters, and demo premium packs.',
          ),
          const SizedBox(height: 16),
          _coinPill(_game.coins),
          const SizedBox(height: 18),
          _sectionTitle('Coin shop'),
          _responsiveShopGrid([
            _ShopCard(
              emoji: '💡',
              name: 'Hint potion',
              price: 10,
              desc: 'Shows the best direction.',
              enabled: _game.coins >= 10,
              onTap: () => _buyShopItem(_ShopItem.hint),
            ),
            _ShopCard(
              emoji: '💎',
              name: 'Mana crystal',
              price: 15,
              desc: '+3 mana for skills.',
              enabled: _game.coins >= 15,
              onTap: () => _buyShopItem(_ShopItem.mana),
            ),
            _ShopCard(
              emoji: '🍖',
              name: 'Pet snack',
              price: 5,
              desc: 'Feed and cheer your pet.',
              enabled: _game.coins >= 5,
              onTap: () => _buyShopItem(_ShopItem.food),
            ),
            _ShopCard(
              emoji: '🛡',
              name: 'Stone shield',
              price: 20,
              desc: 'Blocks the next stone spawn.',
              enabled: _game.coins >= 20,
              onTap: () => _buyShopItem(_ShopItem.shield),
            ),
            _ShopCard(
              emoji: '🎲',
              name: 'Reroll',
              price: 25,
              desc: 'Turns one tile into level 1.',
              enabled: _game.coins >= 25,
              onTap: () => _buyShopItem(_ShopItem.reroll),
            ),
          ]),
          const SizedBox(height: 22),
          _sectionTitle('Premium demo'),
          _premiumCard(
            title: 'Starter coin pack',
            price: r'US$0.99',
            coins: 120,
            desc: 'Demo receipt, fake billing, real future-ready flow.',
          ),
          const SizedBox(height: 10),
          _premiumCard(
            title: 'Monthly supporter',
            price: r'US$2.99',
            coins: 500,
            desc: 'Looks like a subscription; currently local demo only.',
          ),
          const SizedBox(height: 10),
          _premiumCard(
            title: 'Ad-free founder badge',
            price: r'US$4.99',
            coins: 900,
            desc: 'Demo entitlement that can map to StoreKit/Billing later.',
          ),
        ],
      ),
    );
  }

  Widget _settingsPage() {
    return SingleChildScrollView(
      key: const ValueKey('settings'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pageHeader(
            icon: Icons.settings_rounded,
            title: 'Settings',
            subtitle: 'Audio, motion, demo billing, and save controls.',
          ),
          const SizedBox(height: 18),
          _settingsPanel(
            title: 'Audio',
            children: [
              _volumeRow(
                label: 'BGM',
                value: _bgmVolume,
                icon: Icons.music_note_rounded,
                onChanged: (value) {
                  setState(() => _bgmVolume = value);
                  _audio.setBgmVolume(value);
                },
              ),
              _volumeRow(
                label: 'SFX',
                value: _sfxVolume,
                icon: Icons.volume_up_rounded,
                onChanged: (value) {
                  setState(() => _sfxVolume = value);
                  _audio.setSfxVolume(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _settingsPanel(
            title: 'Gameplay demo',
            children: [
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text('Demo purchases enabled'),
                subtitle: const Text(
                    'Fake checkout now, real billing service later.'),
              ),
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: const Text('Reduce tile clipping'),
                subtitle: const Text(
                    'Board uses fixed padding and constrained cells.'),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('Show tutorial again'),
                onTap: () => setState(() => _showTutorial = true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _settingsPanel(
            title: 'Save',
            children: [
              ListTile(
                leading: const Icon(Icons.save_rounded),
                title: const Text('Save now'),
                subtitle:
                    const Text('Writes game and pet state to local storage.'),
                onTap: _save,
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt_rounded),
                title: const Text('Restart board'),
                subtitle: const Text('Keeps coins and pet progress.'),
                onTap: _restart,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xff6fe08b), size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coinPill(int coins) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xff6fe08b).withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xff6fe08b).withOpacity(0.28)),
        ),
        child: Text(
          'Coins $coins',
          style: const TextStyle(
            color: Color(0xff6fe08b),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.78),
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _responsiveShopGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 460
                ? 2
                : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 2.45 : 1.35,
          children: children,
        );
      },
    );
  }

  Widget _premiumCard({
    required String title,
    required String price,
    required int coins,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffffb452).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Color(0xffffb452)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.52),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () => _showDemoPurchase(title, price, coins),
            child: Text(price),
          ),
        ],
      ),
    );
  }

  Widget _settingsPanel({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _volumeRow({
    required String label,
    required double value,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Slider(
        value: value,
        onChanged: onChanged,
      ),
      trailing: Text('${(value * 100).round()}%'),
    );
  }

  Widget _petLayer() {
    final petColor = _pet.affinity.colorForLevel(_pet.stage);
    return Stack(
      children: [
        Column(
          key: const ValueKey('pet'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Pet',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff6fe08b),
                      ),
                    ),
                  ),
                  _iconAction(
                    Icons.grid_view_rounded,
                    () => _selectTab(_MainTab.game),
                  ),
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
                      _PetAnimationWidget(
                        key: _petAnimKey,
                        onEatTriggered: () {
                          _audio.playEat();
                        },
                        onHappyTriggered: () {
                          _audio.playWin();
                        },
                        onEvolveTriggered: () {
                          _audio.playLevelUp();
                        },
                        child: TweenAnimationBuilder<double>(
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
                      _petMeter(
                          '飽足', _pet.hunger / 100, const Color(0xffffb452)),
                      const SizedBox(height: 12),
                      _petMeter('心情', _pet.mood / 100, const Color(0xff65d6ff)),
                      const SizedBox(height: 12),
                      _petMeter('進化', _pet.evolutionProgress,
                          const Color(0xffc991ff)),
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
        ),
        if (_showPetTooltips) ...[
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Center(
              child: TooltipPopup(
                text: '飢餓度影響寵物心情',
                onDismiss: () {},
              ),
            ),
          ),
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: TooltipPopup(
                text: '心情影響融合經驗值',
                onDismiss: () {},
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: TooltipPopup(
                text: '進化需要累積經驗',
                onDismiss: () => setState(() => _showPetTooltips = false),
              ),
            ),
          ),
        ],
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

class _PetAnimationWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onEatTriggered;
  final VoidCallback? onHappyTriggered;
  final VoidCallback? onEvolveTriggered;

  const _PetAnimationWidget({
    super.key,
    required this.child,
    this.onEatTriggered,
    this.onHappyTriggered,
    this.onEvolveTriggered,
  });

  @override
  State<_PetAnimationWidget> createState() => _PetAnimationWidgetState();
}

class _PetAnimationWidgetState extends State<_PetAnimationWidget>
    with TickerProviderStateMixin {
  // Idle breathing
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  // Eating bounce
  late AnimationController _eatController;
  late Animation<double> _eatScaleAnimation;

  // Happy wiggle
  late AnimationController _happyController;
  late Animation<double> _happyRotationAnimation;
  late Animation<double> _happyScaleAnimation;

  // Evolution glow
  late AnimationController _evolveController;
  late Animation<double> _evolveScaleAnimation;
  late Animation<double> _evolveGlowAnimation;

  // Floating particles for eat animation
  final List<_FloatingParticle> _particles = [];
  int _particleIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _initBreathAnimation();
    _initEatAnimation();
    _initHappyAnimation();
    _initEvolveAnimation();
  }

  void _initBreathAnimation() {
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _breathController.repeat(reverse: true);
  }

  void _initEatAnimation() {
    _eatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _eatScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _eatController, curve: Curves.easeInOut));
    _eatController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _particles.clear());
      }
    });
  }

  void _initHappyAnimation() {
    _happyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _happyRotationAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _happyController, curve: Curves.easeInOut));
    _happyScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _happyController, curve: Curves.easeInOut));
  }

  void _initEvolveAnimation() {
    _evolveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _evolveScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _evolveController, curve: Curves.easeOutBack));
    _evolveGlowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _evolveController, curve: Curves.easeInOut));
  }

  void triggerEatAnimation() {
    _eatController.forward(from: 0);
    // Spawn floating particles
    setState(() {
      _particles.clear();
      for (int i = 0; i < 5; i++) {
        _particles.add(_FloatingParticle(
          id: _particleIdCounter++,
          angle: -0.5 + i * 0.25,
          delay: i * 0.05,
        ));
      }
    });
    widget.onEatTriggered?.call();
  }

  void triggerHappyAnimation() {
    _happyController.forward(from: 0);
    widget.onHappyTriggered?.call();
  }

  void triggerEvolveAnimation() {
    _evolveController.forward(from: 0);
    widget.onEvolveTriggered?.call();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _eatController.dispose();
    _happyController.dispose();
    _evolveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathController,
        _eatController,
        _happyController,
        _evolveController,
      ]),
      builder: (context, child) {
        // Determine which animation is active (priority: evolve > eat > happy > breath)
        double scale = _breathAnimation.value;
        double rotation = 0;
        double glowOpacity = 0;

        if (_evolveController.isAnimating) {
          scale = _evolveScaleAnimation.value;
          glowOpacity = _evolveGlowAnimation.value;
        } else if (_eatController.isAnimating) {
          scale = _eatScaleAnimation.value;
        } else if (_happyController.isAnimating) {
          scale = _happyScaleAnimation.value;
          rotation = _happyRotationAnimation.value;
        }

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                widget.child,
                // Floating particles during eat
                for (final particle in _particles)
                  _FloatingParticleWidget(
                    particle: particle,
                    eatProgress: _eatController.value,
                    eatDelay: particle.delay,
                  ),
                // Glow overlay for evolution
                if (_evolveController.isAnimating)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(glowOpacity),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FloatingParticle {
  final int id;
  final double angle;
  final double delay;

  _FloatingParticle({
    required this.id,
    required this.angle,
    required this.delay,
  });
}

class _FloatingParticleWidget extends StatelessWidget {
  final _FloatingParticle particle;
  final double eatProgress;
  final double eatDelay;

  const _FloatingParticleWidget({
    required this.particle,
    required this.eatProgress,
    required this.eatDelay,
  });

  @override
  Widget build(BuildContext context) {
    final adjustedProgress = (eatProgress - particle.delay).clamp(0.0, 1.0);
    if (adjustedProgress <= 0) return const SizedBox();

    final double yOffset = -80 * Curves.easeOut.transform(adjustedProgress);
    final double xOffset =
        30 * particle.angle * Curves.easeInOut.transform(adjustedProgress);
    final double opacity = (1 - adjustedProgress).clamp(0.0, 1.0);

    return Positioned(
      left: 90 + xOffset,
      top: 90 + yOffset,
      child: Opacity(
        opacity: opacity,
        child: const Text(
          '💕',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class _AnimatedTile {
  final int id;
  final Tile tile;
  final int targetIndex; // Final grid position
  int currentIndex; // Animated current position
  bool isNew; // True if this is a freshly spawned tile

  _AnimatedTile({
    required this.id,
    required this.tile,
    required this.targetIndex,
    required this.currentIndex,
    this.isNew = false,
  });
}

class _TileCell extends StatelessWidget {
  const _TileCell({
    required this.tile,
    required this.highlighted,
    required this.cellSize,
  });

  final Tile? tile;
  final bool highlighted;
  final double cellSize;

  @override
  Widget build(BuildContext context) {
    final tile = this.tile;
    if (tile == null) {
      return const SizedBox();
    }

    final color = tile.type.colorForLevel(tile.level);
    final textColor =
        tile.type == ElementType.steam ? const Color(0xff20242d) : Colors.white;

    Widget tileWidget = AnimatedOpacity(
      opacity: tile.justSpawned || tile.justMerged ? 0.74 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: tile.justSpawned ? 0.0 : (tile.justMerged ? 0.8 : 1.0),
          end: tile.justMerged ? 1.05 : 1.0,
        ),
        duration: Duration(milliseconds: tile.justSpawned ? 300 : 180),
        curve: tile.justSpawned ? Curves.easeOutBack : Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
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
                  : Colors.white.withOpacity(
                      tile.type == ElementType.stone ? 0.18 : 0.08),
              width: highlighted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(tile.justMerged ? 0.8 : 0.34),
                blurRadius: tile.justMerged
                    ? 24
                    : (tile.type == ElementType.sage ? 22 : 12),
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

    return SizedBox(
      width: cellSize,
      height: cellSize,
      child: tileWidget,
    );
  }
}

enum _ShopItem { hint, mana, food, shield, reroll }

// ignore: unused_element
class _ShopSheet extends StatelessWidget {
  const _ShopSheet({required this.coins, required this.onBuy});

  final int coins;
  final void Function(_ShopItem) onBuy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '商店',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xff6fe08b).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xff6fe08b).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color: Color(0xff6fe08b),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _ShopCard(
                emoji: '💡',
                name: '提示藥水',
                price: 10,
                desc: '顯示建議方向 5 秒',
                enabled: coins >= 10,
                onTap: () => onBuy(_ShopItem.hint),
              ),
              _ShopCard(
                emoji: '💎',
                name: '法術水晶',
                price: 15,
                desc: '法術池 +3 法力',
                enabled: coins >= 15,
                onTap: () => onBuy(_ShopItem.mana),
              ),
              _ShopCard(
                emoji: '🍖',
                name: '寵物飼料',
                price: 5,
                desc: '餵食寵物',
                enabled: coins >= 5,
                onTap: () => onBuy(_ShopItem.food),
              ),
              _ShopCard(
                emoji: '🛡️',
                name: '護盾',
                price: 20,
                desc: '擋住下次石頭生成',
                enabled: coins >= 20,
                onTap: () => onBuy(_ShopItem.shield),
              ),
              _ShopCard(
                emoji: '🎲',
                name: '重骰',
                price: 25,
                desc: '隨機元素變 Lv1',
                enabled: coins >= 25,
                onTap: () => onBuy(_ShopItem.reroll),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.emoji,
    required this.name,
    required this.price,
    required this.desc,
    required this.onTap,
    required this.enabled,
  });

  final String emoji;
  final String name;
  final int price;
  final String desc;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withOpacity(0.07)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? Colors.white.withOpacity(0.12)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(enabled ? 0.92 : 0.45),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(enabled ? 0.5 : 0.3),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text('🪙',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5))),
                      const SizedBox(width: 2),
                      Text(
                        '$price',
                        style: TextStyle(
                          color: enabled
                              ? const Color(0xff6fe08b)
                              : Colors.white.withOpacity(0.3),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!enabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '金幣不足',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DemoPurchaseSheet extends StatefulWidget {
  const _DemoPurchaseSheet({
    required this.title,
    required this.price,
    required this.onConfirm,
  });

  final String title;
  final String price;
  final VoidCallback onConfirm;

  @override
  State<_DemoPurchaseSheet> createState() => _DemoPurchaseSheetState();
}

class _DemoPurchaseSheetState extends State<_DemoPurchaseSheet> {
  var _processing = false;

  Future<void> _confirm() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.lock_rounded,
                  color: Color(0xff6fe08b),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Demo checkout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      _processing ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xffffb452),
                    size: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sandbox receipt • no real charge',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.52),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    widget.price,
                    style: const TextStyle(
                      color: Color(0xff6fe08b),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This is wired like a real purchase flow: product, loading state, receipt success, and restore-ready entitlement. It does not contact Apple, Google, Stripe, or any payment network yet.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.58),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _processing ? null : _confirm,
              icon: _processing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_rounded),
              label:
                  Text(_processing ? 'Processing...' : 'Confirm demo purchase'),
            ),
          ],
        ),
      ),
    );
  }
}
