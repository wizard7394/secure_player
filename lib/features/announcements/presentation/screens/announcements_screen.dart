import 'package:flutter/material.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fake data for UI development
    final List<Map<String, dynamic>> fakeAnnouncements = [
      {
        'title': 'System Maintenance Scheduled',
        'date': '2026-07-20',
        'time': '23:00 CEST',
        'content':
            'We will be upgrading our DRM backend servers to improve video streaming performance. Expect minor interruptions during this maintenance window. All offline vaults will remain fully accessible.',
        'is_new': true,
        'type': 'warning',
      },
      {
        'title': 'New LPIC-2 Modules Uploaded',
        'date': '2026-07-18',
        'time': '09:15 CEST',
        'content':
            'The highly requested advanced Linux networking modules are now available in your course library. Make sure to restart your player to fetch the latest curriculum tree.',
        'is_new': true,
        'type': 'info',
      },
      {
        'title': 'Player Version 1.2.0 Released',
        'date': '2026-07-15',
        'time': '14:30 CEST',
        'content':
            'Added support for hardware acceleration and improved offline file scanning speed. We also squashed several bugs related to dual-monitor setups. Update is highly recommended.',
        'is_new': false,
        'type': 'update',
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
          'ANNOUNCEMENTS',
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: fakeAnnouncements.length,
        itemBuilder: (context, index) {
          final item = fakeAnnouncements[index];
          return _buildAnnouncementCard(context, item);
        },
      ),
    );
  }

  Widget _buildAnnouncementCard(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final bool isNew = item['is_new'];
    final Color accentColor = isNew ? const Color(0xFF00E676) : Colors.white24;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          mouseCursor: SystemMouseCursors.click,
          onTap: () {
            _showAnnouncementDetails(context, item, accentColor);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF141414), width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isNew ? 'NEW' : 'READ',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              Text(
                                item['date'],
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['content'],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetails(
    BuildContext context,
    Map<String, dynamic> item,
    Color accentColor,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF141414), width: 2),
        ),
        child: Container(
          width: 500, // Fixed width for desktop screens
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.campaign_rounded, color: accentColor, size: 32),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                    ),
                    mouseCursor: SystemMouseCursors.click,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                item['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['date'],
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(width: 24),
                  const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white38,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['time'] ?? '00:00',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF141414), height: 1),
              const SizedBox(height: 24),
              Text(
                item['content'],
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor.withValues(alpha: 0.1),
                    foregroundColor: accentColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'DISMISS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
