// lib/controllers/download_controller.dart
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded }

class DownloadController extends GetxController {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final Dio _dio = Dio();

  // Reactive variables for observing state changes.
  var downloadedSongs = <Song>[].obs;
  var downloadStatus = <String, DownloadStatus>{}.obs;
  var downloadProgress = <String, double>{}.obs;

  // NEW: List to track Song objects currently being downloaded
  var activeDownloadSongs = <Song>[].obs;

  @override
  void onInit() {
    super.onInit();
    _fetchDownloadedSongs(); // Fetch songs on initialization
  }

  // Private method to fetch and update the list of downloaded songs
  void _fetchDownloadedSongs() {
    final songs = _dbService.getDownloadedSongs();
    downloadedSongs.assignAll(songs);
    // Initialize status for all downloaded songs.
    for (var song in songs) {
      downloadStatus[song.id] = DownloadStatus.downloaded;
      // Ensure it's removed from active downloads if it finishes
      activeDownloadSongs.removeWhere((s) => s.id == song.id);
    }
  }

  // NEW: Helper to get combined list of downloaded and active downloading songs
  List<Song> getAllDisplayableSongs() {
    final allSongsSet = <String, Song>{};
    // Add active downloads first
    for (var song in activeDownloadSongs) {
      // Avoid adding if it's somehow already fully downloaded and in downloadedSongs
      if (!allSongsSet.containsKey(song.id)) {
        allSongsSet[song.id] = song;
      }
    }
    // Add downloaded songs (potentially overwriting active ones if they finished quickly)
    for (var song in downloadedSongs) {
      allSongsSet[song.id] = song;
    }
    return allSongsSet.values.toList();
  }

  // Public helper method to check if a song is downloaded/cached
  bool isSongDownloaded(String songId) {
    return downloadStatus[songId] == DownloadStatus.downloaded;
  }

  // Public helper method to get the local file path if cached
  String? getCachedFilePath(String songId) {
    final song = _dbService.getSong(songId);
    return song?.filePath;
  }

  // Make the download method PUBLIC for AudioPlayerController to use
  // Renamed from _downloadSong to downloadSong
  Future<void> downloadSong(Song song) async {
    final songId = song.id;

    // NEW: Add to active downloads list immediately when download is initiated
    if (!activeDownloadSongs.any((s) => s.id == songId)) {
      activeDownloadSongs.add(song);
      // Update status immediately
      downloadStatus[songId] = DownloadStatus.downloading;
      downloadProgress[songId] = 0.0;
    } else if (downloadStatus[songId] == DownloadStatus.downloading) {
      // Already downloading
      debugPrint("Song $songId is already being cached.");
      return;
    }

    // Prevent redundant downloads/caching attempts for fully downloaded files
    if (downloadStatus[songId] == DownloadStatus.downloaded) {
      final existingSong = _dbService.getSong(songId);
      if (existingSong?.filePath != null &&
          File(existingSong!.filePath!).existsSync()) {
        debugPrint("Song $songId is already cached and file exists.");
        // Ensure it's not in active downloads anymore
        activeDownloadSongs.removeWhere((s) => s.id == songId);
        return; // Already downloaded and file exists
      } else {
        debugPrint(
          "Song $songId marked as downloaded but file missing. Re-caching...",
        );
        // Re-add to active downloads if file is missing
        if (!activeDownloadSongs.any((s) => s.id == songId)) {
          activeDownloadSongs.add(song);
        }
        downloadStatus[songId] = DownloadStatus.downloading;
        downloadProgress[songId] = 0.0;
      }
    }

    // If not already handled above, set status to downloading
    // This covers the case where status was 'notDownloaded' or file was missing
    if (downloadStatus[songId] != DownloadStatus.downloading) {
      downloadStatus[songId] = DownloadStatus.downloading;
      downloadProgress[songId] = 0.0;
    }

    String? filePath;
    try {
      final audioUrl = await _apiService.getAudioUrl(songId);
      final directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$songId.m4a';

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint("Deleted existing incomplete file: $filePath");
      }

      await _dio.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress[songId] = received / total;
          }
        },
      );

      final updatedSong = song.copyWith(filePath: filePath);
      await _dbService.addSong(updatedSong);
      downloadStatus[songId] = DownloadStatus.downloaded;
      _fetchDownloadedSongs(); // Refresh the list of downloaded songs
      debugPrint("Song $songId downloaded and cached successfully.");

      // NEW: Remove from active downloads upon successful completion
      activeDownloadSongs.removeWhere((s) => s.id == songId);
    } catch (e) {
      debugPrint("Error during download for $songId: $e");
      downloadStatus[songId] = DownloadStatus.notDownloaded;
      downloadProgress.remove(songId);
      if (filePath != null) {
        try {
          final tempFile = File(filePath);
          if (await tempFile.exists()) {
            await tempFile.delete();
            debugPrint(
              "Deleted partially downloaded file for $songId due to error: $filePath",
            );
          }
        } catch (deleteError) {
          debugPrint("Error deleting partial file for $songId: $deleteError");
        }
      }
      // NEW: Remove from active downloads upon failure
      activeDownloadSongs.removeWhere((s) => s.id == songId);
      rethrow;
    }
  }

  Future<void> deleteSong(Song song) async {
    final filePath = song.filePath;
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint("Deleted cached file: $filePath");
        }
      } catch (e) {
        debugPrint("Error deleting file $filePath: $e");
      }
    }
    await _dbService.deleteSong(song.id);
    downloadStatus.remove(song.id);
    downloadProgress.remove(song.id);
    // NEW: Also remove from active downloads list
    activeDownloadSongs.removeWhere((s) => s.id == song.id);
    _fetchDownloadedSongs();
    debugPrint("Song ${song.id} removed from database and cache tracking.");
  }

  @override
  void onClose() {
    _apiService.dispose();
    _dio.close();
    super.onClose();
  }
}
