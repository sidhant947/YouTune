// lib/screens/player_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/audio_player_controller.dart';
import '../widgets/player_controls.dart';
import '../widgets/seek_bar.dart';
import '../widgets/glassmorphic_container.dart';
import './queue_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioPlayerController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () {
              Get.to(
                () => const QueueScreen(),
                transition: Transition.downToUp,
                duration: const Duration(milliseconds: 500),
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        final song = audioController.currentSong.value;
        if (song == null) {
          // This should ideally not be visible, but as a fallback
          return const Center(child: Text('No song selected'));
        }

        // Pause or resume rotation based on play state
        if (audioController.isPlaying.value) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }

        return Stack(
          children: [
            // Blurred Background Image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: CachedNetworkImageProvider(song.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
            // Main Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Rotating Album Art
                    RotationTransition(
                          turns: _rotationController,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.35,
                              ),
                              child: CachedNetworkImage(
                                imageUrl: song.imageUrl,
                                height: MediaQuery.of(context).size.width * 0.7,
                                width: MediaQuery.of(context).size.width * 0.7,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                        .animate()
                        .fade(duration: 500.ms)
                        .scale(begin: const Offset(0.8, 0.8)),
                    const Spacer(),
                    // Song Info
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.5),
                    const SizedBox(height: 8),
                    Text(
                      song.artist,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.5),
                    const SizedBox(height: 30),
                    // Controls in a Glassmorphic Container
                    GlassmorphicContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 16,
                      child: const Column(
                        children: [
                          SeekBarWidget(),
                          SizedBox(height: 10),
                          PlayerControls(),
                        ],
                      ),
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.5),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
