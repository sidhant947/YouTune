import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';

class DatabaseService {
  static const String songsBoxName = 'songs';

  // Initialize Hive and open boxes.
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SongAdapter());
    await Hive.openBox<Song>(songsBoxName);
  }

  Box<Song> get songsBox => Hive.box<Song>(songsBoxName);

  // Add or update a song in the database.
  Future<void> addSong(Song song) async {
    await songsBox.put(song.id, song);
  }

  // Get a list of all downloaded songs.
  List<Song> getDownloadedSongs() {
    return songsBox.values.toList();
  }

  // Get a single song by its ID.
  Song? getSong(String songId) {
    return songsBox.get(songId);
  }

  // Delete a song from the database.
  Future<void> deleteSong(String songId) async {
    await songsBox.delete(songId);
  }
}
