// lib/screens/downloads_screen.dart
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Removed
import 'package:get/get.dart';
import '../widgets/song_list_item.dart';
import '../controllers/audio_player_controller.dart';
import '../controllers/download_controller.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadController = Get.find<DownloadController>();
    final audioController = Get.find<AudioPlayerController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        // Use the helper method to get the combined list
        final displayList = downloadController.getAllDisplayableSongs();
        if (displayList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.download_for_offline_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 20),
                Text(
                  'No downloads yet.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Downloaded songs and active downloads will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ), // Removed .animate().fade(...)
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12.0), // Adjust padding as needed
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 0.75,
          ),
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            final song = displayList[index];
            // Get download status and progress for this specific song
            final isDownloaded = downloadController.isSongDownloaded(song.id);
            final progress =
                downloadController.downloadProgress[song.id] ?? 0.0;
            final isDownloading =
                downloadController.downloadStatus[song.id] ==
                DownloadStatus.downloading;
            return Dismissible(
              key: Key(song.id),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                // Handle dismiss - might need logic to differentiate between downloaded/active
                // For simplicity, we'll try to delete from both, controller handles it
                downloadController.deleteSong(song);
                Get.snackbar(
                  'Removed',
                  '${song.title} removed.',
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
                onTap: () =>
                    audioController.play(song, queueAllDownloaded: true),
                // Pass download information to the SongListItem
                isDownloaded: isDownloaded,
                isDownloading: isDownloading,
                downloadProgress: progress,
              ),
            ); // Removed .animate().fade(...).slideY(...)
          },
        );
      }),
    );
  }
}
