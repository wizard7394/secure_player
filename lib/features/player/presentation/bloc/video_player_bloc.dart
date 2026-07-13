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
      return List<int>.filled(requiredLength, 0);
    }

    final cleaned = input.trim().replaceAll('"', '');
    List<int> decoded = [];

    final isHex = RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned);
    if (isHex && cleaned.length >= requiredLength * 2) {
      try {
        for (int i = 0; i < requiredLength * 2; i += 2) {
          decoded.add(int.parse(cleaned.substring(i, i + 2), radix: 16));
        }
      } catch (_) {
        decoded = [];
      }
    }

    if (decoded.isEmpty) {
      try {
        decoded = base64Decode(cleaned);
      } catch (_) {
        decoded = [];
      }
    }

    if (decoded.length != requiredLength) {
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

      final rawKey =
          responseData['aes_key']?.toString() ??
          responseData['key']?.toString();
      final rawIv =
          responseData['aes_iv']?.toString() ??
          responseData['iv']?.toString() ??
          responseData['nonce']?.toString() ??
          responseData['video_iv']?.toString();

      final aesKey = _parseKey(rawKey, "AES_KEY", 32);
      final aesIv = _parseKey(rawIv, "AES_IV", 12);

      final targetPath = (event.localFilePath.isNotEmpty)
          ? event.localFilePath
          : event.videoUrl;

      // 🔴 رفع تداخل همزمان: اجبار سیستم به صبر کردن تا زمان تزریق کامل کلیدها در Rust
      await (setDecryptionKeys(key: aesKey, iv: aesIv, filePath: targetPath)
          as dynamic);

      // یک تاخیر مایکرو برای اطمینان از سینک شدن تردها
      await Future.delayed(const Duration(milliseconds: 150));

      final String customUri =
          'safedrm://bypass_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

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
