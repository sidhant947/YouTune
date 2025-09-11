// lib/widgets/player_controls.dart
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Removed
import 'package:get/get.dart';
import '../controllers/audio_player_controller.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioPlayerController>();
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(
              Icons.skip_previous_rounded,
              color: Colors.white,
              size: 36,
            ),
            onPressed: audioController.currentIndex.value > 0
                ? () => audioController.playPrevious()
                : null,
          ),
          // Center Play/Pause Button with Loading Indicator
          Obx(
            // <-- Wrap the main button in Obx to listen to isPreparing
            () => IconButton(
              icon:
                  audioController
                      .isPreparing
                      .value // <-- Check isPreparing
                  ? const SizedBox(
                      height: 50, // Approximate size of the icon for layout
                      width: 50,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : AnimatedSwitcher(
                      // <-- Normal icon when not preparing
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Icon(
                        audioController.isPlaying.value
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_circle_filled_rounded,
                        key: ValueKey<bool>(audioController.isPlaying.value),
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
              iconSize: 72, // Ensure size matches the Icon
              onPressed:
                  audioController
                      .isPreparing
                      .value // <-- Disable while preparing
                  ? null
                  : () {
                      // <-- Enable play/pause when ready
                      if (audioController.isPlaying.value) {
                        audioController.pause();
                      } else {
                        audioController.resume();
                      }
                    },
            ),
          ), // Removed .animate().scale(...)
          IconButton(
            icon: const Icon(
              Icons.skip_next_rounded,
              color: Colors.white,
              size: 36,
            ),
            onPressed:
                audioController.currentIndex.value <
                    audioController.queue.length - 1
                ? () => audioController.playNext()
                : null,
          ),
        ],
      ),
    );
  }
}
