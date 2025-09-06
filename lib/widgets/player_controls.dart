import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (_, audioProvider, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.skip_previous, color: Colors.white, size: 36),
              onPressed: () {
                // We'll implement this logic later
              },
            ),
            IconButton(
              icon: Icon(
                audioProvider.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: Colors.white,
                size: 72,
              ),
              onPressed: () {
                if (audioProvider.isPlaying) {
                  audioProvider.pause();
                } else {
                  audioProvider.resume();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.skip_next, color: Colors.white, size: 36),
              onPressed: () {
                // We'll implement this logic later
              },
            ),
          ],
        );
      },
    );
  }
}
