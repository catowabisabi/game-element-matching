import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final _sfxPlayer = AudioPlayer();
  final _bgmPlayer = AudioPlayer();
  var _bgmStarted = false;
  var _audioAvailable = true;
  double _bgmVolume = 0.22;
  double _sfxVolume = 0.72;

  double get bgmVolume => _bgmVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> _playSfx(String file) async {
    if (!_audioAvailable || _sfxVolume <= 0) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource('sfx/$file'));
    } catch (_) {
      _audioAvailable = false;
    }
  }

  Future<void> playMerge() => _playSfx('merge.ogg');

  Future<void> playSpawn() => _playSfx('spawn.ogg');

  Future<void> playMove() => _playSfx('move.ogg');

  Future<void> playGameOver() => _playSfx('gameover.ogg');

  Future<void> playWin() => _playSfx('win.ogg');

  Future<void> playShop() => _playSfx('shop.ogg');

  Future<void> playEat() => _playSfx('feed.ogg');

  Future<void> playLevelUp() => _playSfx('win.ogg');

  Future<void> playBgm() async {
    if (_bgmStarted || !_audioAvailable || _bgmVolume <= 0) return;
    try {
      _bgmStarted = true;
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer.setVolume(_bgmVolume);
      await _bgmPlayer.play(AssetSource('bgm/background.mp3'));
    } catch (_) {
      _bgmStarted = false;
      _audioAvailable = false;
    }
  }

  Future<void> stopBgm() async {
    _bgmStarted = false;
    await _bgmPlayer.stop();
  }

  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume.clamp(0, 1).toDouble();
    await _bgmPlayer.setVolume(_bgmVolume);
    if (_bgmVolume == 0) {
      await stopBgm();
    } else {
      await playBgm();
    }
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0, 1).toDouble();
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  void dispose() {
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
