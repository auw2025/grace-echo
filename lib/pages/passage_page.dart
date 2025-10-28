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
    // Try to detect verse markers (i.e., something like "18:9") within the text.
    final verseRegExp = RegExp(r'(\d+:\d+)\s+(.*?)(?=(\d+:\d+)|$)', dotAll: true);
    final matches = verseRegExp.allMatches(widget.passage.content).toList();

    Widget contentWidget;

    // Only use the two-column layout if at least one verse marker is found.
    if (matches.isNotEmpty) {
      // Build the list of verses rows.
      List<Widget> verseWidgets = [];
      for (var match in matches) {
        // Group 1 is the verse number, group 2 is the verse text.
        var verseNumber = match.group(1)?.trim() ?? "";
        var verseText = match.group(2)?.trim() ?? "";
        verseWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left part: verse number with a fixed width.
                Container(
                  width: 60,
                  child: Text(
                    verseNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                // Vertical divider line
                Container(
                  width: 1,
                  height: 50,
                  color: Colors.grey,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                // Right part: verse text.
                Expanded(
                  child: Text(
                    verseText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      contentWidget = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: verseWidgets,
        ),
      );
    } else {
      // Default display without splitting into columns.
      contentWidget = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          widget.passage.content,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.passage.title),
      ),
      body: SingleChildScrollView(
        child: contentWidget,
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