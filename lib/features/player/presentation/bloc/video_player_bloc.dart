import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
// استفاده از ایمپورت پکیجی برای جلوگیری از گم شدن مسیر فایل‌های راست
import 'package:secure_player/src/rust/api/simple.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart' as di;
import 'video_player_event.dart';
import 'video_player_state.dart';

class VideoPlayerBloc extends Bloc<VideoPlayerEvent, VideoPlayerState> {
  final ApiClient apiClient = di.sl<ApiClient>();

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
      print("Fetching Decryption Keys...");

      final responseData = await apiClient.fetchVideoKeys(
        event.courseId,
        event.licenseKey,
      );

      final aesKey = base64Decode(responseData['aes_key']);
      final aesIv = base64Decode(responseData['aes_iv']);

      // تزریق کلیدها مستقیماً به حافظه انجین
      setDecryptionKeys(key: aesKey, iv: aesIv);

      // استفاده از مسیر داینامیکی که انجین سرچ پیدا کرده بود
      final String customUri = 'safedrm://${event.localFilePath}';

      print("Ready to stream from memory: $customUri");

      emit(
        const VideoPlayerReady(
          isPlaying: false,
          currentPosition: Duration.zero,
          totalDuration: Duration(minutes: 45, seconds: 30),
          isMuted: false,
        ),
      );
    } catch (e) {
      print("Error: $e");
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
