import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../widgets/song_list_item.dart';
import '../controllers/audio_player_controller.dart';
import '../widgets/glassmorphic_container.dart';

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
      print(e);
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
    super.dispose();
  }

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
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Search songs or artists...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white.withOpacity(0.7)),
              ),
              onSubmitted: (_) => _searchSongs(),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : !_hasSearched
              ? Center(
                  child: Text(
                    'Find your next favorite song.',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ).animate().fade(),
                )
              : _songs.isEmpty
              ? Center(
                  child: Text(
                    'No results found.',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ).animate().fade(),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return SongListItem(
                      song: song,
                      onTap: () {
                        audioController.play(song);
                      },
                    ).animate().fade(delay: (index * 50).ms).slideY(begin: 0.2);
                  },
                ),
        ),
      ],
    );
  }
}
