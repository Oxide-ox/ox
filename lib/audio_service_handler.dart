import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'soundcloud_scraper.dart'; 

late AudioHandler _audioHandler;

Future<AudioHandler> initAudioService() async {
  _audioHandler = await AudioService.init(
    builder: () => AudioServiceHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.oxide.app',
      androidNotificationChannelName: 'Oxide Playback',
      androidNotificationChannelDescription: 'Oxide Music Service',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    //  androidNotificationClickStartsService: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      notificationColor: Color(0xFF8B5CF6),
    ),
  );
  return _audioHandler;
}

class AudioServiceHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  AudioServiceHandler() {
    _setupListeners();
  }

  void _setupListeners() {
    // Pipe status playback ke AudioService state
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Update MediaItem yang sedang diputar ke sistem (Notification bar)
    _player.sequenceStateStream.listen((sequenceState) {
      final sequence = sequenceState?.sequence ?? [];
      final index = sequenceState?.currentIndex ?? 0;
      if (index < sequence.length) {
        final item = sequence[index].tag as MediaItem?;
        this.mediaItem.add(item); // PERBAIKAN: Gunakan this.mediaItem.add()
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // Method khusus untuk memutar SoundCloudTrack
  Future<void> playSoundCloudTrack(SoundCloudTrack track) async {
    try {
      // 1. Ekstrak URL audio langsung via scraper
      final directAudioUrl = await SoundCloudScraper.getDirectDownloadUrl(track.url);
      
      if (directAudioUrl.isEmpty) {
        throw Exception("URL Audio tidak ditemukan");
      }

      // 2. Buat MediaItem dengan metadata lengkap dari SoundCloudTrack
      final item = MediaItem(
        id: track.trackId.toString(),
        title: track.title,
        artist: track.artist.name,
        artUri: Uri.tryParse(track.thumbnail),
        duration: track.duration, // PERBAIKAN: Gunakan durasi asli track
      );

      // 3. Set Audio Source & Mainkan
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(directAudioUrl), tag: item),
      );
      
      this.mediaItem.add(item);
      await _player.play();
    } catch (e) {
      debugPrint("Error playSoundCloudTrack: $e");
      rethrow;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }
}
