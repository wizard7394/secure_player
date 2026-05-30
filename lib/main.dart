import 'package:flutter/material.dart';
import 'features/player/presentation/screens/secure_player_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecurePlayerApp());
}

class SecurePlayerApp extends StatelessWidget {
  const SecurePlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        useMaterial3: true,
      ),
      home: const SecurePlayerScreen(),
    );
  }
}
