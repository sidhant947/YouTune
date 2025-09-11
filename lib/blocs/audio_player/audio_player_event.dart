// lib/blocs/audio_player/audio_player_event.dart
part of 'audio_player_bloc.dart';

abstract class AudioPlayerEvent extends Equatable {
  const AudioPlayerEvent();

  @override
  List<Object?> get props => [];
}

class PlaySong extends AudioPlayerEvent {
  final Song song;
  final bool addToQueue;
  final bool queueAllDownloaded;

  const PlaySong(
    this.song, {
    this.addToQueue = true,
    this.queueAllDownloaded = false,
  });

  @override
  List<Object?> get props => [song, addToQueue, queueAllDownloaded];
}

class PauseSong extends AudioPlayerEvent {}

class ResumeSong extends AudioPlayerEvent {}

class SeekSong extends AudioPlayerEvent {
  final Duration position;

  const SeekSong(this.position);

  @override
  List<Object?> get props => [position];
}

class PlayNext extends AudioPlayerEvent {}

class PlayPrevious extends AudioPlayerEvent {}

class AddToQueue extends AudioPlayerEvent {
  final Song song;

  const AddToQueue(this.song);

  @override
  List<Object?> get props => [song];
}

class AddMultipleToQueue extends AudioPlayerEvent {
  final List<Song> songs;

  const AddMultipleToQueue(this.songs);

  @override
  List<Object?> get props => [songs];
}

class RemoveFromQueue extends AudioPlayerEvent {
  final int index;

  const RemoveFromQueue(this.index);

  @override
  List<Object?> get props => [index];
}

class ClearQueue extends AudioPlayerEvent {}

class ShuffleQueue extends AudioPlayerEvent {}

// Internal events for state updates from AudioPlayer callbacks
class _UpdatePosition extends AudioPlayerEvent {
  final Duration position;

  const _UpdatePosition(this.position);

  @override
  List<Object?> get props => [position];
}

class _UpdateDuration extends AudioPlayerEvent {
  final Duration duration;

  const _UpdateDuration(this.duration);

  @override
  List<Object?> get props => [duration];
}

class _UpdateIsPlaying extends AudioPlayerEvent {
  final bool isPlaying;

  const _UpdateIsPlaying(this.isPlaying);

  @override
  List<Object?> get props => [isPlaying];
}

class _UpdateIsLoadingQueue extends AudioPlayerEvent {
  final bool isLoading;

  const _UpdateIsLoadingQueue(this.isLoading);

  @override
  List<Object?> get props => [isLoading];
}

class _UpdateIsPreparing extends AudioPlayerEvent {
  final bool isPreparing;

  const _UpdateIsPreparing(this.isPreparing);

  @override
  List<Object?> get props => [isPreparing];
}
