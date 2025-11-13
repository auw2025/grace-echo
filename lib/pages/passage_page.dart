import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/passage_model.dart';
import '../providers/settings_provider.dart';

class PassagePage extends StatefulWidget {
  final Passage passage;

  const PassagePage({Key? key, required this.passage}) : super(key: key);

  @override
  State<PassagePage> createState() => _PassagePageState();
}

class _PassagePageState extends State<PassagePage> {
  /* -------------------------------------------------------------------------
   *  Audio
   * ---------------------------------------------------------------------- */
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  /* -------------------------------------------------------------------------
   *  Accessibility
   * ---------------------------------------------------------------------- */
  double _fontSize = 16.0;

  /* -------------------------------------------------------------------------
   *  Sub-page navigation
   * ---------------------------------------------------------------------- */
  int _currentIndex = 0;

  String get _activeAudioUrl {
    if (widget.passage.hasSubPages) {
      return widget.passage.subPages[_currentIndex].audioUrl;
    }
    return widget.passage.audioUrl;
  }

  /* -------------------------------------------------------------------------
   *  Lifecycle
   * ---------------------------------------------------------------------- */
  @override
  void initState() {
    super.initState();
    _loadFontSize();
    _attachAudioListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _attachAudioListeners() {
    _player.onDurationChanged.listen((d) {
      setState(() => totalDuration = d);
    });
    _player.onPositionChanged.listen((p) {
      setState(() => currentPosition = p);
    });
    _player.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
        currentPosition = Duration.zero;
      });
    });
  }

  /* -------------------------------------------------------------------------
   *  Audio controls
   * ---------------------------------------------------------------------- */
  Future<void> _playPauseAudio() async {
    if (_activeAudioUrl.isEmpty) return;

    if (!isPlaying) {
      await _player.play(UrlSource(_activeAudioUrl));
      setState(() => isPlaying = true);
    } else {
      await _player.pause();
      setState(() => isPlaying = false);
    }
  }

  Future<void> _stopAudio() async {
    if (_activeAudioUrl.isEmpty) return;
    await _player.stop();
    setState(() {
      isPlaying = false;
      currentPosition = Duration.zero;
    });
  }

  Future<void> _rewind() async {
    if (_activeAudioUrl.isEmpty) return;
    Duration newPos = currentPosition - const Duration(seconds: 10);
    if (newPos < Duration.zero) newPos = Duration.zero;
    await _player.seek(newPos);
  }

  Future<void> _fastForward() async {
    if (_activeAudioUrl.isEmpty) return;
    Duration newPos = currentPosition + const Duration(seconds: 10);
    if (newPos > totalDuration) newPos = totalDuration;
    await _player.seek(newPos);
  }

  /* -------------------------------------------------------------------------
   *  Sub-page navigation
   * ---------------------------------------------------------------------- */
  void _goToPage(int nextIndex) {
    if (!widget.passage.hasSubPages) return;
    _player.stop();
    setState(() {
      isPlaying = false;
      currentPosition = Duration.zero;
      _currentIndex = nextIndex;
    });
  }

  /* -------------------------------------------------------------------------
   *  Font-size persistence
   * ---------------------------------------------------------------------- */
  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _fontSize = prefs.getDouble('passageFontSize') ?? 16.0);
  }

  Future<void> _saveFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('passageFontSize', _fontSize);
  }

  void _increaseFontSize() {
    setState(() => _fontSize += 2);
    _saveFontSize();
  }

  void _decreaseFontSize() {
    setState(() => _fontSize = _fontSize > 10 ? _fontSize - 2 : _fontSize);
    _saveFontSize();
  }

  /* -------------------------------------------------------------------------
   *  Accessibility bottom-sheet
   * ---------------------------------------------------------------------- */
  void _showAccessibilityOptionsSheet() {
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Font size
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("字體大小", style: TextStyle(fontSize: _fontSize)),
                  Row(children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      iconSize: 32,
                      onPressed: () {
                        _decreaseFontSize();
                        setModalState(() {});
                      },
                    ),
                    Text('${_fontSize.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: _fontSize)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      iconSize: 32,
                      onPressed: () {
                        _increaseFontSize();
                        setModalState(() {});
                      },
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              // High contrast
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("高對比模式", style: TextStyle(fontSize: _fontSize)),
                  Consumer<SettingsProvider>(
                    builder: (_, settings, __) => Switch(
                      value: settings.isHighContrast,
                      onChanged: (v) {
                        settingsProvider.toggleHighContrast(v);
                        setModalState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /* -------------------------------------------------------------------------
   *  Helpers
   * ---------------------------------------------------------------------- */
  TextStyle _getTextStyle(bool highContrast) => TextStyle(
        fontSize: _fontSize,
        color: highContrast ? Colors.white : Colors.black87,
      );

  List<Widget> _parseContent(String content, bool highContrast) {
    final verseRegExp =
        RegExp(r'(\d+:\d+)\s+(.*?)(?=(\d+:\d+)|$)', dotAll: true);
    final matches = verseRegExp.allMatches(content).toList();

    List<Widget> widgets = [];

    if (matches.isNotEmpty) {
      final firstMatchText = matches.first.group(0)!;
      final firstMatchIndex = content.indexOf(firstMatchText);

      if (firstMatchIndex > 0) {
        final headerText = content.substring(0, firstMatchIndex).trim();
        if (headerText.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(headerText, style: _getTextStyle(highContrast)),
            ),
          );
        }
      }

      List<Widget> verseWidgets = [];
      for (final m in matches) {
        final verseNumber = m.group(1) ?? '';
        final verseText = m.group(2) ?? '';
        verseWidgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Text(verseNumber,
                    style: _getTextStyle(highContrast)
                        .copyWith(fontWeight: FontWeight.bold)),
              ),
              Container(
                width: 1,
                height: 50,
                color: highContrast ? Colors.white : Colors.grey,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child:
                    Text(verseText, style: _getTextStyle(highContrast)),
              ),
            ],
          ),
        ));
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: verseWidgets),
        ),
      );
    } else {
      widgets.add(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(content, style: _getTextStyle(highContrast)),
        ),
      );
    }

    return widgets;
  }

  /* -------------------------------------------------------------------------
   *  Body builders
   * ---------------------------------------------------------------------- */
  Widget _buildSinglePageBody(bool highContrast) {
    final widgets =
        _parseContent(widget.passage.content, highContrast);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widgets,
      ),
    );
  }

  Widget _buildSubPageBody(bool highContrast) {
    final subPage = widget.passage.subPages[_currentIndex];

    final widgets = _parseContent(subPage.content, highContrast);

    final optionButtons = [
      for (final opt in subPage.options)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ElevatedButton(
            onPressed: () => _goToPage(opt.nextIndex),
            child: Text(opt.label, style: _getTextStyle(highContrast)),
          ),
        )
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widgets,
          if (optionButtons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: optionButtons),
            ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------
   *  Scaffold fragments
   * ---------------------------------------------------------------------- */
  AppBar _buildAppBar(bool highContrast) => AppBar(
        backgroundColor: highContrast ? Colors.black : null,
        iconTheme: IconThemeData(
            color: highContrast ? Colors.white : Colors.black87),
        title: Text(
          '${widget.passage.category}: ${widget.passage.title}',
          style:
              TextStyle(color: highContrast ? Colors.white : Colors.black87),
        ),
      );

  FloatingActionButton _buildFab(bool highContrast) =>
      FloatingActionButton(
        onPressed: _showAccessibilityOptionsSheet,
        backgroundColor: highContrast ? Colors.black : null,
        child: Icon(Icons.accessibility,
            color: highContrast ? Colors.white : Colors.blueAccent),
      );

  Widget? _buildAudioBar(bool highContrast) {
    if (_activeAudioUrl.isEmpty) return null;

    final iconColor = highContrast ? Colors.white : Colors.black87;
    final bgColor = highContrast
        ? Colors.black
        : Theme.of(context).scaffoldBackgroundColor;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            iconSize: 32,
            icon: Icon(Icons.replay_10, color: iconColor),
            onPressed: _rewind,
          ),
          IconButton(
            iconSize: 48,
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: iconColor,
            ),
            onPressed: _playPauseAudio,
          ),
          IconButton(
            iconSize: 32,
            icon: Icon(Icons.forward_10, color: iconColor),
            onPressed: _fastForward,
          ),
          IconButton(
            iconSize: 32,
            icon: Icon(Icons.stop, color: iconColor),
            onPressed: _stopAudio,
          ),
        ],
      ),
    );
  }

  /* -------------------------------------------------------------------------
   *  Build
   * ---------------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final highContrast = settings.isHighContrast;
    final bgColor = highContrast
        ? Colors.black
        : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: _buildAppBar(highContrast),
      backgroundColor: bgColor,
      body: widget.passage.hasSubPages
          ? _buildSubPageBody(highContrast)
          : _buildSinglePageBody(highContrast),
      floatingActionButton: _buildFab(highContrast),
      bottomNavigationBar: _buildAudioBar(highContrast),
    );
  }
}