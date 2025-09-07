import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../widgets/song_list_item.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/download_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadController = Get.find<DownloadController>();
    final audioController = Get.find<AudioPlayerController>();

    return Obx(() {
      if (downloadController.downloadedSongs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.library_music_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                'Your Library is Empty',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Songs you download will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ).animate().fade(duration: 500.ms),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, kToolbarHeight + 60, 12, 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.75,
        ),
        itemCount: downloadController.downloadedSongs.length,
        itemBuilder: (context, index) {
          final song = downloadController.downloadedSongs[index];
          return Dismissible(
            key: Key(song.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              downloadController.deleteSong(song);
              Get.snackbar(
                'Removed',
                '${song.title} removed from your library.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.white.withOpacity(0.1),
                colorText: Colors.white,
              );
            },
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            child: SongListItem(
              song: song,
              onTap: () => audioController.play(song),
            ),
          ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.2);
        },
      );
    });
  }
}
