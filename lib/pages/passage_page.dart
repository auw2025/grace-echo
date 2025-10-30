import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // State variable for font size adjustment.
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadFontSize(); // Load the saved font size.
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

  /// Loads the saved font size from shared preferences.
  Future<void> _loadFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('passageFontSize') ?? 16.0;
    });
  }

  /// Saves the current font size to shared preferences.
  Future<void> _saveFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('passageFontSize', _fontSize);
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize += 2;
    });
    _saveFontSize();
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = _fontSize > 10 ? _fontSize - 2 : _fontSize;
    });
    _saveFontSize();
  }

  void _showFontSizeAdjustmentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        _decreaseFontSize();
                        // Rebuild bottom sheet's UI immediately:
                        setModalState(() {});
                      },
                    ),
                    Text(
                      '${_fontSize.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: _fontSize),
                    ),
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        _increaseFontSize();
                        // Rebuild bottom sheet's UI immediately:
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This regular expression finds patterns like "1:2" followed by some text.
    final verseRegExp =
        RegExp(r'(\d+:\d+)\s+(.*?)(?=(\d+:\d+)|$)', dotAll: true);
    final matches = verseRegExp.allMatches(widget.passage.content).toList();

    List<Widget> contentWidgets = [];

    if (matches.isNotEmpty) {
      // Find the position where the first verse marker occurs.
      final firstMatchText = matches.first.group(0);
      int firstMatchIndex = widget.passage.content.indexOf(firstMatchText!);

      // If there is text before the first verse marker, add it as a plain paragraph.
      if (firstMatchIndex > 0) {
        String headerText =
            widget.passage.content.substring(0, firstMatchIndex).trim();
        if (headerText.isNotEmpty) {
          contentWidgets.add(
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                headerText,
                style: TextStyle(fontSize: _fontSize),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _fontSize,
                    ),
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
                    style: TextStyle(fontSize: _fontSize),
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
            style: TextStyle(fontSize: _fontSize),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            Text('${widget.passage.category}: ${widget.passage.title}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: contentWidgets,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFontSizeAdjustmentSheet,
        child: const Icon(Icons.format_size),
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