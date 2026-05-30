import 'package:flutter_bloc/flutter_bloc.dart';
import 'video_player_event.dart';
import 'video_player_state.dart';

class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState> {
  VideoPlayerBloc() : super(const VideoPlayerInitial()) {
    on<InitializeVideo>(_onInitializeVideo);
    on<PlayVideo>(_onPlayVideo);
    on<PauseVideo>(_onPauseVideo);
    on<SeekVideo>(_onSeekVideo);
    on<ToggleMute>(_onToggleMute);
  }

  void _onInitializeVideo(
    InitializeVideo event,
    Emitter<VideoPlayerState> emit,
  ) async {
    emit(const VideoPlayerLoading());
    await Future.delayed(const Duration(seconds: 2));
    emit(
      const VideoPlayerReady(
        isPlaying: false,
        currentPosition: Duration.zero,
        totalDuration: Duration(minutes: 45, seconds: 30),
        isMuted: false,
      ),
    );
  }

  void _onPlayVideo(PlayVideo event, Emitter<VideoPlayerState> emit) {
    if (state is VideoPlayerReady) {
      final currentState = state as VideoPlayerReady;
      emit(currentState.copyWith(isPlaying: true));
    }
  }

  void _onPauseVideo(PauseVideo event, Emitter<VideoPlayerState> emit) {
    if (state is VideoPlayerReady) {
      final currentState = state as VideoPlayerReady;
      emit(currentState.copyWith(isPlaying: false));
    }
  }

  void _onSeekVideo(SeekVideo event, Emitter<VideoPlayerState> emit) {
    if (state is VideoPlayerReady) {
      final currentState = state as VideoPlayerReady;
      emit(currentState.copyWith(currentPosition: event.position));
    }
  }

  void _onToggleMute(ToggleMute event, Emitter<VideoPlayerState> emit) {
    if (state is VideoPlayerReady) {
      final currentState = state as VideoPlayerReady;
      emit(currentState.copyWith(isMuted: !currentState.isMuted));
    }
  }
}
