import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/audio_player_provider.dart';
import '../screens/player_screen.dart'; // Import the new screen

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(context);

    if (audioProvider.currentSong == null) {
      return SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => PlayerScreen()));
      },
      child: Container(
        color: Colors.grey[800],
        child: ListTile(
          leading: CachedNetworkImage(
            imageUrl: audioProvider.currentSong!.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(
            audioProvider.currentSong!.title,
            style: TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            audioProvider.currentSong!.artist,
            style: TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              audioProvider.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else {
                audioProvider.resume();
              }
            },
          ),
        ),
      ),
    );
  }
}
