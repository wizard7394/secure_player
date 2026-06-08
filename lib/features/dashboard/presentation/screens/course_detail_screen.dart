import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_player/features/dashboard/presentation/bloc/course_detail_bloc.dart';
import 'package:secure_player/features/player/presentation/screens/secure_player_screen.dart';
import 'package:secure_player/core/di/injection_container.dart' as di;

class CourseDetailScreen extends StatelessWidget {
  final String courseId;
  final String licenseKey;
  final String courseTitle;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.licenseKey,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          di.sl<CourseDetailBloc>()..add(FetchCourseContentEvent(courseId)),
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D0D0D),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            courseTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: const Color(0xFF1A1A1A), height: 1.0),
          ),
        ),
        body: CourseDetailSplitView(courseId: courseId, licenseKey: licenseKey),
      ),
    );
  }
}

class CourseDetailSplitView extends StatefulWidget {
  final String courseId;
  final String licenseKey;

  const CourseDetailSplitView({
    super.key,
    required this.courseId,
    required this.licenseKey,
  });

  @override
  State<CourseDetailSplitView> createState() => _CourseDetailSplitViewState();
}

class _CourseDetailSplitViewState extends State<CourseDetailSplitView> {
  int _selectedSectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourseDetailBloc, CourseDetailState>(
      builder: (context, state) {
        if (state is CourseDetailLoading || state is CourseDetailInitial) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00E676),
              strokeWidth: 3.0,
            ),
          );
        } else if (state is CourseDetailError) {
          return Center(
            child: Text(
              "Data sync failed: ${state.message}",
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontFamily: 'monospace',
                fontSize: 16,
              ),
            ),
          );
        } else if (state is CourseDetailLoaded) {
          final sections = state.sections;
          if (sections.isEmpty) {
            return const Center(
              child: Text(
                "No content available for this course.",
                style: TextStyle(color: Colors.white30, fontSize: 16),
              ),
            );
          }

          if (_selectedSectionIndex >= sections.length) {
            _selectedSectionIndex = 0;
          }

          final selectedSection = sections[_selectedSectionIndex];
          final videos = selectedSection['videos'] as List<dynamic>;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 320,
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                  border: Border(
                    right: BorderSide(color: Color(0xFF1A1A1A), width: 1.5),
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  itemCount: sections.length,
                  itemBuilder: (context, index) {
                    final section = sections[index];
                    final isSelected = index == _selectedSectionIndex;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSectionIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 20.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00E676).withValues(alpha: 0.08)
                              : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF00E676)
                                  : Colors.transparent,
                              width: 4.0,
                            ),
                          ),
                        ),
                        child: Text(
                          section['title'] ?? 'Section',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(40.0),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D0D),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: const Color(0xFF1A1A1A),
                          width: 1.5,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.0),
                          hoverColor: Colors.white.withValues(alpha: 0.02),
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration: const Duration(
                                  milliseconds: 150,
                                ),
                                reverseTransitionDuration: const Duration(
                                  milliseconds: 150,
                                ),
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        SecurePlayerScreen(
                                          courseId: widget.courseId,
                                          licenseKey: widget.licenseKey,
                                        ),
                                transitionsBuilder:
                                    (
                                      context,
                                      animation,
                                      secondaryAnimation,
                                      child,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14.0),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00E676,
                                    ).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Color(0xFF00E676),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        video['title'] ?? 'Unknown Session',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        video['description'] ??
                                            'Premium content',
                                        style: const TextStyle(
                                          color: Colors.white30,
                                          fontSize: 14,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 16.0),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white24,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }
}
