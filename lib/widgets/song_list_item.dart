// lib/widgets/song_list_item.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import 'glassmorphic_container.dart';

class SongListItem extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  // Add parameters for download status and progress
  final bool isDownloaded;
  final bool isDownloading;
  final double downloadProgress;
  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    // Provide default values for new parameters
    this.isDownloaded = true, // Assume downloaded if not specified
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    String subtitleText = song.artist;
    if (song.album != null && song.album!.isNotEmpty) {
      subtitleText += ' • ${song.album}';
    }
    // Determine border color and style based on download status
    Color borderColor = Colors.white.withOpacity(0.2); // Default
    double borderWidth = 1.0;
    if (isDownloading) {
      borderColor = Colors.green; // Green border for downloading
      borderWidth = 2.0; // Slightly thicker
    } else if (isDownloaded) {
      borderColor = Colors.white.withOpacity(0.3); // Standard for downloaded
    }
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        // Wrap the existing GlassmorphicContainer content with a Container that has a dynamic border
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: song.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) =>
                            Container(color: Colors.white.withOpacity(0.1)),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.white.withOpacity(0.1),
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    // Progress bar overlay at the bottom if downloading
                    if (isDownloading && downloadProgress > 0.0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: downloadProgress,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.green,
                          ),
                          minHeight: 4.0,
                        ),
                      ),
                    // Pulsing Download Icon Overlay when downloading
                    if (isDownloading)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: _PulsingDownloadIcon(),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom widget for the pulsing download icon
class _PulsingDownloadIcon extends StatefulWidget {
  const _PulsingDownloadIcon();

  @override
  State<_PulsingDownloadIcon> createState() => _PulsingDownloadIconState();
}

class _PulsingDownloadIconState extends State<_PulsingDownloadIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true); // Repeat forward and backward
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.all(4.0),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.download_for_offline,
          color: Colors.green,
          size: 20,
        ),
      ),
    );
  }
}
