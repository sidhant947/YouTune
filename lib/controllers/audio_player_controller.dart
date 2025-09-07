// lib/controllers/audio_player_controller.dart
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import 'download_controller.dart';

class AudioPlayerController extends GetxController {
  final AudioPlayer audioPlayer = AudioPlayer();
  final DatabaseService _dbService = Get.find<DatabaseService>();
  final DownloadController _downloadController = Get.find<DownloadController>();
  final ApiService _apiService = ApiService();

  var currentSong = Rx<Song?>(null);
  var isPlaying = false.obs;
  var queue = <Song>[].obs;
  var currentIndex = 0.obs;
  var isLoadingQueue = false.obs;

  // Reactive variables to hold the player's state.
  var duration = Duration.zero.obs;
  var position = Duration.zero.obs;

  @override
  void onInit() {
    super.onInit();
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

  Future<void> play(Song song, {bool addToQueue = true}) async {
    if (currentSong.value?.id == song.id) {
      if (audioPlayer.state == PlayerState.playing) {
        await pause();
      } else {
        await resume();
      }
      return;
    }

    // Stop the current song and reset state before playing a new one.
    await audioPlayer.stop();
    duration.value = Duration.zero;
    position.value = Duration.zero;

    currentSong.value = song;

    // If this is a new song (not from queue), fetch related songs
    if (addToQueue && (queue.isEmpty || queue[0].id != song.id)) {
      await _fetchRelatedSongs(song);
    }

    final downloadedSong = _dbService.getSong(song.id);
    if (downloadedSong?.filePath != null &&
        downloadedSong!.filePath!.isNotEmpty) {
      print("Playing from local file: ${downloadedSong.filePath}");
      await audioPlayer.play(DeviceFileSource(downloadedSong.filePath!));
    } else {
      print("Streaming from network and starting download...");
      try {
        final audioUrl = await _apiService.getAudioUrl(song.id);
        await audioPlayer.play(UrlSource(audioUrl));
        _downloadController.downloadSong(song);
      } catch (e) {
        print("Error streaming song: $e");
        Get.snackbar('Playback Error', 'Could not play the selected song.');
      }
    }
  }

  Future<void> _fetchRelatedSongs(Song song) async {
    isLoadingQueue.value = true;
    try {
      // Try multiple strategies to get related songs
      List<Song> relatedSongs = [];

      // Strategy 1: Get songs by the same artist
      try {
        final artistSongs = await _apiService.searchSongs(
          song.artist,
          limit: 5,
        );
        relatedSongs.addAll(artistSongs.where((s) => s.id != song.id));
      } catch (e) {
        print("Error fetching artist songs: $e");
      }

      // Strategy 2: Get songs with similar title/theme
      try {
        final titleWords = song.title.split(' ');
        if (titleWords.length > 1) {
          // Use the most significant word (longest) for search
          final searchTerm = titleWords.reduce(
            (a, b) => a.length > b.length ? a : b,
          );
          if (searchTerm.length > 3) {
            // Only use meaningful words
            final similarSongs = await _apiService.searchSongs(
              searchTerm,
              limit: 5,
            );
            relatedSongs.addAll(similarSongs.where((s) => s.id != song.id));
          }
        }
      } catch (e) {
        print("Error fetching similar title songs: $e");
      }

      // Strategy 3: Get YouTube's recommended songs
      try {
        final recommendedSongs = await _apiService.getSimilarSongs(song.id);
        relatedSongs.addAll(recommendedSongs.where((s) => s.id != song.id));
      } catch (e) {
        print("Error fetching recommended songs: $e");
      }

      // Remove duplicates and limit to 10 songs
      final uniqueSongs = <String, Song>{};
      for (var song in relatedSongs) {
        if (!uniqueSongs.containsKey(song.id)) {
          uniqueSongs[song.id] = song;
        }
      }

      final finalList = uniqueSongs.values.toList();

      // If we still don't have enough songs, add some popular ones as fallback
      if (finalList.length < 5) {
        try {
          final popularSongs = await _apiService.searchSongs(
            'popular songs',
            limit: 10,
          );
          for (var popularSong in popularSongs) {
            if (finalList.length >= 10) break;
            if (popularSong.id != song.id &&
                !uniqueSongs.containsKey(popularSong.id)) {
              finalList.add(popularSong);
              uniqueSongs[popularSong.id] = popularSong;
            }
          }
        } catch (e) {
          print("Error fetching popular songs: $e");
        }
      }

      // Shuffle the list to add variety
      finalList.shuffle();

      // Limit to maximum 10 songs in queue
      final limitedList = finalList.take(10).toList();

      queue.value = [song, ...limitedList];
      currentIndex.value = 0;

      if (limitedList.isEmpty) {
        Get.snackbar(
          'Info',
          'No related songs found. Add songs to queue manually.',
        );
      }
    } catch (e) {
      print("Error fetching related songs: $e");
      // If we can't get related songs, at least add the current song to queue
      queue.value = [song];
      currentIndex.value = 0;
      Get.snackbar('Queue Error', 'Could not load related songs.');
    } finally {
      isLoadingQueue.value = false;
    }
  }

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
      print("Error fetching more songs: $e");
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
    audioPlayer.dispose();
    _apiService.dispose();
    super.onClose();
  }
}
