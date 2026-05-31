// The original content is temporarily commented out to allow generating a self-contained demo - feel free to uncomment later.

// import 'package:flutter/material.dart';
// import 'features/player/presentation/screens/secure_player_screen.dart';
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const SecurePlayerApp());
// }
//
// class SecurePlayerApp extends StatelessWidget {
//   const SecurePlayerApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Secure Video Player',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         scaffoldBackgroundColor: const Color(0xFF0A0A0A),
//         useMaterial3: true,
//       ),
//       home: const SecurePlayerScreen(),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:secure_player/src/rust/api/simple.dart';
import 'package:secure_player/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
          child: Text(
            'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`',
          ),
        ),
      ),
    );
  }
}
