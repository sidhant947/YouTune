import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

class ApiService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<Song>> searchSongs(String query) async {
    try {
      var searchResult = await _yt.search.search(query);
      List<Song> songs = [];
      for (var video in searchResult) {
        songs.add(
          Song(
            id: video.id.value,
            title: video.title,
            artist: video.author,
            imageUrl: video.thumbnails.mediumResUrl,
            duration: video.duration ?? Duration.zero,
          ),
        );
      }
      return songs;
    } catch (e) {
      print('Error searching songs: $e');
      return [];
    }
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
  }
}
