// lib/controllers/audio_player_controller.dart
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart'; // Import for PlayerMode
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import 'download_controller.dart'; // Import DownloadController
import 'dart:io'; // Add this import for File check

class AudioPlayerController extends GetxController {
  // Initialize AudioPlayer with PlayerMode.media for background playback support
  // Declare as late final because we need to pass the mode during initialization
  late final AudioPlayer audioPlayer;

  final DatabaseService _dbService = Get.find<DatabaseService>();
  final DownloadController _downloadController =
      Get.find<DownloadController>(); // Get instance
  final ApiService _apiService = ApiService();
  var currentSong = Rx<Song?>(null);
  var isPlaying = false.obs;
  var queue = <Song>[].obs;
  var currentIndex = 0.obs;
  var isLoadingQueue = false.obs;
  // New variable to track if a song is being prepared/fetched for UI feedback
  var isPreparing = false.obs; // <-- Added for loading indicator
  // Reactive variables to hold the player's state.
  var duration = Duration.zero.obs;
  var position = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize AudioPlayer with PlayerMode.media
    // This is often sufficient for basic background playback with audioplayers
    audioPlayer = AudioPlayer();

    // Listen to player state and update our Rx variables.
    audioPlayer.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });
    audioPlayer.onDurationChanged.listen((d) {
      duration.value = d;
    });
    audioPlayer.onPositionChanged.listen((p) {
      position.value = p;
    });
    // Listen for when a song completes to play next in queue
    audioPlayer.onPlayerComplete.listen((event) {
      playNext();
    });
  }

  // Add queueAllDownloaded parameter
  Future<void> play(
    Song song, {
    bool addToQueue = true,
    bool queueAllDownloaded = false,
  }) async {
    // Set preparing state immediately for UI feedback
    isPreparing.value = true; // <-- Set to true at the start
    if (currentSong.value?.id == song.id) {
      if (audioPlayer.state == PlayerState.playing) {
        await pause();
      } else {
        await resume();
      }
      isPreparing.value = false; // <-- Reset if toggling play/pause
      return;
    }
    // Stop the current song and reset state before playing a new one.
    await audioPlayer.stop(); // Use stop() for clean state
    duration.value = Duration.zero;
    position.value = Duration.zero;
    currentSong.value = song;
    try {
      // If this is a new song (not from queue), fetch related songs or use downloaded list
      if (addToQueue && (queue.isEmpty || queue[0].id != song.id)) {
        if (queueAllDownloaded) {
          // Populate queue with all downloaded songs
          final allDownloadedSongs = _downloadController.downloadedSongs;
          if (allDownloadedSongs.isNotEmpty) {
            queue.value = allDownloadedSongs;
            // Find the index of the song being played
            final songIndex = allDownloadedSongs.indexWhere(
              (s) => s.id == song.id,
            );
            currentIndex.value = songIndex >= 0
                ? songIndex
                : 0; // Default to 0 if not found (shouldn't happen)
            debugPrint(
              "Queue populated with all ${allDownloadedSongs.length} downloaded songs.",
            );
          } else {
            // Fallback if somehow the list is empty
            queue.value = [song];
            currentIndex.value = 0;
            debugPrint(
              "Downloaded songs list was empty, queue set to current song only.",
            );
          }
        } else {
          // Fetch related songs for online playback
          await _fetchRelatedSongs(song);
        }
      }
      final downloadedSong = _dbService.getSong(song.id);
      // Check if the file actually exists locally before trying to play it
      if (downloadedSong?.filePath != null &&
          downloadedSong!.filePath!.isNotEmpty &&
          File(downloadedSong.filePath!).existsSync()) {
        // Check file existence
        debugPrint("Playing from local file: ${downloadedSong.filePath}");
        await audioPlayer.play(DeviceFileSource(downloadedSong.filePath!));
        // Optional: Trigger download to ensure cache is up-to-date or re-cache if needed
        // This handles cases where the file might have been deleted manually
        // We can ignore errors here as the file is already playing
        // Make sure downloadSong is public (not _downloadSong) in DownloadController
        _downloadController.downloadSong(song).catchError((e) {
          debugPrint(
            "Background re-cache check/trigger failed for ${song.id}: $e",
          );
        });
      } else {
        debugPrint("Streaming from network and starting download...");
        final audioUrl = await _apiService.getAudioUrl(song.id);
        await audioPlayer.play(UrlSource(audioUrl));
        // Start caching the song in the background after playback starts
        // Use .then() or await based on whether you want play() to wait
        // Using .then() allows playback to start immediately
        // Make sure downloadSong is public (not _downloadSong) in DownloadController
        _downloadController
            .downloadSong(song)
            .then((_) {
              debugPrint(
                "Background download initiated/completed for ${song.id}",
              );
            })
            .catchError((error) {
              // Handle potential errors during the download initiation
              debugPrint(
                "Error initiating background download for ${song.id}: $error",
              );
              // Optionally show a snackbar to the user
              // Get.snackbar('Download Error', 'Failed to cache ${song.title}');
            });
      }
    } catch (e) {
      debugPrint("Error playing/streaming song: $e");
      Get.snackbar('Playback Error', 'Could not play the selected song.');
    } finally {
      // Ensure isPreparing is set to false regardless of success or failure
      // This is crucial for the UI loading indicator
      isPreparing.value = false; // <-- Reset in finally block
    }
  }

  Future<void> _fetchRelatedSongs(Song song) async {
    isLoadingQueue.value = true;
    try {
      // ... (rest of the method remains largely the same)
      // Try multiple strategies to get related songs
      List<Song> relatedSongs = [];
      // Strategy 1: Get songs by the same artist
      try {
        final artistSongs = await _apiService.searchSongs(
          song.artist,
          limit: 15,
        );
        relatedSongs.addAll(artistSongs.where((s) => s.id != song.id));
      } catch (e) {
        debugPrint("Error fetching artist songs: $e");
      }
      // Strategy 2: Get songs with similar title/theme
      // try {
      //   final titleWords = song.title.split(' ');
      //   if (titleWords.length > 1) {
      //     // Use the most significant word (longest) for search
      //     final searchTerm = titleWords.reduce(
      //       (a, b) => a.length > b.length ? a : b,
      //     );
      //     if (searchTerm.length > 3) {
      //       // Only use meaningful words
      //       final similarSongs = await _apiService.searchSongs(
      //         searchTerm,
      //         limit: 5,
      //       );
      //       relatedSongs.addAll(similarSongs.where((s) => s.id != song.id));
      //     }
      //   }
      // } catch (e) {
      //   debugPrint("Error fetching similar title songs: $e");
      // }
      // Strategy 3: Get YouTube's recommended songs
      try {
        final recommendedSongs = await _apiService.getSimilarSongs(song.id);
        relatedSongs.addAll(recommendedSongs.where((s) => s.id != song.id));
      } catch (e) {
        debugPrint("Error fetching recommended songs: $e");
      }
      // Remove duplicates and limit to 10 songs
      final uniqueSongs = <String, Song>{};
      for (var s in relatedSongs) {
        // Renamed loop variable to avoid shadowing
        if (!uniqueSongs.containsKey(s.id)) {
          uniqueSongs[s.id] = s;
        }
      }
      final finalList = uniqueSongs.values.toList();
      // If we still don't have enough songs, add some popular ones as fallback
      if (finalList.length < 20) {
        try {
          final popularSongs = await _apiService.searchSongs(
            'popular songs',
            limit: 10,
          );
          for (var popularSong in popularSongs) {
            if (finalList.length >= 30) break;
            if (popularSong.id != song.id &&
                !uniqueSongs.containsKey(popularSong.id)) {
              finalList.add(popularSong);
              uniqueSongs[popularSong.id] = popularSong;
            }
          }
        } catch (e) {
          debugPrint("Error fetching popular songs: $e");
        }
      }
      // Shuffle the list to add variety
      finalList.shuffle();
      // Limit to maximum 10 songs in queue
      final limitedList = finalList.take(30).toList();
      queue.value = [song, ...limitedList];
      currentIndex.value = 0;
      if (limitedList.isEmpty) {
        Get.snackbar(
          'Info',
          'No related songs found. Add songs to queue manually.',
        );
      }
    } catch (e) {
      debugPrint("Error fetching related songs: $e");
      // If we can't get related songs, at least add the current song to queue
      queue.value = [song];
      currentIndex.value = 0;
      Get.snackbar('Queue Error', 'Could not load related songs.');
    } finally {
      isLoadingQueue.value = false;
    }
  }

  // ... (rest of the methods like playNext, playPrevious, etc. remain the same)
  Future<void> playNext() async {
    if (queue.isEmpty || currentIndex.value >= queue.length - 1) {
      // If we're at the end of the queue, try to get more related songs
      if (currentSong.value != null) {
        await _fetchMoreSongs();
        if (currentIndex.value < queue.length - 1) {
          currentIndex.value++;
          await play(queue[currentIndex.value], addToQueue: false);
        } else {
          // If no more songs, just restart the current one
          await play(currentSong.value!, addToQueue: false);
        }
      }
      return;
    }
    currentIndex.value++;
    await play(queue[currentIndex.value], addToQueue: false);
  }

  Future<void> _fetchMoreSongs() async {
    if (currentSong.value == null) return;
    isLoadingQueue.value = true;
    try {
      // Get more songs based on the current song's artist
      final moreSongs = await _apiService.searchSongs(
        currentSong.value!.artist,
        limit: 5,
      );
      // Filter out songs already in queue
      final existingIds = queue.map((s) => s.id).toSet();
      final newSongs = moreSongs
          .where((s) => !existingIds.contains(s.id))
          .toList();
      if (newSongs.isNotEmpty) {
        queue.addAll(newSongs);
        Get.snackbar(
          'Queue Updated',
          'Added ${newSongs.length} more songs to queue',
        );
      }
    } catch (e) {
      debugPrint("Error fetching more songs: $e");
    } finally {
      isLoadingQueue.value = false;
    }
  }

  Future<void> playPrevious() async {
    if (currentIndex.value <= 0) return;
    currentIndex.value--;
    await play(queue[currentIndex.value], addToQueue: false);
  }

  void addToQueue(Song song) {
    // Add song after the current position
    if (currentIndex.value < queue.length - 1) {
      queue.insert(currentIndex.value + 1, song);
    } else {
      queue.add(song);
    }
    Get.snackbar('Added to Queue', '${song.title} added to queue');
  }

  void addToQueueMultiple(List<Song> songs) {
    queue.addAll(songs);
    Get.snackbar('Queue Updated', 'Added ${songs.length} songs to queue');
  }

  void removeFromQueue(int index) {
    if (index > currentIndex.value && index < queue.length) {
      final removedSong = queue[index];
      queue.removeAt(index);
      Get.snackbar('Removed from Queue', '${removedSong.title} removed');
    }
  }

  void clearQueue() {
    final current = currentSong.value;
    queue.value = current != null ? [current] : [];
    currentIndex.value = 0;
    Get.snackbar('Queue Cleared', 'All songs removed from queue');
  }

  Future<void> shuffleQueue() async {
    if (queue.length <= 1) return;
    final current = queue[currentIndex.value];
    final remainingSongs = queue.sublist(currentIndex.value + 1)..shuffle();
    queue.value = [current, ...remainingSongs];
    currentIndex.value = 0;
    Get.snackbar('Queue Shuffled', 'Remaining songs have been shuffled');
  }

  Future<void> pause() async {
    await audioPlayer.pause();
  }

  Future<void> resume() async {
    await audioPlayer.resume();
  }

  Future<void> seek(Duration position) async {
    await audioPlayer.seek(position);
  }

  @override
  void onClose() {
    // Important: dispose the player to free up resources
    audioPlayer.dispose();
    _apiService.dispose();
    super.onClose();
  }
}
