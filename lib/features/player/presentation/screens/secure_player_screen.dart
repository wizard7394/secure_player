import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/video_player_bloc.dart';
import '../bloc/video_player_event.dart';
import '../bloc/video_player_state.dart';

class SecurePlayerScreen extends StatelessWidget {
  const SecurePlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          VideoPlayerBloc()..add(const InitializeVideo("encrypted_file.data")),
      child: const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: SafeArea(child: Center(child: PlayerViewContainer())),
      ),
    );
  }
}

class PlayerViewContainer extends StatelessWidget {
  const PlayerViewContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 960,
      height: 540,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 1.5),
      ),
      child: BlocBuilder<VideoPlayerBloc, VideoPlayerState>(
        builder: (context, state) {
          if (state is VideoPlayerLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            );
          }
          if (state is VideoPlayerReady) {
            return Stack(
              children: [
                Center(
                  child: Icon(
                    state.isPlaying
                        ? Icons.play_circle_fill
                        : Icons.pause_circle_filled,
                    size: 80,
                    color: Colors.white10,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: PlayerControlBar(state: state),
                ),
              ],
            );
          }
          return const Center(
            child: Text(
              "WAITING FOR ENGINE",
              style: TextStyle(color: Colors.white30),
            ),
          );
        },
      ),
    );
  }
}

class PlayerControlBar extends StatelessWidget {
  final VideoPlayerReady state;
  const PlayerControlBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
            color: const Color(0xFF00E676),
            onPressed: () {
              final bloc = context.read<VideoPlayerBloc>();
              state.isPlaying
                  ? bloc.add(const PauseVideo())
                  : bloc.add(const PlayVideo());
            },
          ),
          IconButton(
            icon: Icon(state.isMuted ? Icons.volume_off : Icons.volume_up),
            color: Colors.white,
            onPressed: () {
              context.read<VideoPlayerBloc>().add(const ToggleMute());
            },
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF00E676),
                inactiveTrackColor: Colors.white12,
                thumbColor: const Color(0xFF00E676),
                trackHeight: 4.0,
              ),
              child: Slider(
                value: state.currentPosition.inSeconds.toDouble(),
                max: state.totalDuration.inSeconds.toDouble(),
                onChanged: (value) {
                  context.read<VideoPlayerBloc>().add(
                    SeekVideo(Duration(seconds: value.toInt())),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
