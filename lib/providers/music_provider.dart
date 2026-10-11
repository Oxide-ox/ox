import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../btrapps/.dart';
final baseUrl = Api.api;

class MusicProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  // ===========================================================================
  // 1. STATE DATA
  // ===========================================================================
  List<dynamic> searchResults = [];
  List<dynamic> myPlaylist = [];
  List<dynamic> activeQueue = [];

  bool isSearching = false;
  bool isPlaying = false;
  bool isLoadingAudio = false;

  int? currentIndex;
  Map<String, dynamic>? currentSong;

  // ===========================================================================
  // 2. STATE LIRIK
  // ===========================================================================
  String? currentLyrics;
  bool isLoadingLyrics = false;

  MusicProvider() {
    _loadPlaylist(); // Load data favorit dari memori saat aplikasi baru dibuka

    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
      
      if (state.processingState == ProcessingState.completed) {
        nextSong();
      }
    });
  }

  // ===========================================================================
  // 3. FITUR SHARED PREFERENCES (SIMPAN PERMANEN)
  // ===========================================================================
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

  // ===========================================================================
  // 4. FITUR PENCARIAN & PEMUTAR
  // ===========================================================================
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
    currentLyrics = null;
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

  // ===========================================================================
  // 5. FITUR PLAYLIST (FAVORIT)
  // ===========================================================================
  void togglePlaylist(dynamic song) {
    final exists = myPlaylist.any((s) => s['url'] == song['url']);
    if (exists) {
      myPlaylist.removeWhere((s) => s['url'] == song['url']);
    } else {
      myPlaylist.add(song);
    }
    
    _savePlaylist(); // Eksekusi simpan ke memori HP setiap ada perubahan
    notifyListeners();
  }

  bool isSaved(dynamic song) {
    return myPlaylist.any((s) => s['url'] == song['url']);
  }

  void shufflePlaylist() {
    if (myPlaylist.isEmpty) return;
    myPlaylist.shuffle();
    _savePlaylist(); // Simpan urutan terbaru ke memori
    notifyListeners();
    playPlaylistSong(0); 
  }

  // ===========================================================================
  // 6. FITUR LIRIK
  // ===========================================================================
  Future<void> fetchLyrics(String title, String artist) async {
    isLoadingLyrics = true;
    currentLyrics = null;
    notifyListeners();

    try {
      final query = Uri.encodeComponent("$title $artist");
      final url = Uri.parse("$baseUrl/tools/genius?q=$query");
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 200 && data['data'] != null) {
          currentLyrics = data['data']['lyrics'];
        } else {
          currentLyrics = "Lirik tidak ditemukan di Genius.";
        }
      } else {
        currentLyrics = "Gagal memuat lirik dari server.";
      }
    } catch (e) {
      currentLyrics = "Terjadi kesalahan koneksi saat memuat lirik.";
      debugPrint("Error fetching lyrics: $e");
    }

    isLoadingLyrics = false;
    notifyListeners();
  }

  // ===========================================================================
  // 7. KONTROL MEDIA
  // ===========================================================================
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
