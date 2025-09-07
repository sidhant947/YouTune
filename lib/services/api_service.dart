import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:json_path/json_path.dart';
import '../models/song.dart';

class ApiService {
  final YoutubeExplode _yt = YoutubeExplode();
  final http.Client _httpClient = http.Client();

  // This is the internal API endpoint YouTube Music uses.
  static const String _searchUrl =
      'https://music.youtube.com/youtubei/v1/search';

  // This is a public key used by YouTube Music web client.
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

  // This "context" tells the API that we are a web client,
  // ensuring we get music-focused results.
  final Map<String, dynamic> _clientContext = {
    'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.20240524.01.00'},
  };

  Future<List<Song>> searchSongs(String query) async {
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
        return _parseSearchResponse(data);
      } else {
        throw Exception('Failed to search songs');
      }
    } catch (e) {
      print("Error in searchSongs: $e");
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
      // THE FIX IS HERE: We cast match.value to the correct type.
      final song = Song.fromYouTubeMusicJson(
        match.value as Map<String, dynamic>,
      );
      if (song != null) {
        songs.add(song);
      }
    }
    return songs;
  }

  Future<String> getAudioUrl(String videoId) async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var streamInfo = manifest.audioOnly.withHighestBitrate();
      return streamInfo.url.toString();
    } catch (e) {
      print('Error getting audio URL: $e');
      rethrow;
    }
  }

  void dispose() {
    _yt.close();
    _httpClient.close();
  }
}
