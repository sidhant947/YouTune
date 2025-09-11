// lib/blocs/audio_player/audio_player_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/song.dart';
import '../../services/api_service.dart';
import '../../services/database_service.dart';
import '../download/download_bloc.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' as foundation;
part 'audio_player_event.dart';
part 'audio_player_state.dart';

class AudioPlayerBloc extends Bloc<AudioPlayerEvent, AudioPlayerState> {
  final DatabaseService databaseService;
  final DownloadBloc downloadBloc;
  late final AudioPlayer audioPlayer;
  late final ApiService apiService;
  String? _currentDownloadingSongId;

  AudioPlayerBloc({required this.databaseService, required this.downloadBloc})
    : apiService = ApiService(),
      super(const AudioPlayerState()) {
    audioPlayer = AudioPlayer();

    on<PlaySong>(_onPlaySong);
    on<PauseSong>(_onPauseSong);
    on<ResumeSong>(_onResumeSong);
    on<SeekSong>(_onSeekSong);
    on<PlayNext>(_onPlayNext);
    on<PlayPrevious>(_onPlayPrevious);
    on<AddToQueue>(_onAddToQueue);
    on<AddMultipleToQueue>(_onAddMultipleToQueue);
    on<RemoveFromQueue>(_onRemoveFromQueue);
    on<ClearQueue>(_onClearQueue);
    on<ShuffleQueue>(_onShuffleQueue);
    on<_UpdatePosition>(_onUpdatePosition);
    on<_UpdateDuration>(_onUpdateDuration);
    on<_UpdateIsPlaying>(_onUpdateIsPlaying);
    on<_UpdateIsLoadingQueue>(_onUpdateIsLoadingQueue);
    on<_UpdateIsPreparing>(_onUpdateIsPreparing);

    audioPlayer.onPlayerStateChanged.listen((playerState) {
      add(_UpdateIsPlaying(playerState == PlayerState.playing));
    });
    audioPlayer.onDurationChanged.listen((d) {
      add(_UpdateDuration(d));
    });
    audioPlayer.onPositionChanged.listen((p) {
      add(_UpdatePosition(p));
    });
    audioPlayer.onPlayerComplete.listen((_) {
      add(PlayNext());
    });
  }

  void _onPlaySong(PlaySong event, Emitter<AudioPlayerState> emit) async {
    final song = event.song;
    final addToQueue = event.addToQueue;
    final queueAllDownloaded = event.queueAllDownloaded;

    emit(state.copyWith(isPreparing: true));

    // If it's the same song, toggle play/pause
    if (state.currentSong?.id == song.id) {
      if (audioPlayer.state == PlayerState.playing) {
        add(PauseSong());
      } else {
        add(ResumeSong());
      }
      emit(state.copyWith(isPreparing: false));
      return;
    }

    // Stop the previous song if it's different
    final previousSongId = state.currentSong?.id;
    if (previousSongId != null && previousSongId != song.id) {
      await audioPlayer.stop();
    }

    // Update the current song in state (before playing)
    emit(
      state.copyWith(
        currentSong: song,
        duration: Duration.zero,
        position: Duration.zero,
      ),
    );

    try {
      // Check if we need to set up a new queue based on the event flags
      if (addToQueue && (state.queue.isEmpty || state.queue[0].id != song.id)) {
        // Only fetch related songs if NOT queueing all downloaded or playing from artist screen
        if (queueAllDownloaded) {
          // Handle DownloadsScreen case
          final allDownloadedSongs = downloadBloc.state.downloadedSongs;
          if (allDownloadedSongs.isNotEmpty) {
            final songIndex = allDownloadedSongs.indexWhere(
              (s) => s.id == song.id,
            );
            final newIndex = songIndex >= 0 ? songIndex : 0;
            emit(
              state.copyWith(queue: allDownloadedSongs, currentIndex: newIndex),
            );
          } else {
            // Fallback if somehow queueAllDownloaded is true but no downloads
            emit(state.copyWith(queue: [song], currentIndex: 0));
          }
        } else {
          // Fetch related songs for general play (e.g., from Search)
          await _fetchRelatedSongs(song, emit);
        }
      } else {
        // If addToQueue is false (like playing from queue or artist screen after queue is set),
        // we need to ensure the queue is correct and the currentIndex points to the played song.
        if (!addToQueue) {
          final currentQueue = state.queue;
          final currentIndexInQueue = currentQueue.indexWhere(
            (s) => s.id == song.id,
          );
          if (currentIndexInQueue != -1) {
            // Song is in the current queue, update index to play it
            // The queue itself is assumed to be correctly set by a prior AddMultipleToQueue
            emit(state.copyWith(currentIndex: currentIndexInQueue));
          } else {
            // This is an edge case: addToQueue is false, but song isn't in the queue.
            // Fallback to playing just this song. This shouldn't normally happen
            // if AddMultipleToQueue was called first for the artist screen.
            foundation.debugPrint(
              "Warning: PlaySong called with addToQueue=false, but song ${song.id} not found in queue. Playing song alone.",
            );
            emit(state.copyWith(queue: [song], currentIndex: 0));
          }
        }
        // If addToQueue is true but the song is already the first in the queue,
        // we don't need to modify the queue, just play the song at currentIndex 0.
        // The main logic above handles fetching related songs if the queue is empty
        // or doesn't start with this song.
      }

      // Determine if the song is downloaded
      final downloadedSong = databaseService.getSong(song.id);
      if (downloadedSong?.filePath != null &&
          downloadedSong!.filePath!.isNotEmpty &&
          File(downloadedSong.filePath!).existsSync()) {
        // Play from local file
        await audioPlayer.play(DeviceFileSource(downloadedSong.filePath!));
        // Trigger download in background (e.g., to update status if needed)
        downloadBloc.add(DownloadSong(song));
      } else {
        // Stream from URL
        final audioUrl = await apiService.getAudioUrl(song.id);
        await audioPlayer.play(UrlSource(audioUrl));
        // Mark this song ID as the one currently being downloaded
        _currentDownloadingSongId = song.id;
        // Start the download process
        downloadBloc.add(DownloadSong(song));
      }
    } catch (e) {
      foundation.debugPrint("Error playing/streaming song: $e");
      // Clear downloading ID on error
      if (_currentDownloadingSongId == song.id) {
        _currentDownloadingSongId = null;
      }
    } finally {
      // Indicate that preparation (fetching URL, starting playback) is done
      emit(state.copyWith(isPreparing: false));
    }
  }

