import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../src/rust/api/simple.dart';
import 'video_player_event.dart';
import 'video_player_state.dart';

class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState> {
  final String jwtToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJsaWNlbnNlX2lkIjoxLCJkZXZpY2VfaGFzaCI6ImR1bW15X2hhc2hfMTIzNDU2Nzg5IiwiZXhwIjoxNzgwNzg1NDczfQ.3SGXG0QR5PRguysMMjt3lR1F9qBJujVHhgL88iLerqg";
  final String encryptedFilePath =
      r"C:\Users\AmirHosein\Desktop\New folder\01.Start.mp6";
  final Dio _dio = Dio();

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
      final response = await _dio.get(
        'http://127.0.0.1:8000/hls/155/vid_1/keys',
        options: Options(headers: {'Authorization': 'Bearer $jwtToken'}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load keys from server: ${response.statusCode}',
        );
      }

      final responseData = response.data;
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

      print("Proxy Server Started at: $proxyUrl");

      emit(
        const VideoPlayerReady(
          isPlaying: false,
          currentPosition: Duration.zero,
          totalDuration: Duration(minutes: 45, seconds: 30),
          isMuted: false,
        ),
      );
    } catch (e) {
      print("Error initializing video: $e");
    }
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
