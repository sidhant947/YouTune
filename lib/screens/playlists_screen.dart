import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/database_helper.dart';
import 'playlist_detail_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  _PlaylistsScreenState createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<Playlist>> _playlists;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlists = _dbHelper.getPlaylists();
    });
  }

  void _createPlaylist() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Playlist'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "Playlist Name"),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Create'),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _dbHelper.createPlaylist(controller.text);
                _loadPlaylists();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Playlist>>(
        future: _playlists,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No playlists yet.'));
          } else {
            final playlists = snapshot.data!;
            return ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return ListTile(
                  leading: Icon(Icons.music_note),
                  title: Text(playlist.name),
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PlaylistDetailScreen(playlist: playlist),
                          ),
                        )
                        .then((_) => _loadPlaylists());
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        child: Icon(Icons.add),
      ),
    );
  }
}
