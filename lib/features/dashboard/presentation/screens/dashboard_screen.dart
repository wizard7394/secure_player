import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_player/features/dashboard/presentation/bloc/dashboard_bloc.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc()..add(FetchCourses()),
      child: const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: SafeArea(child: DashboardView()),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MY COURSES",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white30),
                onPressed: () {
                  // Logout logic goes here
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state is DashboardLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E676)),
                );
              }

              if (state is DashboardLoaded) {
                if (state.courses.isEmpty) {
                  return const EmptyCoursesView();
                }
                return CoursesGridView(courses: state.courses);
              }

              return const Center(
                child: Text(
                  "CONNECTION ERROR",
                  style: TextStyle(color: Colors.redAccent, letterSpacing: 2.0),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class EmptyCoursesView extends StatelessWidget {
  const EmptyCoursesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_off_outlined,
              color: Colors.white12,
              size: 80,
            ),
            const SizedBox(height: 24),
            const Text(
              "NO COURSES FOUND",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "You haven't purchased any courses yet. Head over to our website to explore the catalog.",
              style: TextStyle(
                color: Colors.white30,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Redirecting to browser...",
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                      backgroundColor: Color(0xFF00E676),
                    ),
                  );
                },
                child: const Text(
                  "BROWSE WEBSITE",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoursesGridView extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  const CoursesGridView({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 350,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.1,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 1.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF141414),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: Colors.white12,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          course["title"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${course["progress"]}% COMPLETED",
                              style: const TextStyle(
                                color: Colors.white30,
                                fontSize: 10,
                                letterSpacing: 1.0,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: course["progress"] / 100,
                              backgroundColor: Colors.white12,
                              color: const Color(0xFF00E676),
                              minHeight: 3,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
