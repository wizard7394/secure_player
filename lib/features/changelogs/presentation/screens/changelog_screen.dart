import 'package:flutter/material.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fake data for UI development
    final List<Map<String, dynamic>> fakeChangelogs = [
      {
        'version': 'v1.2.0',
        'date': '2026-07-15',
        'is_latest': true,
        'changes': [
          {
            'type': 'NEW',
            'text': 'Hardware acceleration support added to MediaKit core.',
            'color': const Color(0xFF00E676),
          },
          {
            'type': 'IMPROVED',
            'text':
                'Optimized offline vault scanning algorithm for faster load times.',
            'color': Colors.blueAccent,
          },
          {
            'type': 'FIXED',
            'text':
                'Resolved UI overflow issues on smaller minimum window sizes.',
            'color': Colors.redAccent,
          },
        ],
      },
      {
        'version': 'v1.1.5',
        'date': '2026-06-28',
        'is_latest': false,
        'changes': [
          {
            'type': 'NEW',
            'text': 'Introduced announcement badge system on the dashboard.',
            'color': const Color(0xFF00E676),
          },
          {
            'type': 'FIXED',
            'text':
                'Fixed audio desynchronization on Bluetooth output devices.',
            'color': Colors.redAccent,
          },
        ],
      },
      {
        'version': 'v1.1.0',
        'date': '2026-06-10',
        'is_latest': false,
        'changes': [
          {
            'type': 'NEW',
            'text': 'Added custom path selection for Offline Vault storage.',
            'color': const Color(0xFF00E676),
          },
          {
            'type': 'IMPROVED',
            'text': 'Refined floating watermark algorithm for better security.',
            'color': Colors.blueAccent,
          },
        ],
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'CHANGELOG',
          style: TextStyle(
            color: Color(0xFF00E676),
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: fakeChangelogs.length,
        itemBuilder: (context, index) {
          final item = fakeChangelogs[index];
          return _buildVersionCard(item);
        },
      ),
    );
  }

  Widget _buildVersionCard(Map<String, dynamic> item) {
    final bool isLatest = item['is_latest'];
    final List<dynamic> changes = item['changes'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLatest
                ? const Color(0xFF00E676).withValues(alpha: 0.3)
                : const Color(0xFF141414),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF141414), width: 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        item['version'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (isLatest) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00E676,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'LATEST',
                            style: TextStyle(
                              color: Color(0xFF00E676),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    item['date'],
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: List.generate(changes.length, (changeIndex) {
                  final change = changes[changeIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: change['color'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              change['type'],
                              style: TextStyle(
                                color: change['color'],
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              change['text'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
