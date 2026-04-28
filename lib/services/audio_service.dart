import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final _sfxPlayer = AudioPlayer();
  final _bgmPlayer = AudioPlayer();

  // SFX for game events
  Future<void> playMerge() async {
    await _sfxPlayer.play(AssetSource('sfx/merge.mp3'));
  }

  Future<void> playSpawn() async {
    await _sfxPlayer.play(AssetSource('sfx/spawn.mp3'));
  }

  Future<void> playMove() async {
    await _sfxPlayer.play(AssetSource('sfx/move.mp3'));
  }

  Future<void> playGameOver() async {
    await _sfxPlayer.play(AssetSource('sfx/gameover.mp3'));
  }

  Future<void> playWin() async {
    await _sfxPlayer.play(AssetSource('sfx/win.mp3'));
  }

  // BGM
  Future<void> playBgm() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.play(AssetSource('bgm/background.mp3'));
  }

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  Future<void> setBgmVolume(double volume) async {
    await _bgmPlayer.setVolume(volume); // 0.0 to 1.0
  }

  void dispose() {
    _sfxPlayer.dispose();
    _bgmPlayer.dispose();
  }
}