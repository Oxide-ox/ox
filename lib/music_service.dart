import 'dart:async';
import 'package:just_audio/just_audio.dart';

class MusicService {
  MusicService._();

  static final AudioPlayer player = AudioPlayer();

  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get stateStream =>
      _controller.stream;

  static String currentTitle = "Tidak ada lagu";
  static String currentArtist = "";
  static String currentImage = "";

  static Future<void> playSong({
    required String url,
    required String title,
    String artist = "",
    String image = "",
  }) async {
    currentTitle = title;
    currentArtist = artist;
    currentImage = image;

    await player.setUrl(url);
    await player.play();

    _controller.add(null);
  }

  static Future<void> pause() async {
    await player.pause();
    _controller.add(null);
  }

  static Future<void> resume() async {
    await player.play();
    _controller.add(null);
  }

  static Future<void> stop() async {
    await player.stop();

    currentTitle = "Tidak ada lagu";
    currentArtist = "";
    currentImage = "";

    _controller.add(null);
  }

  static bool get isPlaying =>
      player.playing;

  static Stream<Duration> get positionStream =>
      player.positionStream;

  static Stream<Duration?> get durationStream =>
      player.durationStream;
}