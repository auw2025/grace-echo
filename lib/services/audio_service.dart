import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAudio(String url) async {
    await _player.play(UrlSource(url));
  }

  Future<void> stopAudio() async {
    await _player.stop();
  }

  Future<void> pauseAudio() async {
    await _player.pause();
  }

  // Additional controls: resume, seek, etc.
  Future<void> resumeAudio() async {
    await _player.resume();
  }
}