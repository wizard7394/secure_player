import 'package:equatable/equatable.dart';

abstract class VideoPlayerState extends Equatable {
  const VideoPlayerState();

  @override
  List<Object?> get props => [];
}

class VideoPlayerInitial extends VideoPlayerState {
  const VideoPlayerInitial();
}

class VideoPlayerLoading extends VideoPlayerState {
  const VideoPlayerLoading();
}

class VideoPlayerReady extends VideoPlayerState {
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isMuted;
  final String customUri;

  const VideoPlayerReady({
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    required this.isMuted,
    required this.customUri,
  });

  VideoPlayerReady copyWith({
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isMuted,
    String? customUri,
  }) {
    return VideoPlayerReady(
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isMuted: isMuted ?? this.isMuted,
      customUri: customUri ?? this.customUri,
    );
  }

  @override
  List<Object?> get props => [
    isPlaying,
    currentPosition,
    totalDuration,
    isMuted,
    customUri,
  ];
}
