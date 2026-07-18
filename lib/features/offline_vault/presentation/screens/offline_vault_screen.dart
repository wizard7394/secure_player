import 'package:flutter/material.dart';

class OfflineVaultScreen extends StatefulWidget {
  const OfflineVaultScreen({super.key});

  @override
  State<OfflineVaultScreen> createState() => _OfflineVaultScreenState();
}

class _OfflineVaultScreenState extends State<OfflineVaultScreen> {
  // Fake state variable for UI development
  String _currentPath = "Not Selected (Using Default App Directory)";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'OFFLINE VAULT',
          style: TextStyle(
            color: Color(0xFF00E676),
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VAULT LOCATION',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            _buildPathCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPathCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF141414), width: 2),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.folder_special_rounded,
                color: Color(0xFF00E676),
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Current Storage Path',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1A1A1A)),
            ),
            child: Text(
              _currentPath,
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This is the directory where the player will look for your downloaded .mp6 video files.',
            style: TextStyle(color: Colors.white38, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              // Mock action to simulate folder selection
              setState(() {
                _currentPath = "D:\\Nabegheha\\Courses\\Downloaded";
              });
            },
            icon: const Icon(Icons.create_new_folder_rounded),
            label: const Text(
              'BROWSE FOLDER',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF141414),
            foregroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF1A1A1A)),
            ),
          ),
          onPressed: () {
            // Mock action to reset path
            setState(() {
              _currentPath = "Not Selected (Using Default App Directory)";
            });
          },
          child: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}
