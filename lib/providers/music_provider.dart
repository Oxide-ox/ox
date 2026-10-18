import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser; 

class MusicProvider with ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  // State Data
  List<dynamic> searchResults = [];
  List<dynamic> myPlaylist = [];
  List<dynamic> activeQueue = [];

  bool isSearching = false;
  bool isPlaying = false;
  bool isLoadingAudio = false;

  int? currentIndex;
  Map<String, dynamic>? currentSong;

  // State Lirik
  String? currentLyrics;
  bool isLoadingLyrics = false;

  MusicProvider() {
    _loadPlaylist();

    _player.playerStateStream.listen((state) {
      isPlaying = state.playing;
      notifyListeners();
      
      if (state.processingState == ProcessingState.completed) {
        nextSong();
      }
    });
  }

  // --- FITUR SHARED PREFERENCES ---
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

  // --- FITUR PENCARIAN ---
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
  
  // --- FITUR PEMUTAR ---
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

    // Otomatis cari lirik saat lagu baru diputar
    fetchLyrics(currentSong!['title'], currentSong!['artist']);

    try {
      final spotifyUrl = Uri.encodeComponent(currentSong!['url']);
      
      // MENGGUNAKAN API DOWNLOADER BARU
      final dlUrl = Uri.parse("https://api.snowping.cfd/api/downloader/spotify?url=$spotifyUrl");
      
      final response = await http.get(dlUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // FORMAT JSON BARU (status 200 & download_url)
        if (data['status'] == 200 && data['result'] != null) {
          final mp3Url = data['result']['download_url']; 
          
          final mediaItem = MediaItem(
            id: currentSong!['url'],
            album: currentSong!['album'] ?? "Unknown Album",
            title: currentSong!['title'],
            artist: currentSong!['artist'],
            // Mengambil cover dari API baru jika thumbnail bawaan tidak ada
            artUri: Uri.parse(currentSong!['thumbnail'] ?? data['result']['cover'] ?? ''),
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

  // --- FITUR PLAYLIST ---
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

  // --- FITUR LIRIK FRONTEND ---
  Future<void> fetchLyrics(String title, String artist) async {
    isLoadingLyrics = true;
    notifyListeners();

    try {
      final query = Uri.encodeComponent("$title $artist");
      
      final searchUrl = Uri.parse("https://genius.com/api/search/multi?q=$query");
      final searchResponse = await http.get(searchUrl, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept': 'application/json'
      });

      if (searchResponse.statusCode == 200) {
        final jsonResp = json.decode(searchResponse.body);
        String? targetUrl;

        final sections = jsonResp['response']['sections'] as List;
        for (var section in sections) {
          if (section['type'] == 'song' || section['type'] == 'top_hit') {
            final hits = section['hits'] as List;
            for (var hit in hits) {
              if (hit['type'] == 'song' && hit['result'] != null && hit['result']['url'] != null) {
                targetUrl = hit['result']['url'];
                break;
              }
            }
          }
          if (targetUrl != null) break;
        }

        if (targetUrl != null) {
          final lyricResponse = await http.get(Uri.parse(targetUrl), headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
          });

          if (lyricResponse.statusCode == 200) {
            var document = html_parser.parse(lyricResponse.body);
            var containers = document.querySelectorAll('div[data-lyrics-container="true"]');

            if (containers.isNotEmpty) {
              List<String> lyricSections = [];
              for (var container in containers) {
                container.innerHtml = container.innerHtml.replaceAll('<br>', '\n').replaceAll('<br/>', '\n');
                lyricSections.add(container.text.trim());
              }

              String finalLyrics = lyricSections.join('\n\n')
                  .replaceAll(RegExp(r'^[0-9]+\s+Contributors.*?\n', caseSensitive: false), '')
                  .replaceAll(RegExp(r'^Translations.*?\n', caseSensitive: false), '')
                  .replaceAll(RegExp(r'\[([^\]]+)\]'), '\n[\$1]')
                  .replaceAll(RegExp(r'\n{3,}'), '\n\n')
                  .trim();

              currentLyrics = finalLyrics;
            } else {
              currentLyrics = "Lirik tidak ditemukan.";
            }
          } else {
            currentLyrics = "Gagal mengakses halaman lirik.";
          }
        } else {
          currentLyrics = "Lagu tidak ditemukan di database lirik.";
        }
      } else {
        currentLyrics = "Gagal terhubung ke API lirik.";
      }
    } catch (e) {
      currentLyrics = "Terjadi kesalahan saat memproses lirik.";
      debugPrint("Error fetching lyrics: $e");
    }

    isLoadingLyrics = false;
    notifyListeners();
  }

  // --- KONTROL MEDIA ---
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
