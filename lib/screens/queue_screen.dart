// lib/screens/queue_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BLoC
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/audio_player/audio_player_bloc.dart'; // Import BLoC
// Removed unused import: '../models/song.dart'
import '../widgets/glassmorphic_container.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the AudioPlayerBloc using context.read() for actions
    // Use BlocBuilder to rebuild when AudioPlayerState changes
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(
          0.3,
        ), // <-- Fixed: withValues -> withOpacity
        elevation: 0,
        title: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) => Text(
            'Queue (${state.queue.length} songs)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.pop(context), // Use standard Navigator
        ),
        // Removed actions: [shuffle, clear] from here
      ),
      body: GlassmorphicContainer(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        // Use BlocBuilder to rebuild when AudioPlayerState changes
        child: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
          builder: (context, state) {
            if (state.queue.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.queue_music_rounded,
                      size: 64,
                      color: Colors.white.withOpacity(
                        0.5,
                      ), // <-- Fixed: withValues -> withOpacity
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Queue is empty',
                      style: TextStyle(
                        color: Colors.white.withOpacity(
                          0.7,
                        ), // <-- Fixed: withValues -> withOpacity
                        fontSize:
                            18, // Kept slightly larger for the empty state message
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Play a song to start a queue',
                      style: TextStyle(
                        color: Colors.white.withOpacity(
                          0.5,
                        ), // <-- Fixed: withValues -> withOpacity
                        fontSize:
                            14, // Kept slightly larger for the empty state message
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              // In queue_screen.dart, inside ListView.builder
              // Assuming your ListTile has a known fixed height, e.g., 60
              itemExtent: 60.0, // Replace 60.0 with your actual item height
              itemCount: state.queue.length,
              itemBuilder: (context, index) {
                final song = state.queue[index];
                final isCurrent = index == state.currentIndex;
                return Dismissible(
                  key: Key('${song.id}-$index'),
                  direction: index > state.currentIndex
                      ? DismissDirection.endToStart
                      : DismissDirection.none,
                  background: Container(
                    color: Colors.red.withOpacity(
                      0.3,
                    ), // <-- Fixed: withValues -> withOpacity
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (direction) {
                    // Remove from queue using the bloc
                    context.read<AudioPlayerBloc>().add(RemoveFromQueue(index));
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ), // Reduce padding
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        6,
                      ), // Slightly smaller radius
                      child: CachedNetworkImage(
                        imageUrl: song.imageUrl,
                        width: 45, // Smaller image
                        height: 45, // Smaller image
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white
                            : Colors.white.withOpacity(
                                0.8,
                              ), // <-- Fixed: withValues -> withOpacity
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 14, // Smaller title font
                      ),
                      maxLines: 1, // Limit title to one line
                      overflow:
                          TextOverflow.ellipsis, // Add ellipsis if too long
                    ),
                    subtitle: Text(
                      song.artist,
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.white.withOpacity(
                                0.9,
                              ) // <-- Fixed: withValues -> withOpacity
                            : Colors.white.withOpacity(
                                0.6,
                              ), // <-- Fixed: withValues -> withOpacity
                        fontSize: 12, // Smaller subtitle font
                      ),
                      maxLines: 1, // Limit artist to one line
                      overflow:
                          TextOverflow.ellipsis, // Add ellipsis if too long
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.equalizer_rounded,
                            color: Colors.white,
                            size: 20,
                          ) // Smaller icon
                        : IconButton(
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            iconSize: 24, // Smaller icon
                            onPressed: () {
                              // Play specific song in queue
                              context.read<AudioPlayerBloc>().add(
                                PlaySong(song, addToQueue: false),
                              );
                              // Update index via bloc event if needed, or let play handle it
                              // context.read<AudioPlayerBloc>().add(UpdateCurrentIndex(index)); // Add this event and handler if direct index setting is needed
                            },
                          ),
                    onTap: () {
                      // Play specific song in queue
                      context.read<AudioPlayerBloc>().add(
                        PlaySong(song, addToQueue: false),
                      );
                      // context.read<AudioPlayerBloc>().add(UpdateCurrentIndex(index));
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
