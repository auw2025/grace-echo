import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:grace_echo/services/firebase_service.dart';

class RecordAudioPage extends StatefulWidget {
  const RecordAudioPage({Key? key}) : super(key: key);

  @override
  State<RecordAudioPage> createState() => _RecordAudioPageState();
}

class _RecordAudioPageState extends State<RecordAudioPage> {
  final _firebaseService = FirebaseService();
  final recorder = FlutterSoundRecorder();

  bool isRecording = false;
  String? recordedFilePath;

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  Future<void> initRecorder() async {
    // Request microphone permissions, etc. if needed
    await recorder.openRecorder();
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      final tmpDir = await getTemporaryDirectory();
      final path = '${tmpDir.path}/temp_audio.aac';
      await recorder.startRecorder(toFile: path);
      setState(() => isRecording = true);
    } catch (e) {
      debugPrint('Error starting recorder: $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      final filePath = await recorder.stopRecorder();
      setState(() {
        isRecording = false;
        recordedFilePath = filePath;
      });
    } catch (e) {
      debugPrint('Error stopping recorder: $e');
    }
  }

  Future<void> uploadAndSavePassage() async {
    if (recordedFilePath == null) return;
    File audioFile = File(recordedFilePath!);

    // In a production app, you'd let user enter real title/content.
    final passageTitle = "Recorded Passage";
    final passageContent = "This is the content for the new passage...";

    // Upload the audio
    final audioUrl = await _firebaseService.uploadAudio(
      audioFile,
      "my_recorded_passage_${DateTime.now().millisecondsSinceEpoch}.aac",
    );

    // Save the passage info to Firestore.
    // NOTE: Pass the default category (in this example "Default") as the fourth argument.
    await _firebaseService.addPassage(
      passageTitle,
      passageContent,
      audioUrl,
      "Default", // You can update this to a different category if needed.
    );

    // Show success message and pop back
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passage added successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordButtonLabel = isRecording ? 'Stop Recording' : 'Start Recording';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Audio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Click the button to record a new passage.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (!isRecording) {
                  await startRecording();
                } else {
                  await stopRecording();
                }
              },
              child: Text(recordButtonLabel),
            ),
            const SizedBox(height: 20),
            if (recordedFilePath != null)
              Column(
                children: [
                  const Text('Recording saved!'),
                  ElevatedButton(
                    onPressed: uploadAndSavePassage,
                    child: const Text('Upload & Save Passage'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}