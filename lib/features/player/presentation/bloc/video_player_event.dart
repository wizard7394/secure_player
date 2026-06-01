import 'package:equatable/equatable.dart';

abstract class VideoPlayerEvent extends Equatable {
  const VideoPlayerEvent();

  @override
  List<Object?> get props => [];
}

class InitializeVideo extends VideoPlayerEvent {
  const InitializeVideo();

  @override
  List<Object> get props => [];
}

class PlayVideo extends VideoPlayerEvent {
  const PlayVideo();
}

class PauseVideo extends VideoPlayerEvent {
  const PauseVideo();
}

class SeekVideo extends VideoPlayerEvent {
  final Duration position;
  const SeekVideo(this.position);

  @override
  List<Object?> get props => [position];
}

class ToggleMute extends VideoPlayerEvent {
  const ToggleMute();
}
