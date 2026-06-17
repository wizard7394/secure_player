import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:secure_player/src/rust/api/simple.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../bloc/video_player_bloc.dart';
import '../bloc/video_player_event.dart';
import '../bloc/video_player_state.dart';

class SecurePlayerScreen extends StatefulWidget {
  final String courseId;
  final dynamic videoId;
  final dynamic vaultData;
  final String? localFilePath;

  const SecurePlayerScreen({
    super.key,
    required this.courseId,
    required this.videoId,
    required this.vaultData,
    this.localFilePath,
  });

  @override
  State<SecurePlayerScreen> createState() => _SecurePlayerScreenState();
}

class _SecurePlayerScreenState extends State<SecurePlayerScreen> {
  late final Player player;
  late final VideoController controller;
  late final VideoPlayerBloc _bloc;
  bool isEngineBound = false;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    _bloc = di.sl<VideoPlayerBloc>();
    _initSecureEngine();
  }

  Future<void> _initSecureEngine() async {
    if (widget.localFilePath == null || widget.localFilePath!.isEmpty) {
      return;
    }

    final nativePlayer = player.platform as dynamic;
    final int handleAddress = await nativePlayer.handle;

    isEngineBound = bindSecureProtocol(handleAddress: handleAddress);

    if (isEngineBound) {
      _bloc.add(
        InitializeVideo(
          courseId: widget.courseId,
          videoId: widget.videoId.toString(),
          licenseKey: 'DUMMY_LICENSE_TEST',
          localFilePath: widget.localFilePath!,
        ),
      );
    }
  }

  @override
  void dispose() {
    player.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<VideoPlayerBloc, VideoPlayerState>(
          listener: (context, state) {
            if (state is VideoPlayerReady) {
              player.open(Media('safedrm://video.mp4'));

              Future.delayed(const Duration(milliseconds: 300), () async {
                final nativePlayer = player.platform as dynamic;
                final int handleAddress = await nativePlayer.handle;
                playSecureStream(handleAddress: handleAddress);
              });
            }
          },
          builder: (context, state) {
            if (state is VideoPlayerInitial || state is VideoPlayerLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E676)),
                    SizedBox(height: 16),
                    Text(
                      "Injecting Decryption Keys to Memory...",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Video(
                      controller: controller,
                      controls: AdaptiveVideoControls,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