  Future<void> _fetchRelatedSongs(
    Song song,
    Emitter<AudioPlayerState> emit,
  ) async {
    emit(state.copyWith(isLoadingQueue: true));
    try {
      List<Song> relatedSongs = [];

      // 1. Fetch songs by the same artist
      try {
        final artistSongs = await apiService.searchSongs(
          song.artist,
          limit: 15,
        );
        relatedSongs.addAll(artistSongs.where((s) => s.id != song.id));
      } catch (e) {
        foundation.debugPrint("Error fetching artist songs: $e");
      }

      // 2. Fetch recommended songs based on the current song
      try {
        final recommendedSongs = await apiService.getSimilarSongs(song.id);
        relatedSongs.addAll(recommendedSongs.where((s) => s.id != song.id));
      } catch (e) {
        foundation.debugPrint("Error fetching recommended songs: $e");
      }

      // 3. Deduplicate the combined list
      final uniqueSongs = <String, Song>{};
      for (var s in relatedSongs) {
        if (!uniqueSongs.containsKey(s.id)) {
          uniqueSongs[s.id] = s;
        }
      }

      // 4. Convert to list and potentially add more songs if the list is small
      final finalList = uniqueSongs.values.toList();
      if (finalList.length < 20) {
        try {
          // Fetch popular songs to fill up the queue if needed
          final popularSongs = await apiService.searchSongs(
            'popular songs',
            limit: 10,
          );
          for (var popularSong in popularSongs) {
            if (finalList.length >= 30) break; // Limit total queue size
            if (popularSong.id != song.id &&
                !uniqueSongs.containsKey(popularSong.id)) {
              finalList.add(popularSong);
              uniqueSongs[popularSong.id] = popularSong;
            }
          }
        } catch (e) {
          foundation.debugPrint("Error fetching popular songs: $e");
        }
      }

      // 5. Shuffle the related songs for variety
      finalList.shuffle();

      // 6. Limit the final list and update the state
      // The queue will be: [currently playing song, ...shuffled related songs]
      final limitedList = finalList.take(30).toList();
      emit(state.copyWith(queue: [song, ...limitedList], currentIndex: 0));
    } catch (e) {
      foundation.debugPrint("Error fetching related songs: $e");
      // Fallback: queue just the current song if fetching fails
      emit(state.copyWith(queue: [song], currentIndex: 0));
    } finally {
      // Indicate that queue loading is complete
      emit(state.copyWith(isLoadingQueue: false));
    }
  }

  void _onPauseSong(PauseSong event, Emitter<AudioPlayerState> emit) async {
    await audioPlayer.pause();
  }

  void _onResumeSong(ResumeSong event, Emitter<AudioPlayerState> emit) async {
    await audioPlayer.resume();
  }

  void _onSeekSong(SeekSong event, Emitter<AudioPlayerState> emit) async {
    await audioPlayer.seek(event.position);
  }

