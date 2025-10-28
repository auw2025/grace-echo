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
    if (widget.passage.audioUrl.isNotEmpty) {
      _player.onDurationChanged.listen((duration) {
        setState(() {
          totalDuration = duration;
        });
      });
      _player.onPositionChanged.listen((position) {
        setState(() {
          currentPosition = position;
        });
      });
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
    // This regular expression finds patterns like "1:2" followed by some text.
    final verseRegExp = RegExp(r'(\d+:\d+)\s+(.*?)(?=(\d+:\d+)|$)', dotAll: true);
    final matches = verseRegExp.allMatches(widget.passage.content).toList();

    List<Widget> contentWidgets = [];

    if (matches.isNotEmpty) {
      // Find the position where the first verse marker occurs.
      final firstMatchText = matches.first.group(0);
      int firstMatchIndex = widget.passage.content.indexOf(firstMatchText!);

      // If there is text before the first verse marker, add it as a plain paragraph.
      if (firstMatchIndex > 0) {
        String headerText = widget.passage.content.substring(0, firstMatchIndex).trim();
        if (headerText.isNotEmpty) {
          contentWidgets.add(
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                headerText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }
      }

      // Build the list of verses rows.
      List<Widget> verseWidgets = [];
      for (var match in matches) {
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
                // Vertical divider line.
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
      // Wrap all verses in a column.
      contentWidgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: verseWidgets,
          ),
        ),
      );
    } else {
      // If no verse markers are detected, simply show the whole passage.
      contentWidgets.add(
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.passage.content,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.passage.category}: ${widget.passage.title}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: contentWidgets,
        ),
      ),
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