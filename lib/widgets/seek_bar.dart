import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/audio_player_provider.dart';

class SeekBarWidget extends StatelessWidget {
  const SeekBarWidget({super.key});

  String _formatDuration(Duration d) {
    int minute = d.inMinutes;
    int second = (d.inSeconds > 60) ? (d.inSeconds % 60) : d.inSeconds;
    String format = "$minute:${(second < 10) ? "0$second" : "$second"}";
    return format;
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioPlayerProvider>(
      context,
      listen: false,
    );

    return StreamBuilder<Duration?>(
      stream: audioProvider.audioPlayer.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: audioProvider.audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            var position = positionSnapshot.data ?? Duration.zero;
            if (position > duration) {
              position = duration;
            }
            return Column(
              children: [
                Slider(
                  value: position.inSeconds.toDouble(),
                  max: duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    audioProvider.audioPlayer.seek(
                      Duration(seconds: value.toInt()),
                    );
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
