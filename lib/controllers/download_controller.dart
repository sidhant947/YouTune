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
    }
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
    // Prevent redundant downloads/caching attempts
    // Allow re-download if it failed before (notDownloaded) or if it's not currently downloading
    if (downloadStatus[song.id] == DownloadStatus.downloading) {
      debugPrint("Song ${song.id} is already being cached.");
      return; // Already downloading, don't start again
    }
    if (downloadStatus[song.id] == DownloadStatus.downloaded) {
      // Check if the file actually exists
      final existingSong = _dbService.getSong(song.id);
      if (existingSong?.filePath != null &&
          File(existingSong!.filePath!).existsSync()) {
        debugPrint("Song ${song.id} is already cached and file exists.");
        return; // Already downloaded and file exists
      } else {
        // File is missing, allow re-download
        debugPrint(
          "Song ${song.id} marked as downloaded but file missing. Re-caching...",
        );
      }
    }
    downloadStatus[song.id] = DownloadStatus.downloading;
    downloadProgress[song.id] = 0.0;
    try {
      final audioUrl = await _apiService.getAudioUrl(song.id);
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/${song.id}.m4a'; // Using m4a as it's common
      // Check if file already exists locally (from a previous incomplete attempt)
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete(); // Delete potentially corrupted/incomplete file
        debugPrint("Deleted existing incomplete file: $filePath");
      }
      await _dio.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress[song.id] = received / total;
            // Optional: Print progress for debugging
            // debugPrint("Download progress for ${song.id}: ${downloadProgress[song.id]}");
          }
        },
      );
      // Update song object with the local file path and save to DB
      // Create a copy to avoid modifying the original song object directly if it's from the queue
      final updatedSong = song.copyWith(filePath: filePath);
      await _dbService.addSong(updatedSong);
      downloadStatus[song.id] = DownloadStatus.downloaded;
      _fetchDownloadedSongs(); // Refresh the list of downloaded songs
      debugPrint("Song ${song.id} downloaded and cached successfully.");
    } catch (e) {
      downloadStatus[song.id] = DownloadStatus.notDownloaded; // Mark as failed
      downloadProgress.remove(song.id); // Clean up progress on error
      debugPrint("Download failed for ${song.id}: $e");
      // Re-throw the error so the caller knows it failed
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
    downloadProgress.remove(song.id); // Ensure progress is also removed
    _fetchDownloadedSongs(); // Refresh the list
    debugPrint("Song ${song.id} removed from database and cache tracking.");
  }

  @override
  void onClose() {
    _apiService.dispose();
    _dio.close(); // Close Dio instance
    super.onClose();
  }
}
