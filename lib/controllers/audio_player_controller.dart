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

  // NEW: Reactive variables to hold the player's state.
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
  }

  Future<void> play(Song song) async {
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

  Future<void> pause() async {
    await audioPlayer.pause();
  }

  Future<void> resume() async {
    await audioPlayer.resume();
  }

  @override
  void onClose() {
    audioPlayer.dispose();
    _apiService.dispose();
    super.onClose();
  }
}
