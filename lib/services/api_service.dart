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

  // --- New Method for Paginated Search ---
  /// Searches for songs and returns both the songs and the token for the next page.
  ///
  /// [query] The search term.
  /// [limit] The maximum number of songs to return in this call.
  /// [pageToken] The token for the next page of results. If null, fetches the first page.
  ///
  /// Returns a Map containing:
  ///   - 'nextPageToken': String? The token to get the next page, or null if no more pages.
  Future<Map<String, dynamic>> searchSongsPaginated(
    String query, {
    int limit = 20,
    String? pageToken,
  }) async {
    final Map<String, dynamic> requestBody = {
      'context': _clientContext,
      'query': query,
      // This 'params' value specifically asks for songs.
      'params': 'EgWKAQIIAWoOEAMQBBAJEAoQBRAQEBU%3D',
    };

    // Include the pageToken if it's provided for pagination
    if (pageToken != null && pageToken.isNotEmpty) {
      requestBody['continuation'] = pageToken; // Common key for continuation
      // Remove query if continuation is used, as it might not be needed or allowed
      requestBody.remove('query');
    }

    final body = json.encode(requestBody);

    try {
      final response = await _httpClient.post(
        Uri.parse('$_searchUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Extract the next page token from the response
        // This path might need adjustment based on actual API response structure
        String? nextPageToken;
        try {
          // Look for continuation token in various potential locations
          // These paths target the continuation data within the response structure.
          // They use JsonPath to navigate the potentially complex nested JSON.
          final contentsPath = JsonPath(
            r'$..continuationContents..continuations[0]..nextContinuationData.continuation',
          );
          final itemsPath = JsonPath(
            r'$..continuationItems..continuations[0]..nextContinuationData.continuation',
          );

          final contentsMatches = contentsPath.read(data);
          final itemsMatches = itemsPath.read(data);

          // Prefer token from continuationContents if available, otherwise from continuationItems
          nextPageToken = contentsMatches.isNotEmpty
              ? contentsMatches.first.value as String?
              : (itemsMatches.isNotEmpty
                    ? itemsMatches.first.value as String?
                    : null);
        } catch (e) {
          debugPrint("Could not extract nextPageToken using JsonPath: $e");
          // Fallback attempt: Try to find the token in a flatter structure or by key
          // This is less reliable but might work for some responses.
          try {
            // A very generic search, might not be accurate.
            final flatSearch = JsonPath(r'$..continuation..[*]').read(data);
            if (flatSearch.isNotEmpty) {
              // Take the last one found, often the correct one, but not guaranteed.
              nextPageToken = flatSearch.last.value as String?;
              debugPrint("Fallback nextPageToken found: $nextPageToken");
            }
          } catch (fallbackE) {
            debugPrint(
              "Fallback nextPageToken extraction also failed: $fallbackE",
            );
          }
        }

        final songs = _parseSearchResponse(data);
        return {
          'songs': songs.take(limit).toList(),
          'nextPageToken': nextPageToken,
        };
      } else {
        throw Exception(
          'Failed to search songs, status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint("Error in searchSongsPaginated: $e");
      rethrow; // Re-throw to be caught by the caller
    }
  }

  // --- Modified Existing Method ---
  /// Searches for songs (original method, kept for backward compatibility or simple searches).
  ///
  /// [query] The search term.
  /// [limit] The maximum number of songs to return.
  ///
  /// Returns a List of Songs.
  Future<List<Song>> searchSongs(String query, {int limit = 20}) async {
    // Use the new paginated method internally but only return the songs list.
    final result = await searchSongsPaginated(query, limit: limit);
    return result['songs'] as List<Song>;
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
      debugPrint("Error in getSimilarSongs: $e");
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
        debugPrint("Error parsing song: $e");
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
            debugPrint("Error parsing song from path $path: $e");
          }
        }
      } catch (e) {
        debugPrint("Error with JSON path $path: $e");
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
      debugPrint('Error getting audio URL: $e');
      rethrow;
    }
  }

  void dispose() {
    _yt.close();
    _httpClient.close();
  }
}
