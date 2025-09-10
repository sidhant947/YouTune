// lib/models/song.dart
import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String? album;

  @HiveField(4)
  final String imageUrl;

  @HiveField(5)
  String? filePath;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    required this.imageUrl,
    this.filePath,
  });

  // Add copyWith method for easier manipulation
  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? imageUrl,
    String? filePath,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      imageUrl: imageUrl ?? this.imageUrl,
      filePath: filePath ?? this.filePath,
    );
  }

  static Song? fromYouTubeMusicJson(Map<String, dynamic> json) {
    try {
      final videoId =
          json['flexColumns'][0]['musicResponsiveListItemFlexColumnRenderer']['text']['runs'][0]['navigationEndpoint']?['watchEndpoint']?['videoId']
              as String?;

      if (videoId == null) {
        return null;
      }

      final title =
          (json['flexColumns'][0]['musicResponsiveListItemFlexColumnRenderer']['text']?['runs']
                  as List?)
              ?.map((r) => r['text'])
              .join() ??
          'Untitled';

      final allArtistInfoRuns =
          json['flexColumns'][1]['musicResponsiveListItemFlexColumnRenderer']['text']?['runs']
              as List?;
      final allArtistInfoText =
          allArtistInfoRuns?.map((r) => r['text']).join() ?? '';

      final infoParts = allArtistInfoText.split(' • ');

      final artist = infoParts.isNotEmpty
          ? infoParts[0].trim()
          : 'Unknown Artist';
      final album = infoParts.length > 1 ? infoParts[1].trim() : null;

      final thumbnails =
          json['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
              as List?;

      // **FIX:** Modify the URL to request a high-resolution image.
      String imageUrl = '';
      if (thumbnails != null && thumbnails.isNotEmpty) {
        // Start with the URL provided by the API (usually the last one is best).
        final baseImageUrl = thumbnails.last['url'] as String? ?? '';

        // Google content URLs can be modified to request a different size.
        if (baseImageUrl.contains('googleusercontent.com')) {
          // We replace the size parameter (e.g., "=w120-h120") with a larger one.
          final urlParts = baseImageUrl.split('=');
          if (urlParts.length > 1) {
            // Request a 600x600 pixel image for high quality.
            imageUrl = '${urlParts[0]}=w600-h600-l90-rj';
          } else {
            imageUrl = baseImageUrl;
          }
        } else {
          imageUrl = baseImageUrl;
        }
      }

      return Song(
        id: videoId,
        title: title.isNotEmpty ? title : 'Untitled',
        artist: artist,
        album: album,
        imageUrl: imageUrl,
      );
    } catch (e) {
      // print("Error parsing song from JSON. Corrupted data: $e");
      return null;
    }
  }
}
