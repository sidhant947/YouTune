// lib/blocs/download/download_state.dart
part of 'download_bloc.dart';

class DownloadState extends Equatable {
  final List<Song> downloadedSongs;
  final Map<String, DownloadStatus> downloadStatus;
  final Map<String, double> downloadProgress;
  final List<Song> activeDownloadSongs;
  final String? error;

  const DownloadState({
    this.downloadedSongs = const [],
    this.downloadStatus = const {},
    this.downloadProgress = const {},
    this.activeDownloadSongs = const [],
    this.error,
  });

  DownloadState copyWith({
    List<Song>? downloadedSongs,
    Map<String, DownloadStatus>? downloadStatus,
    Map<String, double>? downloadProgress,
    List<Song>? activeDownloadSongs,
    String? error,
  }) {
    return DownloadState(
      downloadedSongs: downloadedSongs ?? this.downloadedSongs,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      activeDownloadSongs: activeDownloadSongs ?? this.activeDownloadSongs,
      error: error,
    );
  }

  List<Song> getAllDisplayableSongs() {
    final allSongsSet = <String, Song>{};
    for (var song in activeDownloadSongs) {
      if (!allSongsSet.containsKey(song.id)) {
        allSongsSet[song.id] = song;
      }
    }
    for (var song in downloadedSongs) {
      allSongsSet[song.id] = song;
    }
    return allSongsSet.values.toList();
  }

  bool isSongDownloaded(String songId) {
    return downloadStatus[songId] == DownloadStatus.downloaded;
  }

  @override
  List<Object?> get props => [
    downloadedSongs,
    downloadStatus,
    downloadProgress,
    activeDownloadSongs,
    error,
  ];
}
