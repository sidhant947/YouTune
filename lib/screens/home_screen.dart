import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../widgets/song_list_item.dart';
import '../providers/audio_player_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Song> _songs = [];
  bool _isLoading = false;

  void _searchSongs() async {
    if (_searchController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final songs = await _apiService.searchSongs(_searchController.text);
      setState(() {
        _songs = songs;
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search for a song',
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _searchSongs,
              ),
            ),
            onSubmitted: (_) => _searchSongs(),
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _songs.length,
                  itemBuilder: (context, index) {
                    final song = _songs[index];
                    return SongListItem(
                      song: song,
                      onTap: () {
                        Provider.of<AudioPlayerProvider>(
                          context,
                          listen: false,
                        ).play(song);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
