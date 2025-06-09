import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _clickPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isInitialized = false;
  bool get isPlaying => false;  // Always return false since music is disabled

  Future<void> initBackgroundMusic() async {
    // Background music disabled
    return;
  }

  Future<void> _initializeAudioLater() async {
    // Background music disabled
    return;
  }

  Future<void> toggleBackgroundMusic() async {
    // Background music disabled
    return;
  }

  Future<void> playClickSound() async {
    // Click sounds still enabled
    if (!_isInitialized) return;
    try {
      await _clickPlayer.seek(Duration.zero);
      await _clickPlayer.resume();
    } catch (e) {
      print('DEBUG: Click sound error: $e');
    }
  }
}