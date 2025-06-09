import 'package:kreisel_frontend/services/audio_service.dart';

Future<void> withClickSound(Function callback) async {
  try {
    await AudioService().playClickSound();
    callback();
  } catch (e) {
    print('DEBUG: Error playing click sound: $e');
    // Still execute callback even if sound fails
    callback();
  }
}