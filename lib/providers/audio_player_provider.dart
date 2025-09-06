import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart'; // Import the database helper

class AudioPlayerProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper =
      DatabaseHelper(); // Add database helper instance
  Song? _currentSong;
  bool _isPlaying = false;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  AudioPlayer get audioPlayer => _audioPlayer;

  Future<void> play(Song song) async {
    if (_currentSong?.id == song.id) {
      if (_isPlaying) {
        pause();
      } else {
        resume();
      }
      return;
    }

    _currentSong = song;
    notifyListeners();

    try {
      // Check for a local file first
      final downloadedSongs = await _dbHelper.getDownloadedFilePaths();
      final localPath = downloadedSongs[song.id];

      if (localPath != null && await File(localPath).exists()) {
        print("Playing from local file: $localPath");
        await _audioPlayer.setFilePath(localPath);
      } else {
        print("Streaming from network...");
        final audioUrl = await _apiService.getAudioUrl(song.id);
        await _audioPlayer.setUrl(audioUrl);
      }

      _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      print("Error playing song: $e");
      _isPlaying = false;
    }

    notifyListeners();

    _audioPlayer.playingStream.listen((playing) {
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });
  }

  void pause() {
    _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    _audioPlayer.play();
    _isPlaying = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _apiService.dispose();
    super.dispose();
  }
}
