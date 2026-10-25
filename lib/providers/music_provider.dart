import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}

class MusicProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  List<dynamic> searchResults = [];
  List<dynamic> myPlaylist = [];
  List<dynamic> activeQueue = [];

  bool isSearching = false;
  bool isPlaying = false;
  bool isLoadingAudio = false;

  int? currentIndex;
  Map<String, dynamic>? currentSong;

  List<LyricLine> syncedLyrics = [];
  int currentLyricIndex = -1;
  bool isLoadingLyrics = false;
  String? lyricErrorMessage;

  MusicProvider() {
    _loadPlaylist();

    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
      
      if (state.processingState == ProcessingState.completed) {
        nextSong();
      }
    });

    _player.positionStream.listen((position) {
      _updateLyricIndex(position);
    });
  }

  void _updateLyricIndex(Duration position) {
    if (syncedLyrics.isEmpty) return;

    int newIndex = -1;
    for (int i = 0; i < syncedLyrics.length; i++) {
      if (position >= syncedLyrics[i].time) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != currentLyricIndex) {
      currentLyricIndex = newIndex;
      notifyListeners();
    }
  }

  Future<void> _loadPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedPlaylist = prefs.getString('saved_playlist');
    if (savedPlaylist != null) {
      myPlaylist = json.decode(savedPlaylist);
      notifyListeners();
    }
  }

  Future<void> _savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(myPlaylist);
    await prefs.setString('saved_playlist', encodedData);
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
    activeQueue = List.from(searchResults); 
    await _playAudioAt(index);
  }

  Future<void> playPlaylistSong(int index) async {
    activeQueue = List.from(myPlaylist); 
    await _playAudioAt(index);
  }

  Future<void> _playAudioAt(int index) async {
    if (activeQueue.isEmpty || index < 0 || index >= activeQueue.length) return;

    currentIndex = index;
    currentSong = activeQueue[index];
    
    isLoadingAudio = true;
    syncedLyrics = [];
    currentLyricIndex = -1;
    lyricErrorMessage = null;
    notifyListeners();

    fetchSyncedLyrics(currentSong!['title'], currentSong!['artist']);

    try {
      final spotifyUrl = Uri.encodeComponent(currentSong!['url']);
      final dlUrl = Uri.parse("https://api.nexray.eu.cc/downloader/spotify?url=$spotifyUrl");
      
      final response = await http.get(dlUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == true && data['result'] != null && data['result']['url'] != null) {
          final mp3Url = data['result']['url']; 
          
          final mediaItem = MediaItem(
            id: currentSong!['url'],
            album: currentSong!['album'] ?? "Single",
            title: currentSong!['title'] ?? data['result']['title'] ?? "Unknown Title",
            artist: currentSong!['artist'] ?? data['result']['artist'] ?? "Unknown Artist",
            artUri: Uri.parse(currentSong!['thumbnail'] ?? ''),
          );

          await _player.setAudioSource(
            AudioSource.uri(Uri.parse(mp3Url), tag: mediaItem),
          );
          
          _player.play();
        }
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
    
    isLoadingAudio = false;
    notifyListeners();
  }

  Future<void> fetchSyncedLyrics(String title, String artist) async {
    isLoadingLyrics = true;
    notifyListeners();

    try {
      final queryTitle = Uri.encodeComponent(title);
      final queryArtist = Uri.encodeComponent(artist);

      final url = Uri.parse("https://lrclib.net/api/get?track_name=$queryTitle&artist_name=$queryArtist");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String? rawSyncedLyrics = data['syncedLyrics'];

        if (rawSyncedLyrics != null && rawSyncedLyrics.isNotEmpty) {
          syncedLyrics = _parseLrc(rawSyncedLyrics);
        } else {
          lyricErrorMessage = "Lirik synced tidak tersedia.";
        }
      } else {
        final searchUrl = Uri.parse("https://lrclib.net/api/search?q=$queryTitle $queryArtist");
        final searchRes = await http.get(searchUrl);
        if (searchRes.statusCode == 200) {
          final List searchData = json.decode(searchRes.body);
          if (searchData.isNotEmpty && searchData[0]['syncedLyrics'] != null) {
            syncedLyrics = _parseLrc(searchData[0]['syncedLyrics']);
          } else {
            lyricErrorMessage = "Lirik tidak ditemukan.";
          }
        }
      }
    } catch (e) {
      lyricErrorMessage = "Gagal memuat lirik.";
      debugPrint("Error fetching synced lyrics: $e");
    }

    isLoadingLyrics = false;
    notifyListeners();
  }

  List<LyricLine> _parseLrc(String lrcString) {
    final lines = lrcString.split('\n');
    final List<LyricLine> parsedList = [];
    final regExp = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\](.*)');

    for (var line in lines) {
      final match = regExp.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();

        if (text.isNotEmpty) {
          final duration = Duration(
            minutes: minutes,
            seconds: seconds.truncate(),
            milliseconds: ((seconds - seconds.truncate()) * 1000).round(),
          );
          parsedList.add(LyricLine(time: duration, text: text));
        }
      }
    }

    parsedList.sort((a, b) => a.time.compareTo(b.time));
    return parsedList;
  }

  void togglePlaylist(dynamic song) {
    final exists = myPlaylist.any((s) => s['url'] == song['url']);
    if (exists) {
      myPlaylist.removeWhere((s) => s['url'] == song['url']);
    } else {
      myPlaylist.add(song);
    }
    _savePlaylist(); 
    notifyListeners();
  }

  bool isSaved(dynamic song) {
    return myPlaylist.any((s) => s['url'] == song['url']);
  }

  void shufflePlaylist() {
    if (myPlaylist.isEmpty) return;
    myPlaylist.shuffle();
    _savePlaylist();
    notifyListeners();
    playPlaylistSong(0); 
  }

  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void nextSong() {
    if (currentIndex != null && currentIndex! < activeQueue.length - 1) {
      _playAudioAt(currentIndex! + 1);
    }
  }

  void previousSong() {
    if (currentIndex != null && currentIndex! > 0) {
      _playAudioAt(currentIndex! - 1);
    }
  }
}
