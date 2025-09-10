// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:json_path/json_path.dart';
import '../models/song.dart';
import 'dart:io';

import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class ApiService {
  final YoutubeExplode _yt = YoutubeExplode();
  // In api_service.dart
  // import 'package:http/io_client.dart'; // Add this import
  // import 'dart:io'; // Add this import

  // final http.Client _httpClient = http.Client(); // Replace this line with:
  final http.Client _httpClient = IOClient(
    HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 10),
  );
  // This is the internal API endpoint YouTube Music uses.
  static const String _searchUrl =
      'https://music.youtube.com/youtubei/v1/search';
  static const String _nextUrl = 'https://music.youtube.com/youtubei/v1/next';
  // This is a public key used by YouTube Music web client.
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
  // This "context" tells the API that we are a web client,
  // ensuring we get music-focused results.
  final Map<String, dynamic> _clientContext = {
    'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.20240524.01.00'},
  };

  Future<List<Song>> searchSongs(String query, {int limit = 20}) async {
    final body = json.encode({
      'context': _clientContext,
      'query': query,
      // This 'params' value specifically asks for songs.
      'params': 'EgWKAQIIAWoOEAMQBBAJEAoQBRAQEBU%3D',
    });
    try {
      final response = await _httpClient.post(
        Uri.parse('$_searchUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final songs = _parseSearchResponse(data);
        return songs.take(limit).toList();
      } else {
        throw Exception('Failed to search songs');
      }
    } catch (e) {
      debugPrint("Error in searchSongs: $e"); // <-- Fixed
      return [];
    }
  }

  Future<List<Song>> getSimilarSongs(String videoId) async {
    final body = json.encode({'context': _clientContext, 'videoId': videoId});
    try {
      final response = await _httpClient.post(
        Uri.parse('$_nextUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseNextResponse(data);
      } else {
        throw Exception('Failed to get similar songs');
      }
    } catch (e) {
      debugPrint("Error in getSimilarSongs: $e"); // <-- Fixed
      return [];
    }
  }

  List<Song> _parseSearchResponse(Map<String, dynamic> data) {
    // This JsonPath expression navigates the complex JSON to find the song list.
    final jsonPath = JsonPath(
      r'$..musicShelfRenderer.contents[*].musicResponsiveListItemRenderer',
    );
    final matches = jsonPath.read(data);
    final List<Song> songs = [];
    for (final match in matches) {
      try {
        final song = Song.fromYouTubeMusicJson(
          match.value as Map<String, dynamic>,
        );
        if (song != null) {
          songs.add(song);
        }
      } catch (e) {
        debugPrint("Error parsing song: $e"); // <-- Fixed
      }
    }
    return songs;
  }

  List<Song> _parseNextResponse(Map<String, dynamic> data) {
    final List<Song> songs = [];
    // Try multiple JSON paths to find related songs
    final jsonPaths = [
      r'$..autoplayEndpoint..musicResponsiveListItemRenderer',
      r'$..itemSectionRenderer.contents[*].musicResponsiveListItemRenderer',
      r'$..musicCarouselShelfRenderer.contents[*].musicResponsiveListItemRenderer',
      r'$..musicTwoRowItemRenderer',
    ];
    for (final path in jsonPaths) {
      try {
        final jsonPath = JsonPath(path);
        final matches = jsonPath.read(data);
        for (final match in matches) {
          try {
            final song = Song.fromYouTubeMusicJson(
              match.value as Map<String, dynamic>,
            );
            if (song != null && !songs.any((s) => s.id == song.id)) {
              songs.add(song);
            }
          } catch (e) {
            debugPrint("Error parsing song from path $path: $e"); // <-- Fixed
          }
        }
      } catch (e) {
        debugPrint("Error with JSON path $path: $e"); // <-- Fixed
      }
    }
    return songs;
  }

  Future<String> getAudioUrl(String videoId) async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      // Fallback to any available audio stream
      // if (streamInfo == null && manifest.audioOnly.isNotEmpty) {
      //   streamInfo = manifest.audioOnly.first;
      // }
      // Fix: Check if streamInfo is not null before accessing its url
      return streamInfo.url.toString();
    } catch (e) {
      debugPrint('Error getting audio URL: $e'); // <-- Fixed
      rethrow;
    }
  }

  void dispose() {
    _yt.close();
    _httpClient.close();
  }
}
