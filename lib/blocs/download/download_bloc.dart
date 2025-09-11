// lib/blocs/download/download_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/song.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' as foundation;

part 'download_event.dart';
part 'download_state.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded }

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  final DatabaseService databaseService;
  final ApiService apiService;
  final Dio dio;

  DownloadBloc({required this.databaseService})
    : apiService = ApiService(),
      dio = Dio(),
      super(const DownloadState()) {
    on<LoadDownloadedSongs>(_onLoadDownloadedSongs);
    on<DownloadSong>(_onDownloadSong);
    on<DeleteSong>(_onDeleteSong);
    // Register the handler for the internal progress update event
    // Ensure the event type matches exactly.
    on<_UpdateDownloadProgress>(
      _onUpdateDownloadProgress,
    ); // <-- Correct registration
    add(LoadDownloadedSongs()); // Load initial data
  }

  void _onLoadDownloadedSongs(
    LoadDownloadedSongs event,
    Emitter<DownloadState> emit,
  ) async {
    try {
      final songs = databaseService.getDownloadedSongs();
      final status = <String, DownloadStatus>{};
      final progress = <String, double>{};
      for (var song in songs) {
        status[song.id] = DownloadStatus.downloaded;
        progress[song.id] = 1.0;
      }
      emit(
        state.copyWith(
          downloadedSongs: songs,
          downloadStatus: status,
          downloadProgress: progress,
          activeDownloadSongs: const [],
        ),
      );
    } catch (e) {
      foundation.debugPrint("Error loading downloaded songs: $e");
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onDownloadSong(DownloadSong event, Emitter<DownloadState> emit) async {
    final song = event.song;
    final songId = song.id;

    // Check if already downloading
    if (state.downloadStatus[songId] == DownloadStatus.downloading) {
      foundation.debugPrint("Song $songId is already being cached.");
      return;
    }

    // Check if already downloaded and file exists
    if (state.downloadStatus[songId] == DownloadStatus.downloaded) {
      final existingSong = databaseService.getSong(songId);
      if (existingSong?.filePath != null &&
          File(existingSong!.filePath!).existsSync()) {
        foundation.debugPrint(
          "Song $songId is already cached and file exists.",
        );
        // Ensure it's not in active downloads anymore (sanity check)
        // We need to emit a new state to remove it from active list if needed
        if (state.activeDownloadSongs.any((s) => s.id == songId)) {
          final updatedActiveDownloads = List<Song>.from(
            state.activeDownloadSongs,
          )..removeWhere((s) => s.id == songId);
          emit(state.copyWith(activeDownloadSongs: updatedActiveDownloads));
        }
        return;
      } else {
        foundation.debugPrint(
          "Song $songId marked as downloaded but file missing. Re-caching...",
        );
        // Proceed to re-download, status will be set below
      }
    }

    // --- Update state to 'downloading' and add to active list ---
    final updatedStatus = Map<String, DownloadStatus>.from(
      state.downloadStatus,
    );
    updatedStatus[songId] = DownloadStatus.downloading;

    final updatedProgress = Map<String, double>.from(state.downloadProgress);
    updatedProgress[songId] = 0.0;

    final updatedActiveDownloads = List<Song>.from(state.activeDownloadSongs);
    if (!updatedActiveDownloads.any((s) => s.id == songId)) {
      updatedActiveDownloads.add(song);
    }

    emit(
      state.copyWith(
        downloadStatus: updatedStatus,
        downloadProgress: updatedProgress,
        activeDownloadSongs: updatedActiveDownloads,
      ),
    );

    String? filePath;
    try {
      final audioUrl = await apiService.getAudioUrl(songId);
      final directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$songId.m4a';
      final file = File(filePath);

      if (await file.exists()) {
        await file.delete();
        foundation.debugPrint("Deleted existing incomplete file: $filePath");
      }

      await dio.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progressValue = received / total;
            // Dispatch internal event to update progress
            // Make sure the event type matches the one registered.
            add(
              _UpdateDownloadProgress(songId: songId, progress: progressValue),
            ); // <-- Dispatch event
          }
        },
      );

      final updatedSong = song.copyWith(filePath: filePath);
      await databaseService.addSong(updatedSong);

      // --- Update state on success ---
      final finalStatus = Map<String, DownloadStatus>.from(
        state.downloadStatus,
      );
      finalStatus[songId] = DownloadStatus.downloaded;

      final finalProgress = Map<String, double>.from(state.downloadProgress);
      finalProgress[songId] = 1.0;

      final finalActiveDownloads = List<Song>.from(state.activeDownloadSongs)
        ..removeWhere((s) => s.id == songId);
      final updatedDownloadedSongs = List<Song>.from(state.downloadedSongs)
        ..add(updatedSong);

      emit(
        state.copyWith(
          downloadedSongs: updatedDownloadedSongs,
          downloadStatus: finalStatus,
          downloadProgress: finalProgress,
          activeDownloadSongs: finalActiveDownloads,
        ),
      );
      foundation.debugPrint("Song $songId downloaded and cached successfully.");
    } catch (e) {
      foundation.debugPrint("Error during download for $songId: $e");
      // --- Update state on failure ---
      final errorStatus = Map<String, DownloadStatus>.from(
        state.downloadStatus,
      );
      errorStatus[songId] = DownloadStatus.notDownloaded;

      final errorProgress = Map<String, double>.from(state.downloadProgress)
        ..remove(songId);
      final errorActiveDownloads = List<Song>.from(state.activeDownloadSongs)
        ..removeWhere((s) => s.id == songId);

      emit(
        state.copyWith(
          downloadStatus: errorStatus,
          downloadProgress: errorProgress,
          activeDownloadSongs: errorActiveDownloads,
        ),
      );

      if (filePath != null) {
        try {
          final tempFile = File(filePath);
          if (await tempFile.exists()) {
            await tempFile.delete();
            foundation.debugPrint(
              "Deleted partially downloaded file for $songId due to error: $filePath",
            );
          }
        } catch (deleteError) {
          foundation.debugPrint(
            "Error deleting partial file for $songId: $deleteError",
          );
        }
      }
    }
  }

  // Handler for internal progress update event
  // Ensure signature matches: void Function(EventType event, Emitter<StateType> emit)
  void _onUpdateDownloadProgress(
    _UpdateDownloadProgress event,
    Emitter<DownloadState> emit,
  ) {
    final songId = event.songId;
    final progress = event.progress;

    // Update progress in the copy
    final currentProgress = Map<String, double>.from(state.downloadProgress);
    currentProgress[songId] = progress;

    // Update state with new progress map
    emit(state.copyWith(downloadProgress: currentProgress));
  }

  void _onDeleteSong(DeleteSong event, Emitter<DownloadState> emit) async {
    final song = event.song;
    final songId = song.id;
    final filePath = song.filePath;
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          foundation.debugPrint("Deleted cached file: $filePath");
        }
      } catch (e) {
        foundation.debugPrint("Error deleting file $filePath: $e");
      }
    }

    await databaseService.deleteSong(songId);

    final deleteStatus = Map<String, DownloadStatus>.from(state.downloadStatus)
      ..remove(songId);
    final deleteProgress = Map<String, double>.from(state.downloadProgress)
      ..remove(songId);
    final deleteActiveDownloads = List<Song>.from(state.activeDownloadSongs)
      ..removeWhere((s) => s.id == songId);
    final deleteDownloadedSongs = List<Song>.from(state.downloadedSongs)
      ..removeWhere((s) => s.id == songId);

    emit(
      state.copyWith(
        downloadedSongs: deleteDownloadedSongs,
        downloadStatus: deleteStatus,
        downloadProgress: deleteProgress,
        activeDownloadSongs: deleteActiveDownloads,
      ),
    );
    foundation.debugPrint(
      "Song $songId removed from database and cache tracking.",
    );
  }

  @override
  Future<void> close() {
    apiService.dispose();
    dio.close(); // Dio close might not need force anymore?
    return super.close();
  }
}
