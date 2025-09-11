// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../widgets/song_list_item.dart';
import '../blocs/audio_player/audio_player_bloc.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/mini_player.dart';
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
  String? _currentQuery;
  String? _nextPageToken;
  bool _isFetchingMore = false;
  bool _allResultsLoaded = false;

  Future<void> _performSearch({bool isLoadMore = false}) async {
    if (_searchController.text.isEmpty && !isLoadMore) return;
    // Prevent loading more if already loading, no more results, or no token
    if (isLoadMore &&
        (_allResultsLoaded || _nextPageToken == null || _isFetchingMore)) {
      return;
    }

    final query = isLoadMore ? _currentQuery : _searchController.text;
    if (query == null || query.isEmpty) return;

    if (!isLoadMore) {
      FocusScope.of(context).unfocus();
    }

    setState(() {
      if (isLoadMore) {
        _isFetchingMore = true;
      } else {
        _isLoading = true;
        _hasSearched = true;
        _songs = []; // Clear previous results for new search
        _currentQuery = query;
        _nextPageToken = null; // Reset token for new search
        _allResultsLoaded = false; // Reset end of list flag
      }
    });

    try {
      // Use the paginated search method from ApiService
      final result = await _apiService.searchSongsPaginated(
        query,
        limit: 20,
        pageToken: isLoadMore
            ? _nextPageToken
            : null, // Pass token if loading more
      );

      final List<Song> newSongs = result['songs'] as List<Song>;
      final String? newNextPageToken = result['nextPageToken'] as String?;

      setState(() {
        if (isLoadMore) {
          // Append new songs for pagination
          _songs.addAll(newSongs);
          _isFetchingMore = false;
          // If no new token, we've likely reached the end
          if (newNextPageToken == null || newNextPageToken.isEmpty) {
            _allResultsLoaded = true;
            debugPrint("All results loaded, no more pages.");
          }
        } else {
          // Set results for new search
          _songs = newSongs;
        }
        // Update the next page token for subsequent loads
        _nextPageToken = newNextPageToken;
        debugPrint("Next Page Token: $_nextPageToken");
      });
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _isFetchingMore = false;
          } else {
            _isLoading = false;
          }
          // Optionally show a snackbar error
        });
      }
    } finally {
      if (mounted && !isLoadMore) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadMoreSongs() {
    debugPrint("Attempting to load more songs...");
    _performSearch(isLoadMore: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  kToolbarHeight + 16,
                  16,
                  16,
                ),
                child: GlassmorphicContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Search songs...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      icon: Icon(
                        Icons.search,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    onSubmitted: (_) =>
                        _performSearch(), // Use the new search function
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      // Check if scroll has ended and is at the maximum scroll extent
                      if (notification is ScrollEndNotification) {
                        // Check if scrolled to the very end
                        if (notification.metrics.pixels ==
                            notification.metrics.maxScrollExtent) {
                          debugPrint("Scrolled to end, loading more...");
                          _loadMoreSongs(); // Call the load more function
                          return true; // Indicate that the notification was handled
                        }
                      }
                      // For smoother loading, you might also want to trigger loading slightly before the end:
                      // else if (notification is ScrollUpdateNotification) {
                      //   if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) { // Load 200 pixels before the end
                      //     if (!_isFetchingMore && !_allResultsLoaded && _nextPageToken != null) {
                      //        _loadMoreSongs();
                      //        return true;
                      //     }
                      //   }
                      // }
                      return false; // Let other widgets handle the notification
                    },
                    child: _SearchContent(
                      songs: _songs,
                      isLoading: _isLoading,
                      hasSearched: _hasSearched,
                      isFetchingMore: _isFetchingMore, // Pass fetching flag
                      searchSongs: () =>
                          _performSearch(), // Pass the search function
                      loadMoreSongs:
                          _loadMoreSongs, // Pass the load more function
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
        ],
      ),
    );
  }
}

class _SearchContent extends StatelessWidget {
  final List<Song> songs;
  final bool isLoading;
  final bool hasSearched;
  final bool isFetchingMore; // Receive fetching flag
  final VoidCallback searchSongs;
  final VoidCallback loadMoreSongs; // Receive load more function

  const _SearchContent({
    required this.songs,
    required this.isLoading,
    required this.hasSearched,
    required this.isFetchingMore, // Pass fetching flag
    required this.searchSongs,
    required this.loadMoreSongs, // Pass load more function
  });

  @override
  Widget build(BuildContext context) {
    final audioBloc = context.read<AudioPlayerBloc>();

    return isLoading && songs.isEmpty
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : !hasSearched
        ? Center(
            child: Text(
              'Find your next favorite song.',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          )
        : songs.isEmpty
        ? Center(
            child: Text(
              'No results found.',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
          )
        : GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.75,
            ),
            // Add one item for the loading indicator if fetching more
            itemCount: songs.length + (isFetchingMore ? 1 : 0),
            itemBuilder: (context, index) {
              // Show loading indicator at the end if fetching more
              if (isFetchingMore && index == songs.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }
              if (index >= songs.length) return const SizedBox.shrink();

              final song = songs[index];
              return Stack(
                children: [
                  SongListItem(
                    song: song,
                    onTap: () {
                      audioBloc.add(PlaySong(song));
                    },
                    // Pass download status if needed, assuming downloaded for search
                    isDownloaded: true,
                    isDownloading: false,
                    downloadProgress: 0.0,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        Icons.add_circle,
                        color: Colors.white.withOpacity(0.8),
                        size: 28,
                      ),
                      onPressed: () {
                        audioBloc.add(AddToQueue(song));
                      },
                      tooltip: 'Add to queue',
                    ),
                  ),
                ],
              );
            },
          );
  }
}
