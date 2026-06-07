import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../src/rust/api/simple.dart';
import 'video_player_event.dart';
import 'video_player_state.dart';

class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState> {
  final String encryptedFilePath =
      r"C:\Users\AmirHosein\Desktop\New folder\01.Start.mp6";

  final ApiClient _apiClient = di.sl<ApiClient>();

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

    try {
      print("Starting Hardware Handshake and Decryption...");

      final responseData = await _apiClient.fetchVideoKeys(
        event.courseId,
        event.licenseKey,
      );

      final String base64Key = responseData['aes_key'];
      final String base64Iv = responseData['aes_iv'];

      final List<int> aesKey = base64Decode(base64Key);
      final List<int> aesIv = base64Decode(base64Iv);

      final proxyUrl = await startProxyServer(
        port: 8080,
        filePath: encryptedFilePath,
        aesKey: aesKey,
        aesIv: aesIv,
      );

      print("Rust Proxy Server Connected Successfully at: $proxyUrl");

      emit(
        const VideoPlayerReady(
          isPlaying: false,
          currentPosition: Duration.zero,
          totalDuration: Duration(minutes: 45, seconds: 30),
          isMuted: false,
        ),
      );
    } catch (e) {
      print("Engine Disconnected or Error: $e");
      emit(const VideoPlayerInitial());
    }
  }

  void _onPlayVideo(PlayVideo event, Emitter<VideoPlayerState> emit) {
    if (state is VideoPlayerReady) {
      emit((state as VideoPlayerReady).copyWith(isPlaying: true));
    }
  }

  void _onPauseVideo(PauseVideo event, Emitter<VideoPlayerState> emit) {
    if (state is VideoPlayerReady) {
      emit((state as VideoPlayerReady).copyWith(isPlaying: false));
    }
  }

  void _onSeekVideo(SeekVideo event, Emitter<VideoPlayerState> emit) {
    if (state is VideoPlayerReady) {
      emit(
        (state as VideoPlayerReady).copyWith(currentPosition: event.position),
      );
    }
  }

  void _onToggleMute(ToggleMute event, Emitter<VideoPlayerState> emit) {
    if (state is VideoPlayerReady) {
      emit(
        (state as VideoPlayerReady).copyWith(
          isMuted: !(state as VideoPlayerReady).isMuted,
        ),
      );
    }
  }
}
