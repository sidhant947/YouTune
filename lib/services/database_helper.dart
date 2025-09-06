import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/playlist.dart';
import '../models/song.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'youtune.db');
    return await openDatabase(
      path,
      version: 2, // <--- Increment the version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // <--- Add the upgrade callback
    );
  }

  Future _onCreate(Database db, int version) async {
    // This runs if the database did not exist
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        title TEXT,
        artist TEXT,
        imageUrl TEXT,
        duration INTEGER,
        filePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_songs (
        playlist_id INTEGER,
        song_id TEXT,
        position INTEGER,
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE,
        PRIMARY KEY (playlist_id, song_id)
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // This runs if the database exists but the version is old
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE playlists (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE playlist_songs (
          playlist_id INTEGER,
          song_id TEXT,
          position INTEGER,
          FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
          FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE,
          PRIMARY KEY (playlist_id, song_id)
        )
      ''');
    }
  }

  // --- Song Methods (from before) ---
  Future<void> insertSong(Song song, String filePath) async {
    final db = await database;
    await db.insert('songs', {
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'imageUrl': song.imageUrl,
      'duration': song.duration.inMilliseconds,
      'filePath': filePath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Song>> getDownloadedSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('songs');
    return List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'],
        title: maps[i]['title'],
        artist: maps[i]['artist'],
        imageUrl: maps[i]['imageUrl'],
        duration: Duration(milliseconds: maps[i]['duration']),
      );
    });
  }

  Future<Map<String, String>> getDownloadedFilePaths() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'songs',
      columns: ['id', 'filePath'],
    );
    return {
      for (var map in maps) map['id'] as String: map['filePath'] as String,
    };
  }

  Future<void> deleteSong(String id) async {
    final db = await database;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  // --- Playlist Methods (New) ---

  Future<void> createPlaylist(String name) async {
    final db = await database;
    await db.insert('playlists', {'name': name});
  }

  Future<List<Playlist>> getPlaylists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('playlists');
    return List.generate(maps.length, (i) {
      return Playlist(id: maps[i]['id'], name: maps[i]['name']);
    });
  }

  Future<void> addSongToPlaylist(int playlistId, Song song) async {
    final db = await database;
    // First, ensure the song exists in the main songs table (if it was streamed)
    await db.insert('songs', {
      'id': song.id, 'title': song.title, 'artist': song.artist,
      'imageUrl': song.imageUrl, 'duration': song.duration.inMilliseconds,
      'filePath': null, // File path is null if it's not downloaded
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    // Get the current max position in the playlist
    final result = await db.rawQuery(
      'SELECT MAX(position) as max_pos FROM playlist_songs WHERE playlist_id = ?',
      [playlistId],
    );
    final maxPos = (result.first['max_pos'] as int?) ?? -1;

    // Add the song to the playlist
    await db.insert('playlist_songs', {
      'playlist_id': playlistId,
      'song_id': song.id,
      'position': maxPos + 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Song>> getSongsForPlaylist(int playlistId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT s.* FROM songs s
      INNER JOIN playlist_songs ps ON s.id = ps.song_id
      WHERE ps.playlist_id = ?
      ORDER BY ps.position ASC
    ''',
      [playlistId],
    );

    return List.generate(maps.length, (i) {
      return Song(
        id: maps[i]['id'],
        title: maps[i]['title'],
        artist: maps[i]['artist'],
        imageUrl: maps[i]['imageUrl'],
        duration: Duration(milliseconds: maps[i]['duration']),
      );
    });
  }
}
