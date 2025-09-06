import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import '../providers/download_provider.dart';
import '../services/database_helper.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongListItem({super.key, required this.song, required this.onTap});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _showAddToPlaylistDialog(BuildContext context, Song song) async {
    final dbHelper = DatabaseHelper();
    final playlists = await dbHelper.getPlaylists();

    showDialog(
      context: context,
      builder: (context) {
        if (playlists.isEmpty) {
          return AlertDialog(
            title: Text('Add to Playlist'),
            content: Text('You haven\'t created any playlists yet.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        }
        return SimpleDialog(
          title: Text('Add to Playlist'),
          children: playlists.map((playlist) {
            return SimpleDialogOption(
              onPressed: () {
                dbHelper.addSongToPlaylist(playlist.id!, song);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${song.title} added to ${playlist.name}'),
                  ),
                );
              },
              child: Text(playlist.name),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTrailingWidget(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, child) {
        final status = downloadProvider.getStatus(song.id);

        switch (status) {
          case DownloadStatus.downloading:
            return SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: downloadProvider.getProgress(song.id),
                strokeWidth: 2.0,
              ),
            );
          case DownloadStatus.downloaded:
            return Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            );
          case DownloadStatus.notDownloaded:
          default:
            return IconButton(
              icon: Icon(Icons.download),
              onPressed: () {
                downloadProvider.downloadSong(song);
              },
            );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: song.imageUrl,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_formatDuration(song.duration)),
          SizedBox(width: 8),
          _buildTrailingWidget(context),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              _showAddToPlaylistDialog(context, song);
            },
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
