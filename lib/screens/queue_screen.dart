// lib/screens/queue_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/audio_player_controller.dart';
import '../models/song.dart';
import '../widgets/glassmorphic_container.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioPlayerController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        title: Obx(
          () => Text(
            'Queue (${audioController.queue.length} songs)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            onPressed: () => audioController.shuffleQueue(),
            tooltip: 'Shuffle queue',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            onPressed: () => audioController.clearQueue(),
            tooltip: 'Clear queue',
          ),
        ],
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
                    color: Colors.white.withOpacity(0.5),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Queue is empty',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Play a song to start a queue',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
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
                  color: Colors.red.withOpacity(0.3),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (direction) {
                  audioController.removeFromQueue(index);
                },
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: song.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    song.title,
                    style: TextStyle(
                      color: isCurrent
                          ? Colors.white
                          : Colors.white.withOpacity(0.8),
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    song.artist,
                    style: TextStyle(
                      color: isCurrent
                          ? Colors.white.withOpacity(0.9)
                          : Colors.white.withOpacity(0.6),
                    ),
                  ),
                  trailing: isCurrent
                      ? Icon(Icons.equalizer_rounded, color: Colors.white)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              onPressed: () {
                                audioController.currentIndex.value = index;
                                audioController.play(song, addToQueue: false);
                              },
                            ),
                          ],
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
