import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded }

class DownloadProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Dio _dio = Dio();

  Map<String, DownloadStatus> _downloadStatus = {};
  final Map<String, double> _downloadProgress = {};
  Map<String, String> _downloadedFilePaths = {};

  DownloadProvider() {
    _fetchDownloadedSongs();
  }

  DownloadStatus getStatus(String songId) =>
      _downloadStatus[songId] ?? DownloadStatus.notDownloaded;
  double getProgress(String songId) => _downloadProgress[songId] ?? 0.0;

  Future<void> _fetchDownloadedSongs() async {
    _downloadedFilePaths = await _dbHelper.getDownloadedFilePaths();
    _downloadStatus = {
      for (var id in _downloadedFilePaths.keys) id: DownloadStatus.downloaded,
    };
    notifyListeners();
  }

  Future<void> downloadSong(Song song) async {
    if (getStatus(song.id) != DownloadStatus.notDownloaded) return;

    _downloadStatus[song.id] = DownloadStatus.downloading;
    _downloadProgress[song.id] = 0.0;
    notifyListeners();

    try {
      final audioUrl = await _apiService.getAudioUrl(song.id);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${song.id}.mp3';

      await _dio.download(
        audioUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress[song.id] = received / total;
            notifyListeners();
          }
        },
      );

      await _dbHelper.insertSong(song, filePath);
      _downloadedFilePaths[song.id] = filePath;
      _downloadStatus[song.id] = DownloadStatus.downloaded;
    } catch (e) {
      _downloadStatus[song.id] = DownloadStatus.notDownloaded;
      print("Download failed: $e");
    } finally {
      _downloadProgress.remove(song.id);
      notifyListeners();
    }
  }

  Future<void> deleteSong(Song song) async {
    final filePath = _downloadedFilePaths[song.id];
    if (filePath != null) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        await _dbHelper.deleteSong(song.id);
        _downloadedFilePaths.remove(song.id);
        _downloadStatus.remove(song.id);
        notifyListeners();
      } catch (e) {
        print("Error deleting song: $e");
      }
    }
  }
}
