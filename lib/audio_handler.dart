import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.prikitiww.apps.channel.audio',
      androidNotificationChannelName: 'Prikitiww Music Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidShowNotificationBadge: true,
    ),
  );
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MyAudioHandler() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });

    _player.durationStream.listen((Duration? duration) {
      if (duration != null && mediaItem.value != null) {
        mediaItem.add(mediaItem.value!.copyWith(duration: duration));
      }
    });
  }

  Stream<Duration> get positionStream => _player.positionStream;
  AudioPlayer get player => _player;

  Future<void> playCustomSong({
    required String id,
    required String title,
    required String artist,
    required String artworkUrl,
    required String audioUrl,
    Duration? duration,
  }) async {
    final item = MediaItem(
      id: id,
      title: title,
      artist: artist,
      artUri: Uri.tryParse(artworkUrl),
      duration: duration ?? const Duration(minutes: 3),
    );

    mediaItem.add(item);

    try {
      await _player.stop();

      if (audioUrl.startsWith('http')) {
        final audioSource = AudioSource.uri(
          Uri.parse(audioUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          },
        );
        await _player.setAudioSource(audioSource);
      } else if (audioUrl.isNotEmpty) {
        await _player.setAsset(audioUrl);
      }

      await _player.play();
    } catch (e) {
      print("❌ Error playCustomSong: $e");
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
}