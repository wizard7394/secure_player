import 'package:flutter/material.dart';
import 'package:secure_player/features/auth_license/presentation/screens/login_screen.dart';
// import 'features/player/presentation/screens/secure_player_screen.dart';
import 'src/rust/frb_generated.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();
  await RustLib.init();

  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    center: true,
    skipTaskbar: false,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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
      home: const LoginScreen(),
    );
  }
}
