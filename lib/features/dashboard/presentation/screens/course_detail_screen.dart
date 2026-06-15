import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/course_detail_bloc.dart';
import '../../../player/presentation/screens/secure_player_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CourseDetailBloc>()..add(FetchCourseContentEvent(courseId)),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF141414),
          title: Text(
            'Course Modules // ID: $courseId',
            style: const TextStyle(color: Color(0xFF00E676)),
          ),
        ),
        body: BlocBuilder<CourseDetailBloc, CourseDetailState>(
          builder: (context, state) {
            if (state is CourseDetailLoading || state is CourseDetailInitial) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E676)),
              );
            } else if (state is CourseDetailError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            } else if (state is CourseDetailLoaded) {
              final tree = state.sections;

              if (tree.isEmpty) {
                return const Center(
                  child: Text(
                    'No content available.',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tree.length,
                itemBuilder: (context, index) {
                  return PlayerRecursiveNode(
                    node: tree[index],
                    courseId: courseId,
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class PlayerRecursiveNode extends StatefulWidget {
  final dynamic node;
  final String courseId;

  const PlayerRecursiveNode({
    super.key,
    required this.node,
    required this.courseId,
  });

  @override
  State<PlayerRecursiveNode> createState() => _PlayerRecursiveNodeState();
}

class _PlayerRecursiveNodeState extends State<PlayerRecursiveNode> {
  bool isExpanded = false;

  void _handleVideoTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurePlayerScreen(
          courseId: widget.courseId,
          videoId: widget.node['id'],
          vaultData: widget.node['vault'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFolder = widget.node['item_type'] == 'folder';
    final children = widget.node['children'] as List<dynamic>? ?? [];

    if (!isFolder) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8, top: 4),
        child: Material(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _handleVideoTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFF00E676), width: 4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_fill,
                    color: Color(0xFF00E676),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.node['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Duration: ${widget.node['duration'] ?? 0} Min',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.download_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8, top: 4),
          child: Material(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(4),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                isExpanded ? Icons.folder_open : Icons.folder,
                color: const Color(0xFF00E676),
              ),
              title: Text(
                widget.node['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.white54,
              ),
              onTap: () => setState(() => isExpanded = !isExpanded),
            ),
          ),
        ),
        if (isExpanded && children.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 16, bottom: 8),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Colors.white12, width: 2)),
            ),
            padding: const EdgeInsets.only(left: 16),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: children.length,
              itemBuilder: (context, childIndex) {
                return PlayerRecursiveNode(
                  node: children[childIndex],
                  courseId: widget.courseId,
                );
              },
            ),
          ),
      ],
    );
  }
}
