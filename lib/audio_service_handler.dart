import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
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
      androidNotificationIcon: 'mipmap/ic_launcher',
      notificationColor: Color(0xFF8B5CF6),
    ),
  );
  return _audioHandler;
}

class AudioServiceHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  bool _initialized = false;

  AudioServiceHandler() {
    _setupListeners();
  }

  void _setupListeners() {
    try {
      _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

      _player.sequenceStateStream.listen((sequenceState) {
        try {
          final sequence = sequenceState?.sequence ?? [];
          final index = sequenceState?.currentIndex ?? 0;
          if (index < sequence.length) {
            final item = sequence[index].tag as MediaItem?;
            if (item != null) mediaItem.add(item);
          }
        } catch (e) {
          debugPrint('Error updating media item: $e');
        }
      });

      _initialized = true;
      debugPrint('✅ AudioServiceHandler initialized');
    } catch (e) {
      debugPrint('❌ Error setup listeners: $e');
    }
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

  Future<void> playSoundCloudTrack(SoundCloudTrack track) async {
    try {
      debugPrint('🎵 Playing: ${track.title}');
      final directAudioUrl = await SoundCloudScraper.getDirectDownloadUrl(track.url);

      if (directAudioUrl.isEmpty) {
        throw Exception('❌ URL Audio tidak ditemukan');
      }

      debugPrint('🔗 Audio URL: $directAudioUrl');

      final item = MediaItem(
        id: track.trackId.toString(),
        title: track.title,
        artist: track.artist.name,
        artUri: Uri.tryParse(track.thumbnail),
        duration: track.duration,
      );

      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(directAudioUrl), tag: item),
      );

      mediaItem.add(item);
      await _player.play();
      debugPrint('✅ Playing');
    } catch (e) {
      debugPrint('❌ Error playSoundCloudTrack: $e');
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
