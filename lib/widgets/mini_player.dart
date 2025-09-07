import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/audio_player_controller.dart';
import '../screens/player_screen.dart';
import 'glassmorphic_container.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioPlayerController>();

    return Obx(() {
      final song = audioController.currentSong.value;
      if (song == null) {
        return const SizedBox.shrink();
      }
      return GlassmorphicContainer(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: GestureDetector(
          onTap: () {
            Get.to(
              () => const PlayerScreen(),
              transition: Transition.downToUp,
              duration: const Duration(milliseconds: 500),
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
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Obx(
                () => IconButton(
                  icon: Icon(
                    audioController.isPlaying.value
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_filled_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  onPressed: () {
                    if (audioController.isPlaying.value) {
                      audioController.pause();
                    } else {
                      audioController.resume();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ).animate().slideY(
        begin: 2,
        duration: 500.ms,
        curve: Curves.easeOutCubic,
      );
    });
  }
}
