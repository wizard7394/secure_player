import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'core/di/injection_container.dart' as di;
import 'core/utils/globals.dart';
import 'core/network/certificate_pinning.dart';
import 'features/auth_license/presentation/bloc/auth_bloc.dart';
import 'features/auth_license/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'src/rust/frb_generated.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = AppHttpOverrides();
  await di.init();
  MediaKit.ensureInitialized();
  await RustLib.init();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1024, 768), // Default startup size
    minimumSize: Size(800, 600), // Minimum allowed size to prevent UI overflow
    center: true,
    skipTaskbar: false,
    title: 'DRM Secure Player',
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
      navigatorKey: globalNavigatorKey,
      title: 'Secure Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        canvasColor: const Color(0xFF050505),
        dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0D0D0D)),
      ),
      // COMMENT/UNCOMMENT THE LINES BELOW TO TOGGLE LOGIN BYPASS
      initialRoute: '/',

      // initialRoute: '/dashboard',
      routes: {
        '/': (context) => BlocProvider(
          create: (_) => di.sl<AuthBloc>(),
          child: const LoginScreen(),
        ),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
