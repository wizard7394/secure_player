import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../dashboard/presentation/bloc/course_detail_bloc.dart';
import '../../../player/presentation/bloc/video_player_bloc.dart';
import '../../../player/presentation/screens/secure_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final ValueNotifier<String?> _lastPlayedNotifier = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _loadLastPlayedVideo();
  }

  Future<void> _loadLastPlayedVideo() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPlayed = prefs.getString('last_played_${widget.courseId}');
    if (lastPlayed != null) {
      _lastPlayedNotifier.value = lastPlayed;
    }
  }

  @override
  void dispose() {
    _lastPlayedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<CourseDetailBloc>()..add(FetchCourseContentEvent(widget.courseId)),
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        appBar: AppBar(
          backgroundColor: const Color(0xFF050505),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'COURSE MODULES',
            style: TextStyle(
              color: Color(0xFF00E676),
              letterSpacing: 2.0,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                itemCount: tree.length,
                itemBuilder: (context, index) {
                  return PlayerRecursiveNode(
                    node: tree[index],
                    courseId: widget.courseId,
                    lastPlayedNotifier: _lastPlayedNotifier,
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
  final ValueNotifier<String?> lastPlayedNotifier;

  const PlayerRecursiveNode({
    super.key,
    required this.node,
    required this.courseId,
    required this.lastPlayedNotifier,
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
          if (size > 1024) {
            activeFilePath = foundPath;
            if (mounted) setState(() => isFileReady = true);
            return;
          } else {
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
      if (size > 1024) {
        if (mounted) setState(() => isFileReady = true);
      } else {
        defaultFile.deleteSync();
      }
    }
  }

  Future<void> _handleVideoAction() async {
    final vault = widget.node['vault'];
    String videoUrl = widget.node['video_url']?.toString() ?? '';
    final vaultUuid = vault?['uuid']?.toString();

    if (vaultUuid != null) {
      widget.lastPlayedNotifier.value = vaultUuid;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_played_${widget.courseId}', vaultUuid);
    }

    if (videoUrl.isEmpty && vault != null) {
      videoUrl = vault['download_url']?.toString() ?? '';
    }

    if (videoUrl.isNotEmpty && !videoUrl.startsWith('http')) {
      videoUrl = 'https://cdn.nabegheha.com$videoUrl';
    }

    if (isFileReady) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider<VideoPlayerBloc>(
            create: (context) => sl<VideoPlayerBloc>(),
            child: SecurePlayerScreen(
              courseId: widget.courseId,
              videoId: vaultUuid ?? '',
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
      if (mounted) {
        setState(() {
          isDownloading = false;
          isFileReady = true;
        });
      }
    } catch (e) {
      if (targetFile.existsSync()) targetFile.deleteSync();
      if (mounted) {
        setState(() {
          isDownloading = false;
          downloadProgress = 0.0;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildTrailingAction(bool isActive) {
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
      return Icon(
        Icons.offline_pin_rounded,
        color: isActive ? Colors.white : const Color(0xFF00E676),
        size: 24,
      );
    }
    return Icon(
      Icons.cloud_download_outlined,
      color: isActive ? Colors.white54 : Colors.white24,
      size: 24,
    );
  }

  Widget _buildAttachmentChip(Map<String, dynamic> att) {
    final String type = att['type']?.toString().toLowerCase() ?? 'link';
    final String title = att['title']?.toString() ?? 'Resource';
    final String url = att['url']?.toString() ?? '';

    IconData icon = Icons.link_rounded;
    Color iconColor = Colors.blueAccent;

    if (type == 'pdf') {
      icon = Icons.picture_as_pdf_rounded;
      iconColor = Colors.redAccent;
    } else if (type == 'zip' || type == 'rar') {
      icon = Icons.folder_zip_rounded;
      iconColor = Colors.orangeAccent;
    } else if (type == 'code') {
      icon = Icons.code_rounded;
      iconColor = const Color(0xFF00E676);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        mouseCursor: SystemMouseCursors.click,
        onTap: () async {
          if (url.isNotEmpty) {
            final Uri uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1A1A1A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFolder = widget.node['item_type'] == 'folder';
    final children = widget.node['children'] as List<dynamic>? ?? [];
    final attachments = widget.node['attachments'] as List<dynamic>? ?? [];
    final vaultUuid = widget.node['vault']?['uuid']?.toString();

    if (!isFolder) {
      return ValueListenableBuilder<String?>(
        valueListenable: widget.lastPlayedNotifier,
        builder: (context, activeId, child) {
          final isActive = activeId != null && activeId == vaultUuid;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF00E676).withValues(alpha: 0.15),
                        const Color(0xFF0A0A0A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isActive ? null : const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF00E676)
                    : const Color(0xFF141414),
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00E676).withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    mouseCursor: isDownloading
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    hoverColor: Colors.white.withValues(alpha: 0.03),
                    splashColor: const Color(0xFF00E676).withValues(alpha: 0.1),
                    highlightColor: Colors.transparent,
                    onTap: isDownloading ? null : _handleVideoAction,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF00E676)
                                  : (isFileReady
                                        ? const Color(
                                            0xFF00E676,
                                          ).withValues(alpha: 0.1)
                                        : const Color(0xFF141414)),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00E676,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: isActive
                                  ? Colors.black
                                  : (isFileReady
                                        ? const Color(0xFF00E676)
                                        : Colors.white54),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.node['title'],
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      'Duration: ${widget.node['duration'] ?? 0} Min',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white70
                                            : Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF00E676,
                                          ).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'LAST PLAYED',
                                          style: TextStyle(
                                            color: Color(0xFF00E676),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _buildTrailingAction(isActive),
                        ],
                      ),
                    ),
                  ),
                ),
                if (attachments.isNotEmpty) ...[
                  Container(
                    height: 1,
                    color: const Color(0xFF141414),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: attachments
                          .map((att) => _buildAttachmentChip(att))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) =>
              setState(() => isExpanded = expanded),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          backgroundColor: const Color(0xFF0A0A0A),
          collapsedBackgroundColor: const Color(0xFF0A0A0A),
          iconColor: const Color(0xFF00E676),
          collapsedIconColor: Colors.white54,
          leading: Icon(
            isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
            color: isExpanded ? const Color(0xFF00E676) : Colors.white54,
            size: 28,
          ),
          title: Text(
            widget.node['title'],
            style: TextStyle(
              color: isExpanded ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
          children: [
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF141414), width: 2),
                ),
              ),
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 16,
                top: 16,
              ),
              child: Column(
                children: children.map((childNode) {
                  return PlayerRecursiveNode(
                    node: childNode,
                    courseId: widget.courseId,
                    lastPlayedNotifier: widget.lastPlayedNotifier,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
