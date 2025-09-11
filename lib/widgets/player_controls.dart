// lib/widgets/player_controls.dart
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Removed as per previous instruction
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BLoC
import '../blocs/audio_player/audio_player_bloc.dart'; // Import BLoC

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to rebuild when AudioPlayerState changes
    return BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
      builder: (context, state) {
        final audioBloc = context.read<AudioPlayerBloc>(); // Get bloc instance
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(
                Icons.skip_previous_rounded,
                color: Colors.white,
                size: 36,
              ),
              onPressed: state.currentIndex > 0
                  ? () => audioBloc.add(PlayPrevious())
                  : null,
            ),
            // Center Play/Pause Button with Loading Indicator
            // Wrap the main button in BlocBuilder to listen to isPreparing
            BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
              buildWhen: (previous, current) =>
                  previous.isPreparing != current.isPreparing ||
                  previous.isPlaying != current.isPlaying,
              builder: (context, state) => IconButton(
                icon:
                    state
                        .isPreparing // Check isPreparing from state
                    ? const SizedBox(
                        height: 50, // Approximate size of the icon for layout
                        width: 50,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : AnimatedSwitcher(
                        // <-- Normal icon when not preparing
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: Icon(
                          state
                                  .isPlaying // Check isPlaying from state
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          key: ValueKey<bool>(state.isPlaying),
                          color: Colors.white,
                          size: 72,
                        ),
                      ),
                iconSize: 72, // Ensure size matches the Icon
                onPressed:
                    state
                        .isPreparing // Disable while preparing
                    ? null
                    : () {
                        // Enable play/pause when ready
                        if (state.isPlaying) {
                          audioBloc.add(PauseSong());
                        } else {
                          audioBloc.add(ResumeSong());
                        }
                      },
              ),
            ),
            // ).animate().scale(delay: 100.ms), // Removed animation
            IconButton(
              icon: const Icon(
                Icons.skip_next_rounded,
                color: Colors.white,
                size: 36,
              ),
              onPressed: state.currentIndex < state.queue.length - 1
                  ? () => context.read<AudioPlayerBloc>().add(PlayNext())
                  : null,
            ),
          ],
        );
      },
    );
  }
}
