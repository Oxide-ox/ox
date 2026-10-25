import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class MusicProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  List<dynamic> searchResults = [];
  bool isSearching = false;
  bool isPlaying = false;
  
  int? currentIndex;
  Map<String, dynamic>? currentSong;
  bool isLoadingAudio = false;

  MusicProvider() {
    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
      
      if (state.processingState == ProcessingState.completed) {
        nextSong();
      }
    });
  }

  Future<void> searchMusic(String query) async {
    isSearching = true;
    notifyListeners();
    try {
      final url = Uri.parse("https://api.nexray.eu.cc/search/spotify?q=$query");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          searchResults = (data['result'] as List).take(20).toList();
        }
      }
    } catch (e) {
      debugPrint("Error search: $e");
    }
    isSearching = false;
    notifyListeners();
  }

  Future<void> playSong(int index) async {
    currentIndex = index;
    currentSong = searchResults[index];
    isLoadingAudio = true;
    notifyListeners();

    try {
      final spotifyUrl = Uri.encodeComponent(currentSong!['url']);
      final dlUrl = Uri.parse("https://api.nexray.eu.cc/downloader/spotify?url=$spotifyUrl");
      
      final response = await http.get(dlUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final mp3Url = data['result']['url'];
          
          final mediaItem = MediaItem(
            id: currentSong!['url'],
            album: currentSong!['album'] ?? "Unknown Album",
            title: currentSong!['title'],
            artist: currentSong!['artist'],
            artUri: Uri.parse(currentSong!['thumbnail']),
          );

          await _player.setAudioSource(
            AudioSource.uri(Uri.parse(mp3Url), tag: mediaItem),
          );
          _player.play();
        }
      }
    } catch (e) {
      debugPrint("Error playing: $e");
    }
    isLoadingAudio = false;
    notifyListeners();
  }

  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void nextSong() {
    if (currentIndex != null && currentIndex! < searchResults.length - 1) {
      playSong(currentIndex! + 1);
    }
  }

  void previousSong() {
    if (currentIndex != null && currentIndex! > 0) {
      playSong(currentIndex! - 1);
    }
  }
}
