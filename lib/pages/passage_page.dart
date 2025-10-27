import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/passage_model.dart';

class PassagePage extends StatefulWidget {
  final Passage passage;

  const PassagePage({Key? key, required this.passage}) : super(key: key);

  @override
  State<PassagePage> createState() => _PassagePageState();
}

class _PassagePageState extends State<PassagePage> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Listen for audio duration changes
    _player.onDurationChanged.listen((duration) {
      setState(() {
        totalDuration = duration;
      });
    });
    // Listen for position changes
    _player.onPositionChanged.listen((position) {
      setState(() {
        currentPosition = position;
      });
    });
    // Optionally, handle audio completion
    _player.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        currentPosition = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    // Always dispose the player when not needed
    _player.dispose();
    super.dispose();
  }

  Future<void> _playPauseAudio() async {
    if (!isPlaying) {
      await _player.play(UrlSource(widget.passage.audioUrl));
      setState(() {
        isPlaying = true;
      });
    } else {
      await _player.pause();
      setState(() {
        isPlaying = false;
      });
    }
  }

  Future<void> _stopAudio() async {
    await _player.stop();
    setState(() {
      isPlaying = false;
      currentPosition = Duration.zero;
    });
  }

  Future<void> _rewind() async {
    Duration newPosition = currentPosition - const Duration(seconds: 10);
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    }
    await _player.seek(newPosition);
  }

  Future<void> _fastForward() async {
    Duration newPosition = currentPosition + const Duration(seconds: 10);
    if (newPosition > totalDuration) {
      newPosition = totalDuration;
    }
    await _player.seek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.passage.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.passage.content,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              // Audio control buttons (icon-only)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.replay_10),
                    onPressed: _rewind,
                  ),
                  IconButton(
                    iconSize: 48,
                    icon: Icon(isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled),
                    onPressed: _playPauseAudio,
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.forward_10),
                    onPressed: _fastForward,
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.stop),
                    onPressed: _stopAudio,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}