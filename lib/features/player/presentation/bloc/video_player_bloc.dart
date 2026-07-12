import 'dart:convert';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secure_player/src/rust/api/simple.dart';
import '../../data/domain/repositories/video_stream_repository.dart';
import 'video_player_event.dart';
import 'video_player_state.dart';

class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState> {
  final VideoStreamRepository videoStreamRepository;

  VideoPlayerBloc({required this.videoStreamRepository})
    : super(const VideoPlayerInitial()) {
    on<InitializeVideo>(_onInitializeVideo);
    on<PlayVideo>(_onPlayVideo);
    on<PauseVideo>(_onPauseVideo);
    on<SeekVideo>(_onSeekVideo);
    on<ToggleMute>(_onToggleMute);
  }

  List<int> _parseKey(String? input, String keyName, int requiredLength) {
    if (input == null || input.trim().isEmpty || input == 'null') {
      log("$keyName is MISSING! Padding with zeros.", name: "DRM_DEBUG");
      return List<int>.filled(requiredLength, 0);
    }

    final cleaned = input.trim().replaceAll('"', '');
    final decoded = base64Decode(cleaned);

    if (decoded.length != requiredLength) {
      log(
        "$keyName length is ${decoded.length}, but Rust expects $requiredLength! Fixing it.",
        name: "DRM_DEBUG",
      );
      if (decoded.length < requiredLength) {
        final padded = List<int>.from(decoded);
        padded.addAll(List<int>.filled(requiredLength - decoded.length, 0));
        return padded;
      } else {
        return decoded.sublist(0, requiredLength);
      }
    }
    return decoded;
  }

  void _onInitializeVideo(
    InitializeVideo event,
    Emitter<VideoPlayerState> emit,
  ) async {
    emit(const VideoPlayerLoading());

    try {
      final responseData = await videoStreamRepository.getVideoKeys(
        event.courseId,
        event.videoId,
      );

      final aesKey = _parseKey(
        responseData['aes_key']?.toString(),
        "AES_KEY",
        32,
      );
      final aesIv = _parseKey(responseData['aes_iv']?.toString(), "AES_IV", 12);

      log("Final Key Length -> ${aesKey.length} bytes", name: 'DRM_DEBUG');
      log("Final IV Length -> ${aesIv.length} bytes", name: 'DRM_DEBUG');

      final targetPath = (event.localFilePath.isNotEmpty)
          ? event.localFilePath
          : event.videoUrl;

      setDecryptionKeys(key: aesKey, iv: aesIv, filePath: targetPath);

      final String customUri = 'safedrm://bypass_video.mp4';

      emit(
        VideoPlayerReady(
          isPlaying: false,
          currentPosition: Duration.zero,
          totalDuration: const Duration(minutes: 45, seconds: 30),
          isMuted: false,
          customUri: customUri,
        ),
      );
    } catch (e) {
      log("DRM Stream Error: $e", name: 'DRM_DEBUG');
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
