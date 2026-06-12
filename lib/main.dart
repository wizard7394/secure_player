import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_player/features/auth_license/presentation/screens/login_screen.dart';
import 'src/rust/frb_generated.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'core/di/injection_container.dart' as di;
import 'features/auth_license/presentation/bloc/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await di.init();

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        canvasColor: const Color(0xFF050505),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0D0D0D)),
      ),
      home: BlocProvider(
        create: (_) => di.sl<AuthBloc>(),
        child: const LoginScreen(),
      ),
    );
  }
}


// test kd