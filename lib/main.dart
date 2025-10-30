import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/record_audio_page.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create and load the global settings.
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settingsProvider,
      child: const MyCatholicApp(),
    ),
  );
}

class MyCatholicApp extends StatelessWidget {
  const MyCatholicApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to high contrast mode using Provider
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'My Catholic App',
      theme: settings.isHighContrast
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              primaryColor: Colors.black,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
              ),
            )
          : ThemeData(
              primarySwatch: Colors.blue,
            ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/record': (context) => const RecordAudioPage(),
      },
    );
  }
}