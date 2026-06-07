import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_player/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:secure_player/features/dashboard/presentation/screens/course_detail_screen.dart';
import 'package:secure_player/core/di/injection_container.dart' as di;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<DashboardBloc>()..add(FetchCoursesEvent()),
      child: const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: DashboardView(),
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(40.0, 60.0, 40.0, 20.0),
          child: Text(
            "MY COURSES",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 3.0,
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading || state is DashboardInitial) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF00E676),
                    strokeWidth: 3.0,
                  ),
                );
              } else if (state is DashboardError) {
                return Center(
                  child: Text(
                    "Connection failed: ${state.message}",
                    style: const TextStyle(
                      color: Color(0xFFD32F2F),
                      fontFamily: 'monospace',
                      fontSize: 16,
                    ),
                  ),
                );
              } else if (state is DashboardLoaded) {
                final courses = state.courses;
                if (courses.isEmpty) {
                  return const Center(
                    child: Text(
                      "No purchased courses found.",
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 16,
                        letterSpacing: 1.0,
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 20.0,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return CourseCardWidget(course: course);
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}

class CourseCardWidget extends StatelessWidget {
  final dynamic course;
  const CourseCardWidget({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          hoverColor: Colors.white.withValues(alpha: 0.02),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(
                  courseId: course['id'].toString(),
                  licenseKey: course['license_key'].toString(),
                  courseTitle: course['title'].toString(),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Color(0xFF00E676),
                    size: 32,
                  ),
                ),
                const Spacer(),
                Text(
                  course['title'] ?? 'Unknown Course',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  "LICENSE: ${course['license_key']}",
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
