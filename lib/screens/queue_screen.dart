// lib/screens/queue_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/audio_player_controller.dart';
// Removed unused import: '../models/song.dart'
import '../widgets/glassmorphic_container.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioPlayerController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3), // <-- Fixed
        elevation: 0,
        title: Obx(
          () => Text(
            'Queue (${audioController.queue.length} songs)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Get.back(),
        ),
        // Removed actions: [shuffle, clear] from here
      ),
      body: GlassmorphicContainer(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (audioController.queue.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.5), // <-- Fixed
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Queue is empty',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), // <-- Fixed
                      fontSize:
                          18, // Kept slightly larger for the empty state message
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Play a song to start a queue',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5), // <-- Fixed
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
            itemCount: audioController.queue.length,
            itemBuilder: (context, index) {
              final song = audioController.queue[index];
              final isCurrent = index == audioController.currentIndex.value;
              return Dismissible(
                key: Key('${song.id}-$index'),
                direction: index > audioController.currentIndex.value
                    ? DismissDirection.endToStart
                    : DismissDirection.none,
                background: Container(
                  color: Colors.red.withValues(alpha: 0.3), // <-- Fixed
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (direction) {
                  audioController.removeFromQueue(index);
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
                          : Colors.white.withValues(alpha: 0.8), // <-- Fixed
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14, // Smaller title font
                    ),
                    maxLines: 1, // Limit title to one line
                    overflow: TextOverflow.ellipsis, // Add ellipsis if too long
                  ),
                  subtitle: Text(
                    song.artist,
                    style: TextStyle(
                      color: isCurrent
                          ? Colors.white.withValues(alpha: 0.9) // <-- Fixed
                          : Colors.white.withValues(alpha: 0.6), // <-- Fixed
                      fontSize: 12, // Smaller subtitle font
                    ),
                    maxLines: 1, // Limit artist to one line
                    overflow: TextOverflow.ellipsis, // Add ellipsis if too long
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
                            audioController.currentIndex.value = index;
                            audioController.play(song, addToQueue: false);
                          },
                        ),
                  onTap: () {
                    audioController.currentIndex.value = index;
                    audioController.play(song, addToQueue: false);
                  },
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
