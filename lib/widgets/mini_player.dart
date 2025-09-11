// lib/widgets/mini_player.dart
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Removed as per previous instruction
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BLoC
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/audio_player/audio_player_bloc.dart'; // Import BLoC
import '../screens/player_screen.dart';
import 'glassmorphic_container.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to rebuild when AudioPlayerState changes
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        final song = state.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }
        return GlassmorphicContainer(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: GestureDetector(
            onTap: () {
              // Use standard Navigator
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen()),
              );
            },
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: song.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(
                            0.7,
                          ), // <-- Fixed: withValues -> withOpacity
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Play/Pause Button with Loading Indicator
                // Wrap the button in BlocBuilder to listen to isPreparing
                BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
                  buildWhen: (previous, current) =>
                      previous.isPreparing != current.isPreparing ||
                      previous.isPlaying != current.isPlaying,
                  builder: (context, state) => IconButton(
                    icon:
                        state
                            .isPreparing // Check isPreparing from state
                        ? const SizedBox(
                            height:
                                40, // Match the approximate size of the icon
                            width: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            state
                                    .isPlaying // Check isPlaying from state
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                    onPressed:
                        state
                            .isPreparing // Disable while preparing
                        ? null
                        : () {
                            // Enable play/pause when ready
                            final audioBloc = context.read<AudioPlayerBloc>();
                            if (state.isPlaying) {
                              audioBloc.add(PauseSong());
                            } else {
                              audioBloc.add(ResumeSong());
                            }
                          },
                  ),
                ),
                // ).animate().scale(delay: 100.ms), // Removed animation
              ],
            ),
          ),
        );
        // ).animate().slideY(begin: 2, duration: 500.ms, curve: Curves.easeOutCubic); // Removed animation
      },
    );
  }
}
