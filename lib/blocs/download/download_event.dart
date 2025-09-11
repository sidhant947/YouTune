// lib/blocs/download/download_event.dart
part of 'download_bloc.dart';

abstract class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

class LoadDownloadedSongs extends DownloadEvent {}

class DownloadSong extends DownloadEvent {
  final Song song;

  const DownloadSong(this.song);

  @override
  List<Object?> get props => [song];
}

class DeleteSong extends DownloadEvent {
  final Song song;

  const DeleteSong(this.song);

  @override
  List<Object?> get props => [song];
}

// Internal event for progress updates - MUST be public for Bloc to register it
// Even though it's intended for internal use, Bloc requires it to be accessible.
class _UpdateDownloadProgress extends DownloadEvent {
  // <-- Remove 'const' if it was there
  final String songId;
  final double progress;

  const _UpdateDownloadProgress({
    required this.songId,
    required this.progress,
  }); // <-- Remove 'const' if it was there

  @override
  List<Object?> get props => [songId, progress];
}
