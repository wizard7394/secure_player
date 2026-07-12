import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/course_detail_bloc.dart';
import '../../../player/presentation/bloc/video_player_bloc.dart';
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
          actions: [
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(
                  Icons.drive_folder_upload,
                  color: Color(0xFF00E676),
                ),
                tooltip: 'Set External Storage Path',
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(ctx);
                  final courseBloc = BlocProvider.of<CourseDetailBloc>(ctx);

                  final result = await FilePicker.platform.getDirectoryPath();
                  if (result != null) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('custom_vault_path', result);

                    if (!ctx.mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Storage path linked: $result',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: const Color(0xFF00E676),
                      ),
                    );
                    courseBloc.add(FetchCourseContentEvent(courseId));
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
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
              final tree = state.courseData['sections'] as List<dynamic>? ?? [];
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
  bool isDownloading = false;
  double downloadProgress = 0.0;
  bool isFileReady = false;
  String activeFilePath = '';

  @override
  void initState() {
    super.initState();
    _checkLocalFileStatus();
  }

  Future<String?> _searchFileRobustly(
    Directory rootDir,
    String targetTitle,
  ) async {
    List<Directory> dirsToCheck = [rootDir];
    final String normalizedTarget = targetTitle.toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '',
    );

    while (dirsToCheck.isNotEmpty) {
      final currentDir = dirsToCheck.removeAt(0);
      try {
        final entities = currentDir.listSync(
          recursive: false,
          followLinks: false,
        );
        for (final entity in entities) {
          if (entity is File) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            if (fileName.toLowerCase().endsWith('.mp6')) {
              final nameWithoutExt = fileName.substring(0, fileName.length - 4);
              final normalizedFile = nameWithoutExt.toLowerCase().replaceAll(
                RegExp(r'\s+'),
                '',
              );
              if (normalizedFile == normalizedTarget) return entity.path;
            }
          } else if (entity is Directory) {
            dirsToCheck.add(entity);
          }
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  Future<void> _checkLocalFileStatus() async {
    if (widget.node['item_type'] == 'video' && widget.node['vault'] != null) {
      final String nodeTitle = widget.node['title']
          .toString()
          .replaceAll('.mp6', '')
          .trim();
      final vaultUuid = widget.node['vault']['uuid'].toString();
      final prefs = await SharedPreferences.getInstance();
      final customPath = prefs.getString('custom_vault_path');

      if (customPath != null && Directory(customPath).existsSync()) {
        final foundPath = await _searchFileRobustly(
          Directory(customPath),
          nodeTitle,
        );
        if (foundPath != null) {
          final file = File(foundPath);
          final size = file.lengthSync();
          log(
            "Local File Found in Custom Path: $foundPath | Size: $size bytes",
            name: "DRM_DEBUG",
          );
          if (size > 1024) {
            activeFilePath = foundPath;
            if (mounted) setState(() => isFileReady = true);
            return;
          } else {
            log("File is corrupted or empty. Deleting...", name: "DRM_DEBUG");
            file.deleteSync();
          }
        }
        activeFilePath = '$customPath${Platform.pathSeparator}$nodeTitle.mp6';
      } else {
        await _setFallbackDefaultPath(vaultUuid);
      }
    }
  }

  Future<void> _setFallbackDefaultPath(String vaultUuid) async {
    final targetFileName = 'media_$vaultUuid.mp6';
    final appDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${appDir.path}/drm_vault');
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    final defaultFilePath = '${targetDir.path}/$targetFileName';
    final defaultFile = File(defaultFilePath);
    activeFilePath = defaultFilePath;

    if (defaultFile.existsSync()) {
      final size = defaultFile.lengthSync();
      log(
        "Local File Found in Default Path: $defaultFilePath | Size: $size bytes",
        name: "DRM_DEBUG",
      );
      if (size > 1024) {
        if (mounted) setState(() => isFileReady = true);
      } else {
        log(
          "Default File is corrupted or empty. Deleting...",
          name: "DRM_DEBUG",
        );
        defaultFile.deleteSync();
      }
    } else {
      log(
        "No existing file found. Ready to download to: $activeFilePath",
        name: "DRM_DEBUG",
      );
    }
  }

  Future<void> _handleVideoAction() async {
    final vault = widget.node['vault'];
    String videoUrl = widget.node['video_url']?.toString() ?? '';
    if (videoUrl.isEmpty && vault != null) {
      videoUrl = vault['download_url']?.toString() ?? '';
    }
    if (videoUrl.isNotEmpty && !videoUrl.startsWith('http')) {
      videoUrl = 'https://cdn.nabegheha.com$videoUrl';
    }

    log("User Clicked Video. Action Triggered.", name: "DRM_DEBUG");
    log("Resolved Video URL: $videoUrl", name: "DRM_DEBUG");
    log("Is File Ready? $isFileReady", name: "DRM_DEBUG");

    if (isFileReady) {
      if (!mounted) return;
      log("Pushing to Player Screen...", name: "DRM_DEBUG");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider<VideoPlayerBloc>(
            create: (context) => sl<VideoPlayerBloc>(),
            child: SecurePlayerScreen(
              courseId: widget.courseId,
              videoId: widget.node['id'].toString(),
              vaultData: vault,
              localFilePath: activeFilePath,
              videoUrl: videoUrl,
            ),
          ),
        ),
      );
      return;
    }

    if (videoUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Media source URL is missing.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final targetFile = File(activeFilePath);
    final targetDir = targetFile.parent;
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    if (!mounted) return;
    setState(() {
      isDownloading = true;
      downloadProgress = 0.0;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    log("Starting Download via Dio...", name: "DRM_DEBUG");

    try {
      final dio = Dio();
      await dio.download(
        videoUrl,
        activeFilePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() => downloadProgress = received / total);
          }
        },
      );

      log(
        "Download Complete. Final Size: ${targetFile.lengthSync()} bytes",
        name: "DRM_DEBUG",
      );

      if (mounted) {
        setState(() {
          isDownloading = false;
          isFileReady = true;
        });
      }
    } catch (e) {
      log("DIO DOWNLOAD EXCEPTION: $e", name: "DRM_DEBUG");
      if (targetFile.existsSync()) targetFile.deleteSync();
      if (mounted) {
        setState(() {
          isDownloading = false;
          downloadProgress = 0.0;
        });
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildTrailingAction() {
    if (isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          value: downloadProgress,
          color: const Color(0xFF00E676),
          backgroundColor: Colors.white12,
          strokeWidth: 3,
        ),
      );
    }
    if (isFileReady) {
      return const Icon(
        Icons.offline_pin_rounded,
        color: Color(0xFF00E676),
        size: 24,
      );
    }
    return const Icon(
      Icons.cloud_download_outlined,
      color: Colors.white54,
      size: 24,
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
            onTap: isDownloading ? null : _handleVideoAction,
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
                  _buildTrailingAction(),
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
