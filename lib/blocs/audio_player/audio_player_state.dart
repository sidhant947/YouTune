// lib/blocs/audio_player/audio_player_state.dart
part of 'audio_player_bloc.dart';

class AudioPlayerState extends Equatable {
  final Song? currentSong;
  final bool isPlaying;
  final List<Song> queue;
  final int currentIndex;
  final bool isLoadingQueue;
  final bool isPreparing;
  final Duration duration;
  final Duration position;

  const AudioPlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.queue = const [],
    this.currentIndex = 0,
    this.isLoadingQueue = false,
    this.isPreparing = false,
    this.duration = Duration.zero,
    this.position = Duration.zero,
  });

  AudioPlayerState copyWith({
    Song? currentSong,
    bool? isPlaying,
    List<Song>? queue,
    int? currentIndex,
    bool? isLoadingQueue,
    bool? isPreparing,
    Duration? duration,
    Duration? position,
  }) {
    return AudioPlayerState(
      currentSong: currentSong ?? this.currentSong,
      isPlaying: isPlaying ?? this.isPlaying,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoadingQueue: isLoadingQueue ?? this.isLoadingQueue,
      isPreparing: isPreparing ?? this.isPreparing,
      duration: duration ?? this.duration,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props => [
    currentSong,
    isPlaying,
    queue,
    currentIndex,
    isLoadingQueue,
    isPreparing,
    duration,
    position,
  ];
}
