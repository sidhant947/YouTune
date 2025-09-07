import 'dart:io';
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
    _fetchDownloadedSongs();
  }

  void _fetchDownloadedSongs() {
    final songs = _dbService.getDownloadedSongs();
    downloadedSongs.assignAll(songs);
    // Initialize status for all downloaded songs.
    for (var song in songs) {
      downloadStatus[song.id] = DownloadStatus.downloaded;
    }
  }

  Future<void> downloadSong(Song song) async {
    if (downloadStatus[song.id] != null &&
        downloadStatus[song.id] != DownloadStatus.notDownloaded) {
      return;
    }

    downloadStatus[song.id] = DownloadStatus.downloading;
    downloadProgress[song.id] = 0.0;

    try {
      final audioUrl = await _apiService.getAudioUrl(song.id);
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/${song.id}.m4a'; // Using m4a as it's common

      await _dio.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress[song.id] = received / total;
          }
        },
      );

      // Update song object with the local file path and save to DB
      song.filePath = filePath;
      await _dbService.addSong(song);

      downloadStatus[song.id] = DownloadStatus.downloaded;
      _fetchDownloadedSongs(); // Refresh the list of downloaded songs
    } catch (e) {
      downloadStatus[song.id] = DownloadStatus.notDownloaded;
      print("Download failed: $e");
    } finally {
      downloadProgress.remove(song.id);
    }
  }

  Future<void> deleteSong(Song song) async {
    final filePath = song.filePath;
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print("Error deleting file: $e");
      }
    }
    await _dbService.deleteSong(song.id);
    downloadStatus.remove(song.id);
    _fetchDownloadedSongs(); // Refresh the list
  }
}
