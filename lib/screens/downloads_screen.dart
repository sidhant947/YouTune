import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/database_helper.dart';
import '../widgets/song_list_item.dart';
import '../providers/audio_player_provider.dart';
import '../providers/download_provider.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<Song>> _downloadedSongs;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() {
    setState(() {
      _downloadedSongs = _dbHelper.getDownloadedSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to DownloadProvider to refresh when a song is deleted
    Provider.of<DownloadProvider>(context);

    return FutureBuilder<List<Song>>(
      future: _downloadedSongs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No downloaded songs.'));
        } else {
          final songs = snapshot.data!;
          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return Dismissible(
                key: Key(song.id),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  Provider.of<DownloadProvider>(
                    context,
                    listen: false,
                  ).deleteSong(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${song.title} removed from downloads"),
                    ),
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: SongListItem(
                  song: song,
                  onTap: () {
                    Provider.of<AudioPlayerProvider>(
                      context,
                      listen: false,
                    ).play(song);
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
}