  void _onPlayNext(PlayNext event, Emitter<AudioPlayerState> emit) async {
    // Check if there's a next song in the queue
    if (state.queue.isEmpty || state.currentIndex >= state.queue.length - 1) {
      // No next song, stop playback or loop back (depending on desired behavior)
      // For now, we'll stop. You could implement looping here.
      if (state.currentSong != null) {
        await audioPlayer.stop();
        // Optionally restart the current song or show end of queue message
        // add(PlaySong(state.currentSong!, addToQueue: false)); // Example: restart
      }
      return;
    }

    // Stop the current audio
    await audioPlayer.stop();

    // Calculate the new index
    final newIndex = state.currentIndex + 1;

    // Update the current index in the state
    emit(state.copyWith(currentIndex: newIndex));

    // Play the next song in the queue (without modifying the queue again)
    add(PlaySong(state.queue[newIndex], addToQueue: false));
  }

  void _onPlayPrevious(
    PlayPrevious event,
    Emitter<AudioPlayerState> emit,
  ) async {
    // Check if there's a previous song (index must be greater than 0)
    if (state.currentIndex <= 0) return;

    // Stop the current audio
    await audioPlayer.stop();

    // Calculate the new index
    final newIndex = state.currentIndex - 1;

    // Update the current index in the state
    emit(state.copyWith(currentIndex: newIndex));

    // Play the previous song in the queue (without modifying the queue again)
    add(PlaySong(state.queue[newIndex], addToQueue: false));
  }

  void _onAddToQueue(AddToQueue event, Emitter<AudioPlayerState> emit) {
    final song = event.song;
    // Create a new list based on the current queue
    final newQueue = List<Song>.from(state.queue);

    // Insert the song right after the currently playing song
    // If the queue is empty or currentIndex is somehow invalid, add to the end
    if (state.currentIndex < newQueue.length) {
      newQueue.insert(state.currentIndex + 1, song);
    } else {
      newQueue.add(song);
    }

    // Update the state with the new queue
    emit(state.copyWith(queue: newQueue));
  }

  void _onAddMultipleToQueue(
    AddMultipleToQueue event,
    Emitter<AudioPlayerState> emit,
  ) {
    final songs = event.songs;
    // Create a new list based on the current queue and add the new songs
    final newQueue = List<Song>.from(state.queue)..addAll(songs);

    // Update the state with the new queue
    emit(state.copyWith(queue: newQueue));
  }

  void _onRemoveFromQueue(
    RemoveFromQueue event,
    Emitter<AudioPlayerState> emit,
  ) {
    final index = event.index;
    // Ensure the index is valid and after the current playing index
    if (index > state.currentIndex && index < state.queue.length) {
      // Create a new list and remove the song at the specified index
      final newQueue = List<Song>.from(state.queue)..removeAt(index);

      // Update the state with the new queue
      emit(state.copyWith(queue: newQueue));
    }
  }

  void _onClearQueue(ClearQueue event, Emitter<AudioPlayerState> emit) {
    final current = state.currentSong;
    // Clear the queue, keeping only the currently playing song (if any) at index 0
    emit(
      state.copyWith(queue: current != null ? [current] : [], currentIndex: 0),
    );
  }

  void _onShuffleQueue(ShuffleQueue event, Emitter<AudioPlayerState> emit) {
    // Cannot shuffle if there's only one song or the queue is empty
    if (state.queue.length <= 1) return;

    // Get the currently playing song
    final current = state.queue[state.currentIndex];
    // Get the remaining songs (after the current one)
    final remainingSongs = state.queue.sublist(state.currentIndex + 1);
    // Shuffle the remaining songs
    remainingSongs.shuffle();

    // Create a new queue: [current song, ...shuffled remaining songs]
    emit(state.copyWith(queue: [current, ...remainingSongs], currentIndex: 0));
  }

  // --- Internal Event Handlers ---

  void _onUpdatePosition(
    _UpdatePosition event,
    Emitter<AudioPlayerState> emit,
  ) {
    // Update the current playback position in the state
    emit(state.copyWith(position: event.position));
  }

  void _onUpdateDuration(
    _UpdateDuration event,
    Emitter<AudioPlayerState> emit,
  ) {
    // Update the total duration of the current song in the state
    emit(state.copyWith(duration: event.duration));
  }

  void _onUpdateIsPlaying(
    _UpdateIsPlaying event,
    Emitter<AudioPlayerState> emit,
  ) {
    // Update the playing/paused state in the state
    emit(state.copyWith(isPlaying: event.isPlaying));
  }

  void _onUpdateIsLoadingQueue(
    _UpdateIsLoadingQueue event,
    Emitter<AudioPlayerState> emit,
  ) {
    // Update the queue loading state in the state
    emit(state.copyWith(isLoadingQueue: event.isLoading));
  }

  void _onUpdateIsPreparing(
    _UpdateIsPreparing event,
    Emitter<AudioPlayerState> emit,
  ) {
    // Update the preparing state (getting URL, starting playback) in the state
    emit(state.copyWith(isPreparing: event.isPreparing));
  }

  @override
  Future<void> close() {
    // Clean up resources when the bloc is closed
    audioPlayer.dispose();
    apiService.dispose();
    return super.close();
  }
}
