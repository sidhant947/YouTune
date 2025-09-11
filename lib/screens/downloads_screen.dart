// lib/screens/downloads_screen.dart
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Removed as per previous instruction
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BLoC
import '../widgets/song_list_item.dart';
import '../blocs/audio_player/audio_player_bloc.dart'; // Import BLoC
import '../blocs/download/download_bloc.dart'; // Import BLoC
// import '../models/song.dart'; // Import Song model // <-- Add this import

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the BLoCs using context.read()
    final downloadBloc = context.read<DownloadBloc>();
    final audioBloc = context.read<AudioPlayerBloc>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Use standard Navigator
        ),
        // Optional: Add a Clear All button in the AppBar
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.delete_sweep_outlined),
        //     onPressed: () {
        //       // Implement Clear All logic here, e.g., show confirmation dialog
        //       // and then iterate through downloaded songs calling DeleteSong event.
        //     },
        //   ),
        // ],
      ),
      // Use BlocBuilder to rebuild when DownloadState changes
      body: BlocBuilder<DownloadBloc, DownloadState>(
        builder: (context, state) {
          // Use the helper method to get the combined list
          final displayList = state.getAllDisplayableSongs();
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
              ),
              // ).animate().fade(duration: 500.ms), // Removed animation
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
              // Get download status and progress for this specific song from state
              final isDownloaded = state.isSongDownloaded(song.id);
              final progress = state.downloadProgress[song.id] ?? 0.0;
              final isDownloading =
                  state.downloadStatus[song.id] == DownloadStatus.downloading;

              return Dismissible(
                key: Key(song.id),
                direction: DismissDirection.endToStart, // Keep swipe to delete
                onDismissed: (direction) {
                  // Handle dismiss - delete the song using the bloc
                  downloadBloc.add(DeleteSong(song));
                  // Show snackbar
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
                      audioBloc.add(PlaySong(song, queueAllDownloaded: true)),
                  // Pass download information
                  isDownloaded: isDownloaded,
                  isDownloading: isDownloading,
                  downloadProgress: progress,
                  // Pass the delete callback - WITHOUT confirmation dialog
                  onDelete: isDownloaded
                      ? () {
                          // Dispatch the DeleteSong event immediately
                          downloadBloc.add(DeleteSong(song));
                          // Show snackbar confirmation
                        }
                      : null, // No delete callback if not downloaded
                ),
              );
            },
          );
        },
      ),
    );
  }
}
