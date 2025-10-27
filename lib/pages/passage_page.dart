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
    // Only set up audio listeners if audioUrl is provided
    if (widget.passage.audioUrl.isNotEmpty) {
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
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playPauseAudio() async {
    if (widget.passage.audioUrl.isEmpty) return;
    
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
    if (widget.passage.audioUrl.isEmpty) return;
    
    await _player.stop();
    setState(() {
      isPlaying = false;
      currentPosition = Duration.zero;
    });
  }

  Future<void> _rewind() async {
    if (widget.passage.audioUrl.isEmpty) return;
    
    Duration newPosition = currentPosition - const Duration(seconds: 10);
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    }
    await _player.seek(newPosition);
  }

  Future<void> _fastForward() async {
    if (widget.passage.audioUrl.isEmpty) return;
    
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
      // Body contains the text content scrollable
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          widget.passage.content,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      // Fixed audio control buttons at the bottom, only shown if audioUrl is provided
      bottomNavigationBar: widget.passage.audioUrl.isNotEmpty
          ? Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
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
            )
          : null,
    );
  }
}