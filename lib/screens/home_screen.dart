// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'downloads_screen.dart'; // Import the new Downloads screen
import '../widgets/mini_player.dart'; // Make sure this import is present
import '../screens/search_screen.dart'; // Import SearchScreen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Main content area - just the Downloads tile
          _DownloadsTile(),
          // MiniPlayer positioned at the bottom
          const Positioned(bottom: 0, left: 0, right: 0, child: MiniPlayer()),
        ],
      ),
      // Add Floating Action Button
      // Inside lib/screens/home_screen.dart, within the Scaffold widget

      // ... other Scaffold properties ...
      floatingActionButton: Padding(
        // Add padding to lift the FAB above the MiniPlayer
        padding: const EdgeInsets.only(bottom: 90.0), // Adjust 90.0 if needed
        child: FloatingActionButton(
          backgroundColor: Colors.white.withOpacity(
            0.9,
          ), // Use withOpacity as per previous fixes
          foregroundColor: Colors.black,
          child: const Icon(Icons.search),
          onPressed: () {
            // Navigate to SearchScreen
            Get.to(() => const SearchScreen());
          },
        ),
      ),
      // ... other Scaffold properties ...
    );
  }
}

// Extract the Downloads tile into a separate widget for clarity
class _DownloadsTile extends StatelessWidget {
  const _DownloadsTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0), // Add some padding around the tile
      child: GestureDetector(
        onTap: () {
          // Navigate to the Downloads screen
          Get.to(() => const DownloadsScreen());
        },
        child: Container(
          height: 80, // Set a fixed height for the tile
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16), // Use rounded corners
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: const Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // Center content horizontally
            children: [
              Icon(
                Icons.download_for_offline,
                color: Colors.white,
                size: 30, // Adjust icon size
              ),
              SizedBox(width: 15), // Add space between icon and text
              Text(
                'Downloads',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20, // Adjust font size
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
