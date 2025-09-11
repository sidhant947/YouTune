// lib/widgets/seek_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BLoC
import '../blocs/audio_player/audio_player_bloc.dart'; // Import BLoC

class SeekBarWidget extends StatelessWidget {
  const SeekBarWidget({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
    }
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to rebuild when AudioPlayerState changes
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        final position = state.position;
        final duration = state.duration;
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.0,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 7.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 15.0,
                ),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(
                  0.3,
                ), // <-- Fixed: withValues -> withOpacity
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(
                  0.2,
                ), // <-- Fixed: withValues -> withOpacity
              ),
              child: Slider(
                value: position.inSeconds.toDouble().clamp(
                  0.0,
                  duration.inSeconds.toDouble().isFinite
                      ? duration.inSeconds.toDouble()
                      : 1.0,
                ),
                max: duration.inSeconds.toDouble() > 0
                    ? duration.inSeconds.toDouble()
                    : 1.0,
                onChanged: (value) {
                  // Dispatch event to seek
                  context.read<AudioPlayerBloc>().add(
                    SeekSong(Duration(seconds: value.toInt())),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      color: Colors.white.withOpacity(
                        0.7,
                      ), // <-- Fixed: withValues -> withOpacity
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      color: Colors.white.withOpacity(
                        0.7,
                      ), // <-- Fixed: withValues -> withOpacity
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
