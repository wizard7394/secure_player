import 'package:flutter/material.dart';

class SecurePlayerScreen extends StatefulWidget {
  final String courseId;
  final int videoId;
  final Map<String, dynamic>? vaultData;

  const SecurePlayerScreen({
    super.key,
    required this.courseId,
    required this.videoId,
    required this.vaultData,
  });

  @override
  State<SecurePlayerScreen> createState() => _SecurePlayerScreenState();
}

class _SecurePlayerScreenState extends State<SecurePlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF00E676)),
        title: const Text(
          'Offline Player Engine',
          style: TextStyle(color: Color(0xFF00E676), fontSize: 14),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, color: Color(0xFF00E676), size: 64),
            const SizedBox(height: 16),
            Text(
              'Vault UUID: ${widget.vaultData?['uuid'] ?? 'NOT ASSIGNED'}',
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ready for Rust Decryption Hook & Download Manager',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
