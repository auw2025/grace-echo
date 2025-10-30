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

  // State variable for high contrast mode.
  bool _isHighContrast = false;

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

  void _toggleHighContrast(bool value) {
    setState(() {
      _isHighContrast = value;
    });
  }

  /// Show accessibility options (font size + high-contrast toggle).
  void _showAccessibilityOptionsSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Font size adjustment row with a label.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Label for font size.
                        Text(
                          "字體大小",
                          style: TextStyle(fontSize: _fontSize),
                        ),
                        // Font size adjustment buttons.
                        Row(
                          children: [
                            IconButton(
                              iconSize: 32,
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                _decreaseFontSize();
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
                                setModalState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // High contrast mode toggle row.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "高對比度",
                          style: TextStyle(fontSize: _fontSize),
                        ),
                        Switch(
                          value: _isHighContrast,
                          onChanged: (value) {
                            _toggleHighContrast(value);
                            setModalState(() {});
                          },
                        ),
                      ],
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

  // Returns a TextStyle based on the current state.
  TextStyle _getTextStyle() {
    return TextStyle(
      fontSize: _fontSize,
      color: _isHighContrast ? Colors.white : Colors.black87,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Adjust the background color for a more visible high contrast effect.
    final Color contentBackgroundColor =
        _isHighContrast ? Colors.black : Theme.of(context).scaffoldBackgroundColor;

    // A different app bar styling for high contrast.
    final AppBar appBar = AppBar(
      backgroundColor: _isHighContrast ? Colors.black : null,
      title: Text(
        '${widget.passage.category}: ${widget.passage.title}',
        style: TextStyle(
          color: _isHighContrast ? Colors.white : Colors.white,
        ),
      ),
      iconTheme: IconThemeData(
        color: _isHighContrast ? Colors.white : Colors.white,
      ),
    );

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
                style: _getTextStyle(),
              ),
            ),
          );
        }
      }

      // Build the list of verse rows.
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
                    style: _getTextStyle().copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                // Vertical divider line.
                Container(
                  width: 1,
                  height: 50,
                  color: _isHighContrast ? Colors.white : Colors.grey,
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                // Right part: verse text.
                Expanded(
                  child: Text(
                    verseText,
                    style: _getTextStyle(),
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
            style: _getTextStyle(),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: appBar,
      backgroundColor: contentBackgroundColor,
      body: Container(
        color: contentBackgroundColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: contentWidgets,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAccessibilityOptionsSheet,
        backgroundColor: _isHighContrast ? Colors.black : null,
        child: Icon(
          Icons.accessibility,
          color: _isHighContrast ? Colors.white : Colors.blueAccent,
        ),
      ),
      bottomNavigationBar: widget.passage.audioUrl.isNotEmpty
          ? Container(
              color: _isHighContrast ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 32,
                    icon: Icon(Icons.replay_10,
                        color: _isHighContrast ? Colors.white : Colors.black87),
                    onPressed: _rewind,
                  ),
                  IconButton(
                    iconSize: 48,
                    icon: Icon(isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                        color: _isHighContrast ? Colors.white : Colors.black87),
                    onPressed: _playPauseAudio,
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: Icon(Icons.forward_10,
                        color: _isHighContrast ? Colors.white : Colors.black87),
                    onPressed: _fastForward,
                  ),
                  IconButton(
                    iconSize: 32,
                    icon: Icon(Icons.stop,
                        color: _isHighContrast ? Colors.white : Colors.black87),
                    onPressed: _stopAudio,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}