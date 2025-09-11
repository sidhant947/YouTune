// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
// import 'package:flutter_animate/flutter_animate.dart'; // Removed
import 'package:get/get.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../widgets/song_list_item.dart';
import '../controllers/audio_player_controller.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/mini_player.dart'; // Import MiniPlayer
// import 'package:flutter/foundation.dart'; // Import for debugPrint

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Song> _songs = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  void _searchSongs() async {
    if (_searchController.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });
    try {
      final songs = await _apiService.searchSongs(_searchController.text);
      setState(() {
        _songs = songs;
      });
    } catch (e) {
      debugPrint(e.toString()); // <-- Fixed
      // Optionally show an error snackbar
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _apiService.dispose();
    super.dispose(); // FIX: Call super.dispose()
  }

  @override
  Widget build(BuildContext context) {
    // final audioController = Get.find<AudioPlayerController>();
    // Wrap the main content and MiniPlayer in a Scaffold
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(
          0.3,
        ), // <-- Fixed (from previous steps)
        elevation: 0,
        title: const Text(
          'Search', // Static title for Search
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            // Navigate back to HomeScreen
            Get.back();
          },
        ),
      ),
      body: Stack(
        children: [
          // Main content area (search bar and results)
          _SearchContent(
            searchController: _searchController,
            songs: _songs,
            isLoading: _isLoading,
            hasSearched: _hasSearched,
            searchSongs: _searchSongs,
            apiService:
                _apiService, // Pass apiService if needed in _SearchContent
          ),
          // MiniPlayer positioned at the bottom
          const Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
        ],
      ),
    );
  }
}

// Extract the original Column content into a separate widget for clarity and reuse
class _SearchContent extends StatelessWidget {
  final TextEditingController searchController;
  final List<Song> songs;
  final bool isLoading;
  final bool hasSearched;
  final VoidCallback searchSongs;
  final ApiService apiService; // Pass ApiService if needed
  const _SearchContent({
    required this.searchController,
    required this.songs,
    required this.isLoading,
    required this.hasSearched,
    required this.searchSongs,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioPlayerController>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 40, 16, 16),
          child: GlassmorphicContainer(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search songs or artists...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5), // <-- Fixed
                ),
                border: InputBorder.none,
                icon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7), // <-- Fixed
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Colors.white.withOpacity(0.7), // <-- Fixed
                  ),
                  onPressed: songs.isNotEmpty
                      ? () => audioController.addToQueueMultiple(songs)
                      : null,
                  tooltip: 'Add all to queue',
                ),
              ),
              onSubmitted: (_) => searchSongs(), // Use the passed callback
            ),
          ),
        ),
        // Expanded widget to take remaining space, considering MiniPlayer height
        Expanded(
          child: Padding(
            // Add padding at the bottom to ensure content doesn't go under MiniPlayer
            padding: const EdgeInsets.only(
              bottom: 80.0,
            ), // Approximate MiniPlayer height
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : !hasSearched
                // Removed .animate().fade()
                ? Center(
                    child: Text(
                      'Find your next favorite song.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5), // <-- Fixed
                      ),
                    ),
                  )
                : songs.isEmpty
                // Removed .animate().fade()
                ? Center(
                    child: Text(
                      'No results found.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5), // <-- Fixed
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      0,
                      12,
                      12,
                    ), // Adjust padding
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return Stack(
                        children: [
                          SongListItem(
                            song: song,
                            onTap: () {
                              audioController.play(song);
                            },
                          ),
                          // Removed .animate().fade(...).slideY(...)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: Icon(
                                Icons.add_circle,
                                color: Colors.white.withOpacity(
                                  0.8,
                                ), // <-- Fixed
                                size: 28,
                              ),
                              onPressed: () {
                                audioController.addToQueue(song);
                              },
                              tooltip: 'Add to queue',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
