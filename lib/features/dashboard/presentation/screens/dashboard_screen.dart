import 'package:flutter/material.dart';

import '../../../courses/presentation/screens/my_courses_screen.dart';
import '../../../offline_vault/presentation/screens/offline_vault_screen.dart';
import '../../../announcements/presentation/screens/announcements_screen.dart';
import '../../../changelogs/presentation/screens/changelog_screen.dart';
import '../../../preferences/presentation/screens/preferences_screen.dart';

import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingHeader(),
                const SizedBox(height: 32),
                _buildHeroContinueCard(),
                const SizedBox(height: 40),
                const Text(
                  'NAVIGATION',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 16),
                _buildListMenu(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DRM DASHBOARD',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Welcome Back',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFF141414),
          child: Icon(Icons.person_outline_rounded, color: Color(0xFF00E676)),
        ),
      ],
    );
  }

  Widget _buildHeroContinueCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2E1A), Color(0xFF050505)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF141414), width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.play_circle_filled_rounded,
              size: 140,
              color: const Color(0xFF00E676).withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'RESUME',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'LPIC-1: Managing Files',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Session 05 // 45:30 Remaining',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: Colors.black26,
                    color: Color(0xFF00E676),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListMenu(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'My Courses',
        'subtitle': 'Access purchased content',
        'icon': Icons.video_library_rounded,
        'badge': 0,
      },
      {
        'title': 'Offline Vault',
        'subtitle': 'Manage downloaded files',
        'icon': Icons.download_done_rounded,
        'badge': 0,
      },
      {
        'title': 'Announcements',
        'subtitle': 'Latest updates & news',
        'icon': Icons.campaign_rounded,
        'badge': 2, // Fake unread count
      },
      {
        'title': 'Changelogs',
        'subtitle': 'Software versions history',
        'icon': Icons.new_releases_rounded,
        'badge': 0,
      },
      {
        'title': 'Report Issue',
        'subtitle': 'Submit bugs or feedback',
        'icon': Icons.bug_report_rounded,
        'badge': 0,
      },
      {
        'title': 'Preferences',
        'subtitle': 'Player & system settings',
        'icon': Icons.settings_rounded,
        'badge': 0,
      },
    ];

    return Column(
      children: List.generate(menuItems.length, (index) {
        final item = menuItems[index];
        final int badgeCount = item['badge'] ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Material(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              mouseCursor: SystemMouseCursors.click,
              onTap: () async {
                if (item['title'] == 'My Courses') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyCoursesScreen(),
                    ),
                  );
                } else if (item['title'] == 'Offline Vault') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OfflineVaultScreen(),
                    ),
                  );
                } else if (item['title'] == 'Announcements') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnnouncementsScreen(),
                    ),
                  );
                } else if (item['title'] == 'Changelogs') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangelogScreen(),
                    ),
                  );
                } else if (item['title'] == 'Preferences') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PreferencesScreen(),
                    ),
                  );
                } else if (item['title'] == 'Report Issue') {
                  final Uri url = Uri.parse(
                    'https://nabegheha.com/my-account/tickets/',
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'],
                        color: const Color(0xFF00E676),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle'],
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (badgeCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '$badgeCount NEW',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white24,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
