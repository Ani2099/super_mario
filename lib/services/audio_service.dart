import 'package:flame_audio/flame_audio.dart';

abstract class AudioService {
  Future<void> init();
  Future<void> playBgm(String filename);
  Future<void> stopBgm();
  Future<void> playSfx(String filename);
  void setMusicVolume(double volume);
  void setSfxVolume(double volume);
  void toggleMute();
  bool get isMuted;
  double get musicVolume;
  double get sfxVolume;
}

class FlameAudioService implements AudioService {
  double _musicVolume = 0.5;
  double _sfxVolume = 0.7;
  bool _isMuted = false;
  String? _currentBgm;

  @override
  Future<void> init() async {
    // Preload audio cache or configure BGM pool
    FlameAudio.bgm.initialize();
  }

  @override
  Future<void> playBgm(String filename) async {
    if (_isMuted) return;
    try {
      _currentBgm = filename;
      await FlameAudio.bgm.play(filename, volume: _musicVolume);
    } catch (e) {
      // Handle errors during audio playback gracefully (e.g., on web or test environments)
      print('AudioService Error: Failed to play BGM $filename: $e');
    }
  }

  @override
  Future<void> stopBgm() async {
    try {
      await FlameAudio.bgm.stop();
      _currentBgm = null;
    } catch (e) {
      print('AudioService Error: Failed to stop BGM: $e');
    }
  }

  @override
  Future<void> playSfx(String filename) async {
    if (_isMuted) return;
    try {
      await FlameAudio.play(filename, volume: _sfxVolume);
    } catch (e) {
      print('AudioService Error: Failed to play SFX $filename: $e');
    }
  }

  @override
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    if (!_isMuted && _currentBgm != null) {
      FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
    }
  }

  @override
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  @override
  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      FlameAudio.bgm.pause();
    } else {
      FlameAudio.bgm.resume();
      if (_currentBgm != null) {
        FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
      }
    }
  }

  @override
  bool get isMuted => _isMuted;

  @override
  double get musicVolume => _musicVolume;

  @override
  double get sfxVolume => _sfxVolume;
}
