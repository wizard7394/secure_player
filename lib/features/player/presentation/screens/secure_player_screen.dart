import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:secure_player/src/rust/api/simple.dart';
import '../bloc/video_player_bloc.dart';
import '../bloc/video_player_event.dart';
import '../bloc/video_player_state.dart';

class SecurePlayerScreen extends StatefulWidget {
  final String courseId;
  final String videoId;
  final dynamic vaultData;
  final String localFilePath;
  final String videoUrl;

  const SecurePlayerScreen({
    super.key,
    required this.courseId,
    required this.videoId,
    required this.vaultData,
    required this.localFilePath,
    required this.videoUrl,
  });

  @override
  State<SecurePlayerScreen> createState() => _SecurePlayerScreenState();
}

class _SecurePlayerScreenState extends State<SecurePlayerScreen> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);

    player.stream.error.listen((error) {
      log("MEDIA_KIT_ERROR: $error", name: "DRM_DEBUG");
    });

    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    try {
      final platform = player.platform as dynamic;

      // تنظیمات حیاتی برای غیرفعال کردن چک‌های ناامن پلی‌لیست
      await platform.setProperty('load-unsafe-playlists', 'yes');
      await platform.setProperty('force-seekable', 'yes');
      await platform.setProperty(
        'demuxer-lavf-o',
        'probesize=32,analyzeduration=0',
      );

      final int handleAddress = await platform.handle;

      // فراخوانی پروتکل ثبت شده
      bindSecureProtocol(handleAddress: handleAddress);
      log("Secure Protocol Bound Successfully!", name: "DRM_DEBUG");
    } catch (e) {
      log("Handle Error: $e", name: "DRM_DEBUG");
    }

    if (mounted) {
      context.read<VideoPlayerBloc>().add(
        InitializeVideo(
          courseId: widget.courseId,
          videoId: widget.videoId,
          localFilePath: widget.localFilePath,
          videoUrl: widget.videoUrl,
        ),
      );
    }
  }

  @override
  void dispose() {
    clearDecryptionKeys();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocListener<VideoPlayerBloc, VideoPlayerState>(
        listener: (context, state) async {
          if (state is VideoPlayerReady) {
            log("Opening Media: ${state.customUri}", name: "DRM_DEBUG");
            // استفاده از media_kit برای باز کردن با تنظیمات جدید
            await player.open(Media(state.customUri));
          }
        },
        child: Center(
          child: Video(controller: controller, controls: AdaptiveVideoControls),
        ),
      ),
    );
  }
}
