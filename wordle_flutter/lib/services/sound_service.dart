import 'package:audioplayers/audioplayers.dart';

/// Short feedback clips loaded from bundled `.mp3` assets.
class SoundService {
  SoundService() : _player = AudioPlayer();

  final AudioPlayer _player;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await _player.setReleaseMode(ReleaseMode.stop);
    _ready = true;
  }

  Future<void> playCorrect() => _play('sounds/correct.mp3');

  Future<void> playWrong() => _play('sounds/wrong.mp3');

  Future<void> playWin() => _play('sounds/win.mp3');

  Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // Missing asset or platform audio failure — ignore.
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
