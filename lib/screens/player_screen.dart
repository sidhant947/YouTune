// lib/screens/player_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Removed as per previous instruction
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BLoC
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/audio_player/audio_player_bloc.dart'; // Import BLoC
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
  // Removed unused field _gestureDetectorKey

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    // Do not call repeat() here anymore
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use BlocBuilder to rebuild when AudioPlayerState changes
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
          onPressed: () => Navigator.pop(context), // Standard back button
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            onPressed: () {
              // Navigate to QueueScreen using standard Navigator
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QueueScreen()),
              );
            },
          ),
        ],
      ),
      // The Scaffold now has only ONE body wrapped in BlocBuilder
      body: BlocBuilder<AudioPlayerBloc, AudioPlayerState>(
        builder: (context, state) {
          final song = state.currentSong;
          if (song == null) {
            return const Center(child: Text('No song selected'));
          }
          // Control rotation animation based on isPlaying state
          if (state.isPlaying) {
            if (!_rotationController.isAnimating) {
              _rotationController.repeat();
            }
          } else {
            if (_rotationController.isAnimating) {
              _rotationController.stop();
            }
          }
          // Wrap the main Stack content with GestureDetector for swipe down to close
          return GestureDetector(
            onVerticalDragUpdate: (details) {
              // Check if the drag is primarily downward (delta.dy > 0)
              // and if the total vertical movement is significant (delta.dy > 20)
              // This allows the swipe to be detected anywhere on the screen.
              if (details.delta.dy > 20 &&
                  details.delta.dy.abs() > details.delta.dx.abs()) {
                // Pop the screen if swipe down detected using standard Navigator
                Navigator.pop(context);
              }
            },
            child: Stack(
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
                    child: Container(
                      color: Colors.black.withOpacity(
                        0.5,
                      ), // <-- Fixed: withValues -> withOpacity
                    ),
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
                        RotationTransition(
                          turns: _rotationController,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    0.5,
                                  ), // <-- Fixed: withValues -> withOpacity
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
                        ),
                        // Removed animation
                        // .animate()
                        // .fade(duration: 500.ms)
                        // .scale(begin: const Offset(0.8, 0.8)),
                        const Spacer(),
                        // Song Info - Modified to handle overflow
                        Text(
                          song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1, // Limit to one line
                          overflow:
                              TextOverflow.ellipsis, // Add ellipsis if too long
                        ),
                        // Removed animation
                        // .animate().fade(delay: 200.ms).slideY(begin: 0.5),
                        const SizedBox(height: 8),
                        Text(
                          song.artist,
                          style: TextStyle(
                            color: Colors.white.withOpacity(
                              0.7,
                            ), // <-- Fixed: withValues -> withOpacity
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1, // Limit to one line
                          overflow:
                              TextOverflow.ellipsis, // Add ellipsis if too long
                        ),
                        // Removed animation
                        // .animate().fade(delay: 300.ms).slideY(begin: 0.5),
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
                        ),
                        // Removed animation
                        // .animate().fade(delay: 400.ms).slideY(begin: 0.5),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
