import 'package:flutter/material.dart';

import 'downloads_screen.dart';
import '../widgets/mini_player.dart';
import '../screens/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _DownloadsTile(),

          const Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.black,
          child: const Icon(Icons.search),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
        ),
      ),
    );
  }
}

class _DownloadsTile extends StatelessWidget {
  const _DownloadsTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DownloadsScreen()),
          );
        },
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download_for_offline, color: Colors.white, size: 30),
              SizedBox(width: 15),
              Text(
                'Downloads',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
