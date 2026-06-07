import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';

import '../bloc/video_player_bloc.dart';
import '../bloc/video_player_event.dart';
import '../bloc/video_player_state.dart';
import '../../../security_overlay/presentation/bloc/watermark_bloc.dart';
import '../../../security_overlay/presentation/widgets/security_overlay_view.dart';

class SecurePlayerScreen extends StatelessWidget {
  final String courseId;
  final String licenseKey;

  const SecurePlayerScreen({
    super.key,
    required this.courseId,
    required this.licenseKey,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => VideoPlayerBloc()
            ..add(InitializeVideo(courseId: courseId, licenseKey: licenseKey)),
        ),
        BlocProvider(
          create: (context) =>
              WatermarkBloc()..add(FetchWatermarkData(licenseKey)),
        ),
      ],
      child: const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: SafeArea(child: PlayerViewContainer()),
      ),
    );
  }
}

class PlayerViewContainer extends StatelessWidget {
  const PlayerViewContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Colors.black),
      clipBehavior: Clip.antiAlias,
      child: BlocBuilder<VideoPlayerBloc, VideoPlayerState>(
        builder: (context, state) {
          if (state is VideoPlayerLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            );
          }

          if (state is VideoPlayerReady) {
            return RustStreamPlayer(state: state);
          }

          return const Center(
            child: Text(
              "ENGINE DISCONNECTED",
              style: TextStyle(color: Colors.white30, letterSpacing: 2.0),
            ),
          );
        },
      ),
    );
  }
}

class RustStreamPlayer extends StatefulWidget {
  final VideoPlayerReady state;
  const RustStreamPlayer({super.key, required this.state});

  @override
  State<RustStreamPlayer> createState() => _RustStreamPlayerState();
}

class _RustStreamPlayerState extends State<RustStreamPlayer> {
  late final Player player;
  late final VideoController controller;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    player = Player(
      configuration: const PlayerConfiguration(bufferSize: 32 * 1024 * 1024),
    );
    controller = VideoController(player);
    player.open(Media('http://127.0.0.1:8080/stream'));
    player.play();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void _onPointerEnter(PointerEvent details) {
    setState(() {
      _showControls = true;
    });
  }

  void _onPointerExit(PointerEvent details) {
    setState(() {
      _showControls = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onPointerEnter,
      onExit: _onPointerExit,
      child: Stack(
        children: [
          Positioned.fill(
            child: Video(controller: controller, controls: NoVideoControls),
          ),

          const Positioned.fill(child: SecurityOverlayView()),

          IgnorePointer(
            ignoring: !_showControls,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: CustomPlayerControls(player: player),
                  ),
                  Positioned(
                    top: 30,
                    left: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomPlayerControls extends StatefulWidget {
  final Player player;
  const CustomPlayerControls({super.key, required this.player});

  @override
  State<CustomPlayerControls> createState() => _CustomPlayerControlsState();
}

class _CustomPlayerControlsState extends State<CustomPlayerControls> {
  bool _isDragging = false;
  Duration _dragPosition = Duration.zero;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours > 0
        ? '${duration.inHours.toString().padLeft(2, '0')}:'
        : '';
    return '$hours$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black87, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          StreamBuilder<Duration>(
            stream: widget.player.stream.position,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration>(
                stream: widget.player.stream.duration,
                builder: (context, durationSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = durationSnapshot.data ?? Duration.zero;

                  final displayPosition = _isDragging
                      ? _dragPosition
                      : position;

                  double sliderValue = displayPosition.inMilliseconds
                      .toDouble();
                  double sliderMax = duration.inMilliseconds.toDouble();

                  if (sliderValue > sliderMax || sliderMax == 0) {
                    sliderValue = 0;
                  }

                  return Row(
                    children: [
                      Text(
                        _formatDuration(displayPosition),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF00E676),
                            inactiveTrackColor: Colors.white12,
                            thumbColor: const Color(0xFF00E676),
                            overlayColor: const Color(
                              0xFF00E676,
                            ).withOpacity(0.2),
                            trackHeight: 3.0,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6.0,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14.0,
                            ),
                          ),
                          child: Slider(
                            value: sliderValue,
                            max: sliderMax > 0 ? sliderMax : 1.0,
                            onChangeStart: (value) {
                              setState(() {
                                _isDragging = true;
                                _dragPosition = Duration(
                                  milliseconds: value.toInt(),
                                );
                              });
                            },
                            onChanged: (value) {
                              setState(() {
                                _dragPosition = Duration(
                                  milliseconds: value.toInt(),
                                );
                              });
                            },
                            onChangeEnd: (value) {
                              setState(() {
                                _isDragging = false;
                              });
                              widget.player.seek(
                                Duration(milliseconds: value.toInt()),
                              );
                            },
                          ),
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white30,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<bool>(
                stream: widget.player.stream.playing,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    color: Colors.white,
                    iconSize: 32,
                    onPressed: () => widget.player.playOrPause(),
                  );
                },
              ),
              Row(
                children: [
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: PopupMenuButton<double>(
                      initialValue: 1.0,
                      tooltip: 'Speed',
                      color: const Color(0xFF1A1A1A),
                      elevation: 8,
                      offset: const Offset(0, -220),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: const BorderSide(
                          color: Color(0xFF333333),
                          width: 1,
                        ),
                      ),
                      icon: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onSelected: (rate) {
                        widget.player.setRate(rate);
                      },
                      itemBuilder: (context) =>
                          [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((rate) {
                            return PopupMenuItem<double>(
                              value: rate,
                              height: 36,
                              child: Center(
                                child: Text(
                                  '${rate}x',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen_rounded),
                    color: Colors.white54,
                    iconSize: 24,
                    onPressed: () async {
                      bool isFullScreen = await windowManager.isFullScreen();
                      if (isFullScreen) {
                        await windowManager.setFullScreen(false);
                      } else {
                        await windowManager.setFullScreen(true);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
