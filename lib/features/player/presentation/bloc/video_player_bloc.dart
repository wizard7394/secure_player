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

  // پارسر دقیق برای جلوگیری از خطای طول بایت در فرمت Base64
  List<int> _parseKey(String input) {
    input = input.trim().replaceAll('"', '');
    return base64Decode(input);
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

      final aesKey = _parseKey(responseData['aes_key']);
      final aesIv = _parseKey(responseData['aes_iv']);

      log(
        "Final Key Length -> ${aesKey.length} bytes",
        name: 'VideoPlayerBloc',
      );
      log("Final IV Length -> ${aesIv.length} bytes", name: 'VideoPlayerBloc');

      setDecryptionKeys(key: aesKey, iv: aesIv, filePath: event.localFilePath);

      // آدرس فیک با فرمت استاندارد برای فریب مدیاکیت و ریدایرکت به Rust
      final String customUri =
          'safedrm://localhost/bypass_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

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
      log("DRM Stream Error: $e", name: 'VideoPlayerBloc');
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
