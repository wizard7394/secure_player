import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  List<int> _parseKey(String input) {
    input = input.trim().replaceAll('"', '');

    // تشخیص هگزادسیمال
    final hexRegex = RegExp(r'^[0-9a-fA-F]+$');
    if (input.length % 2 == 0 && hexRegex.hasMatch(input)) {
      List<int> bytes = [];
      for (int i = 0; i < input.length; i += 2) {
        bytes.add(int.parse(input.substring(i, i + 2), radix: 16));
      }
      return bytes;
    }

    // تشخیص IV خام 16 بایتی (UTF-8)
    if (input.length == 16 && !input.contains('=')) {
      return utf8.encode(input);
    }

    // در غیر این صورت Base64
    try {
      return base64Decode(input);
    } catch (e) {
      return utf8.encode(input); // فال‌بک نهایی
    }
  }

  void _onInitializeVideo(
    InitializeVideo event,
    Emitter<VideoPlayerState> emit,
  ) async {
    emit(const VideoPlayerLoading());

    try {
      final responseData = await apiClient.fetchVideoKeys(
        event.courseId,
        event.videoId,
        event.licenseKey,
      );

      final aesKey = _parseKey(responseData['aes_key']);
      final aesIv = _parseKey(responseData['aes_iv']);

      print("DEBUG: Final Key Length -> ${aesKey.length} bytes");
      print("DEBUG: Final IV Length -> ${aesIv.length} bytes");

      setDecryptionKeys(key: aesKey, iv: aesIv, filePath: event.localFilePath);

      final String customUri =
          'safedrm://bypass_${DateTime.now().millisecondsSinceEpoch}';

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
