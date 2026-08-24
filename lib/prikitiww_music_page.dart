import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';

// 🟢 GLOBAL AUDIO HANDLER DIKELOLA LANGSUNG DI FILE INI (TANPA SENTUH MAIN.DART)
AudioHandler? globalAudioHandler;

// =============================================================================
// KONSTANTA WARNA TEMA GOTHIC MAGENTA
// =============================================================================
class AppTheme {
  static const Color bgDark = Color(0xFF0D0D0E);
  static Color cardBg = const Color(0xFF160A22).withOpacity(0.9);
  static const Color primaryMagenta = Color(0xFFE6007E);
  static const Color secondaryPurple = Color(0xFF8E00C7);
  static const Color whiteText = Colors.white;
  static const Color grayText = Color(0xFFA0A0AB);
}

// =============================================================================
// MODEL DATA LAGU
// =============================================================================
class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;
  final String? permalinkUrl;
  final String? audioUrl;
  final Duration duration;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
    this.permalinkUrl,
    this.audioUrl,
    required this.duration,
  });

  bool get isNetworkImage => thumbnail.startsWith('http');

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'thumbnail': thumbnail,
        'permalinkUrl': permalinkUrl,
        'audioUrl': audioUrl,
        'durationInSeconds': duration.inSeconds,
      };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Unknown Title',
        artist: json['artist'] ?? 'SoundCloud',
        thumbnail: json['thumbnail'] ?? '',
        permalinkUrl: json['permalinkUrl'],
        audioUrl: json['audioUrl'],
        duration: Duration(seconds: json['durationInSeconds'] ?? 180),
      );
}

// =============================================================================
// MAIN MUSIC PAGE
// =============================================================================
class PrikitiwwMusicPage extends StatefulWidget {
  const PrikitiwwMusicPage({super.key});

  @override
  State<PrikitiwwMusicPage> createState() => _PrikitiwwMusicPageState();
}

class _PrikitiwwMusicPageState extends State<PrikitiwwMusicPage> {
  int _currentNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  List<Song> _searchResults = [];
  List<Song> _recentlyPlayed = [];
  bool _isSearching = false;
  bool _isLoadingAudio = false;

  Song? _currentSong;
  List<Song> _currentQueue = [];
  int _currentIndex = 0;
  bool _isLiked = false;
  bool _isShuffle = false;
  bool _isRepeat = false;

  Map<String, List<Song>> _userPlaylists = {};

  @override
  void initState() {
    super.initState();
    _initMusicPage();
  }

  // 🟢 INISIALISASI AUDIO SERVICE & PERMISSION SAAT BUKA HALAMAN INI
  Future<void> _initMusicPage() async {
    await _requestNotificationPermission();
    await _initAudioService();
    await _loadPlaylistsFromStorage();
    await _loadRecentlyPlayedFromStorage();
  }

  Future<void> _initAudioService() async {
    if (globalAudioHandler == null) {
      try {
        globalAudioHandler = await initAudioService();
        if (mounted) setState(() {});
      } catch (e) {
        debugPrint("Error init AudioService: $e");
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  // ---------------------------------------------------------------------------
  // RECENTLY PLAYED PERSISTEN (LOCAL STORAGE)
  // ---------------------------------------------------------------------------
  Future<void> _loadRecentlyPlayedFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('prikitiww_recently_played');
    if (data != null) {
      try {
        final List list = jsonDecode(data);
        setState(() {
          _recentlyPlayed = list.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
        });
      } catch (e) {
        debugPrint("Error load recently played: $e");
      }
    }
  }

  Future<void> _saveRecentlyPlayedToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(_recentlyPlayed.map((e) => e.toJson()).toList());
    await prefs.setString('prikitiww_recently_played', jsonStr);
  }

  void _addSongToRecentlyPlayed(Song song) {
    setState(() {
      _recentlyPlayed.removeWhere((s) => s.id == song.id);
      _recentlyPlayed.insert(0, song);
      if (_recentlyPlayed.length > 15) {
        _recentlyPlayed = _recentlyPlayed.sublist(0, 15);
      }
    });
    _saveRecentlyPlayedToStorage();
  }

  // ---------------------------------------------------------------------------
  // API SOUNDCLOUD SEARCH & DOWNLOADER (FRESH LINK)
  // ---------------------------------------------------------------------------
  Future<void> _searchSoundcloud(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    try {
      final url = Uri.parse(
          'http://api.ikyyxd.my.id/search/soundcloud?apikey=kyzz&query=${Uri.encodeComponent(query)}');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true && data['result'] != null) {
          final List rawList = data['result'];

          List<Song> parsedResults = [];
          for (int i = 0; i < rawList.length; i++) {
            final item = rawList[i];
            if (item['permalink_url'] == null || item['permalink'] == null) continue;

            String artwork = item['artwork_url'] ?? '';
            if (artwork.contains('-large.jpg')) {
              artwork = artwork.replaceFirst('-large.jpg', '-t500x500.jpg');
            }

            int durationMs = item['duration'] ?? 180000;

            parsedResults.add(
              Song(
                id: "sc_${i}_${DateTime.now().millisecondsSinceEpoch}",
                title: item['permalink'] ?? 'SoundCloud Track',
                artist: item['genre'] != null && item['genre'].toString().isNotEmpty
                    ? item['genre']
                    : "SoundCloud",
                thumbnail: artwork,
                permalinkUrl: item['permalink_url'],
                duration: Duration(milliseconds: durationMs),
              ),
            );
          }

          setState(() {
            _searchResults = parsedResults;
          });
        }
      }
    } catch (e) {
      debugPrint("Error search SoundCloud: $e");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _fetchAndPlaySoundcloudAudio(Song songItem, List<Song> queueContext, int index) async {
    if (songItem.permalinkUrl == null) {
      _playSong(songItem, queueContext: queueContext, index: index);
      return;
    }

    setState(() => _isLoadingAudio = true);

    try {
      final url = Uri.parse(
          'http://api.ikyyxd.my.id/download/soundclouddl?apikey=kyzz&url=${Uri.encodeComponent(songItem.permalinkUrl!)}');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == true) {
          final String audioUrl = data['audio_url'] ?? '';
          final String realTitle = data['title'] ?? songItem.title;

          final updatedSong = Song(
            id: songItem.id,
            title: realTitle,
            artist: songItem.artist,
            thumbnail: songItem.thumbnail,
            permalinkUrl: songItem.permalinkUrl,
            audioUrl: audioUrl,
            duration: songItem.duration,
          );

          if (index < queueContext.length) {
            queueContext[index] = updatedSong;
          }
          _playSong(updatedSong, queueContext: queueContext, index: index);
        } else {
          _showSnackBar("Gagal mengambil link audio dari server.");
        }
      }
    } catch (e) {
      _showSnackBar("Gagal terhubung ke API Downloader.");
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.primaryMagenta),
    );
  }

  // ---------------------------------------------------------------------------
  // MANAJEMEN PLAYLIST & STORAGE
  // ---------------------------------------------------------------------------
  Future<void> _loadPlaylistsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('prikitiww_playlists');
    if (data != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(data);
      setState(() {
        _userPlaylists = jsonMap.map((key, value) {
          final List list = value as List;
          return MapEntry(
            key,
            list.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList(),
          );
        });
      });
    }
  }

  Future<void> _savePlaylistsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = _userPlaylists.map(
      (key, value) => MapEntry(key, value.map((e) => e.toJson()).toList()),
    );
    await prefs.setString('prikitiww_playlists', jsonEncode(jsonMap));
  }

  void _createNewEmptyPlaylist(String name) {
    setState(() {
      if (!_userPlaylists.containsKey(name)) {
        _userPlaylists[name] = [];
      }
    });
    _savePlaylistsToStorage();
    _showSnackBar("Playlist '$name' berhasil dibuat.");
  }

  void _createNewPlaylistAndAddSong(String name, Song song) {
    setState(() {
      if (!_userPlaylists.containsKey(name)) {
        _userPlaylists[name] = [];
      }
      if (!_userPlaylists[name]!.any((s) => s.id == song.id)) {
        _userPlaylists[name]!.add(song);
      }
    });
    _savePlaylistsToStorage();
    _showSnackBar("Ditambahkan ke playlist '$name'");
  }

  void _showPlaylistDetailModal(String playlistName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14081E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final songs = _userPlaylists[playlistName] ?? [];
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          playlistName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  Text("${songs.length} Lagu tersimpan", style: const TextStyle(color: AppTheme.grayText, fontSize: 13)),
                  const Divider(color: Colors.white10, height: 24),
                  Expanded(
                    child: songs.isEmpty
                        ? const Center(
                            child: Text("Belum ada lagu di playlist ini", style: TextStyle(color: AppTheme.grayText)),
                          )
                        : ListView.builder(
                            itemCount: songs.length,
                            itemBuilder: (context, idx) {
                              final song = songs[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: song.isNetworkImage
                                        ? Image.network(song.thumbnail, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppTheme.secondaryPurple, width: 44, height: 44))
                                        : Image.asset(song.thumbnail, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppTheme.secondaryPurple, width: 44, height: 44)),
                                  ),
                                  title: Text(
                                    song.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    song.artist,
                                    style: const TextStyle(color: AppTheme.grayText, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                                    onPressed: () {
                                      setState(() {
                                        _userPlaylists[playlistName]?.removeAt(idx);
                                      });
                                      setModalState(() {});
                                      _savePlaylistsToStorage();
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _fetchAndPlaySoundcloudAudio(song, songs, idx);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddPlaylistDialog(Song song) {
    if (_userPlaylists.isEmpty) {
      final controller = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF14081E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.primaryMagenta, width: 1.5),
          ),
          title: const Text("Buat Playlist Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Nama Playlist",
              hintStyle: TextStyle(color: AppTheme.grayText),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryMagenta)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryMagenta, width: 2)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: AppTheme.grayText))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMagenta),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  _createNewPlaylistAndAddSong(controller.text.trim(), song);
                  Navigator.pop(context);
                }
              },
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF14081E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Tambah ke Playlist", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.add_box_rounded, color: AppTheme.primaryMagenta),
                title: const Text("Buat Playlist Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistModalOnly(song);
                },
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView(
                  children: _userPlaylists.keys.map((pName) {
                    return ListTile(
                      leading: const Icon(Icons.music_note_rounded, color: AppTheme.secondaryPurple),
                      title: Text(pName, style: const TextStyle(color: Colors.white)),
                      subtitle: Text("${_userPlaylists[pName]!.length} Lagu", style: const TextStyle(color: AppTheme.grayText, fontSize: 12)),
                      onTap: () {
                        _createNewPlaylistAndAddSong(pName, song);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _showCreatePlaylistModalOnly([Song? song]) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF14081E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.primaryMagenta, width: 1.5),
        ),
        title: const Text("Nama Playlist Baru", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Contoh: My Mix",
            hintStyle: TextStyle(color: AppTheme.grayText),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: AppTheme.grayText))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryMagenta),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                if (song != null) {
                  _createNewPlaylistAndAddSong(controller.text.trim(), song);
                } else {
                  _createNewEmptyPlaylist(controller.text.trim());
                }
                Navigator.pop(context);
              }
            },
            child: const Text("Buat", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // KONTROL AUDIO HANDLER
  // ---------------------------------------------------------------------------
  void _playSong(Song song, {List<Song>? queueContext, int index = 0}) async {
    if (globalAudioHandler == null) {
      await _initAudioService();
    }

    setState(() {
      _currentSong = song;
      if (queueContext != null) {
        _currentQueue = queueContext;
        _currentIndex = index;
      }
    });

    _addSongToRecentlyPlayed(song);

    if (globalAudioHandler != null && globalAudioHandler is MyAudioHandler) {
      (globalAudioHandler as MyAudioHandler).playCustomSong(
        id: song.id,
        title: song.title,
        artist: song.artist,
        artworkUrl: song.thumbnail,
        audioUrl: song.audioUrl ?? '',
        duration: song.duration,
      );
    }
  }

  void _nextSong() {
    if (_currentQueue.isEmpty) return;
    if (_isRepeat && _currentSong != null) {
      _playSong(_currentSong!, queueContext: _currentQueue, index: _currentIndex);
      return;
    }
    int nextIdx = (_currentIndex + 1) % _currentQueue.length;
    _fetchAndPlaySoundcloudAudio(_currentQueue[nextIdx], _currentQueue, nextIdx);
  }

  void _previousSong() {
    if (_currentQueue.isEmpty) return;
    int prevIdx = (_currentIndex - 1 + _currentQueue.length) % _currentQueue.length;
    _fetchAndPlaySoundcloudAudio(_currentQueue[prevIdx], _currentQueue, prevIdx);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          _buildGlow(-60, -60, AppTheme.primaryMagenta.withOpacity(0.18)),
          _buildGlow(null, -60, AppTheme.secondaryPurple.withOpacity(0.2), bottom: -60),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _currentNavIndex,
                    children: [
                      _buildHomeTab(),
                      _buildSearchTab(),
                      _buildLibraryTab(),
                    ],
                  ),
                ),

                if (_currentSong != null) _buildMiniPlayer(),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF090310),
          border: Border(top: BorderSide(color: AppTheme.primaryMagenta.withOpacity(0.2), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _currentNavIndex,
          selectedItemColor: AppTheme.primaryMagenta,
          unselectedItemColor: AppTheme.grayText,
          onTap: (index) => setState(() => _currentNavIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: "Search"),
            BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: "Library"),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HOME TAB
  // ===========================================================================
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.account_circle_rounded, color: AppTheme.primaryMagenta, size: 28),
              const SizedBox(width: 10),
              const Text(
                "Good evening",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text("Pilihan Cepat", style: TextStyle(color: AppTheme.grayText, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          if (_recentlyPlayed.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.primaryMagenta, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Cari & Putar Lagu", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("Masuk ke tab Search untuk mencari lagu SoundCloud", style: TextStyle(color: AppTheme.grayText, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: _recentlyPlayed.take(4).map((song) => _buildQuickChoiceCard(song.title, song)).toList(),
            ),
          
          const SizedBox(height: 25),

          const Text("Recently played", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),

          if (_recentlyPlayed.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text("Belum ada lagu yang diputar", style: TextStyle(color: AppTheme.grayText, fontSize: 13)),
              ),
            )
          else
            SizedBox(
              height: 155,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recentlyPlayed.length,
                itemBuilder: (context, index) {
                  final song = _recentlyPlayed[index];
                  return GestureDetector(
                    onTap: () => _fetchAndPlaySoundcloudAudio(song, _recentlyPlayed, index),
                    child: Container(
                      width: 105,
                      margin: const EdgeInsets.only(right: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 105,
                            height: 105,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.3)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: song.isNetworkImage
                                  ? Image.network(song.thumbnail, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppTheme.secondaryPurple))
                                  : Image.asset(song.thumbnail, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppTheme.secondaryPurple)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(song.artist, style: const TextStyle(color: AppTheme.grayText, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickChoiceCard(String title, Song song) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _fetchAndPlaySoundcloudAudio(song, _recentlyPlayed, 0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                child: song.isNetworkImage
                    ? Image.network(song.thumbnail, width: 45, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppTheme.secondaryPurple, width: 45))
                    : Image.asset(song.thumbnail, width: 45, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppTheme.secondaryPurple, width: 45)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. SEARCH TAB
  // ===========================================================================
  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            textInputAction: TextInputAction.search,
            onSubmitted: (val) => _searchSoundcloud(val),
            decoration: InputDecoration(
              hintText: "Cari lagu SoundCloud (contoh: Duka)...",
              hintStyle: const TextStyle(color: AppTheme.grayText, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryMagenta),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, color: AppTheme.primaryMagenta),
                onPressed: () => _searchSoundcloud(_searchController.text),
              ),
              filled: true,
              fillColor: AppTheme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          if (_isSearching)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryMagenta),
                    SizedBox(height: 12),
                    Text("Mencari lagu di SoundCloud...", style: TextStyle(color: AppTheme.grayText)),
                  ],
                ),
              ),
            )
          else if (_searchResults.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(FontAwesomeIcons.soundcloud, color: Colors.white24, size: 50),
                    SizedBox(height: 12),
                    Text("Ketik judul lagu untuk mulai mencari", style: TextStyle(color: AppTheme.grayText)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final song = _searchResults[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.15)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.4)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: song.thumbnail.isNotEmpty
                              ? Image.network(
                                  song.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppTheme.secondaryPurple,
                                    child: const Icon(Icons.music_note, color: Colors.white),
                                  ),
                                )
                              : Container(
                                  color: AppTheme.secondaryPurple,
                                  child: const Icon(Icons.music_note, color: Colors.white),
                                ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "${song.artist} • ${song.duration.inMinutes}:${(song.duration.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(color: AppTheme.grayText, fontSize: 11),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white54),
                        onPressed: () => _showAddPlaylistDialog(song),
                      ),
                      onTap: () => _fetchAndPlaySoundcloudAudio(song, _searchResults, index),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. LIBRARY TAB
  // ===========================================================================
  Widget _buildLibraryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Playlist Saya", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, color: AppTheme.primaryMagenta),
                onPressed: () => _showCreatePlaylistModalOnly(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _userPlaylists.isEmpty
                ? const Center(child: Text("Belum ada playlist tersimpan", style: TextStyle(color: AppTheme.grayText)))
                : ListView(
                    children: _userPlaylists.keys.map((name) {
                      final pList = _userPlaylists[name]!;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.2)),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryPurple.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.playlist_play_rounded, color: AppTheme.primaryMagenta),
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text("${pList.length} Lagu", style: const TextStyle(color: AppTheme.grayText, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                          onTap: () => _showPlaylistDetailModal(name),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🎵 MINI PLAYER
  // ===========================================================================
  Widget _buildMiniPlayer() {
    return StreamBuilder<PlaybackState>(
      stream: globalAudioHandler?.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isPlaying = state?.playing ?? false;

        return StreamBuilder<MediaItem?>(
          stream: globalAudioHandler?.mediaItem,
          builder: (context, mediaSnapshot) {
            final mediaItem = mediaSnapshot.data;

            return StreamBuilder<Duration>(
              stream: AudioService.position,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = mediaItem?.duration ?? const Duration(minutes: 3);

                double progress = duration.inSeconds > 0
                    ? position.inSeconds / duration.inSeconds
                    : 0.0;

                return GestureDetector(
                  onTap: () {
                    if (_currentSong != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullPlayerScreen(
                            song: _currentSong!,
                            isLiked: _isLiked,
                            isShuffle: _isShuffle,
                            isRepeat: _isRepeat,
                            onNext: _nextSong,
                            onPrevious: _previousSong,
                            onToggleLike: () => setState(() => _isLiked = !_isLiked),
                            onToggleShuffle: () => setState(() => _isShuffle = !_isShuffle),
                            onToggleRepeat: () => setState(() => _isRepeat = !_isRepeat),
                            onAddPlaylist: () => _showAddPlaylistDialog(_currentSong!),
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryMagenta.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryMagenta.withOpacity(0.2), blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _currentSong!.isNetworkImage
                                      ? Image.network(_currentSong!.thumbnail,
                                          width: 42, height: 42, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                                color: AppTheme.secondaryPurple,
                                                child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                                              ))
                                      : Image.asset(_currentSong!.thumbnail,
                                          width: 42, height: 42, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                                color: AppTheme.secondaryPurple,
                                                child: const Icon(Icons.music_note, color: Colors.white, size: 20),
                                              )),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(mediaItem?.title ?? _currentSong!.title,
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text(mediaItem?.artist ?? _currentSong!.artist,
                                          style: const TextStyle(color: AppTheme.grayText, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                if (_isLoadingAudio)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: AppTheme.primaryMagenta, strokeWidth: 2),
                                  )
                                else ...[
                                  IconButton(
                                    icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: AppTheme.primaryMagenta, size: 20),
                                    onPressed: () => setState(() => _isLiked = !_isLiked),
                                  ),
                                  IconButton(
                                    icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: AppTheme.primaryMagenta, size: 28),
                                    onPressed: () {
                                      if (isPlaying) {
                                        globalAudioHandler?.pause();
                                      } else {
                                        globalAudioHandler?.play();
                                      }
                                    },
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ),
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryMagenta),
                          minHeight: 2.5,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildGlow(double? top, double? left, Color color, {double? bottom, double? right}) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 100, spreadRadius: 30)],
        ),
      ),
    );
  }
}

// =============================================================================
// FULL SCREEN PLAYER PAGE
// =============================================================================
class FullPlayerScreen extends StatefulWidget {
  final Song song;
  final bool isLiked;
  final bool isShuffle;
  final bool isRepeat;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;
  final VoidCallback onAddPlaylist;

  const FullPlayerScreen({
    super.key,
    required this.song,
    required this.isLiked,
    required this.isShuffle,
    required this.isRepeat,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleLike,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
    required this.onAddPlaylist,
  });

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlaybackState>(
      stream: globalAudioHandler?.playbackState,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isPlaying = state?.playing ?? false;

        return StreamBuilder<MediaItem?>(
          stream: globalAudioHandler?.mediaItem,
          builder: (context, mediaSnapshot) {
            final mediaItem = mediaSnapshot.data;

            return StreamBuilder<Duration>(
              stream: AudioService.position,
              builder: (context, positionSnapshot) {
                final position = positionSnapshot.data ?? Duration.zero;
                final duration = mediaItem?.duration ?? widget.song.duration;

                return Scaffold(
                  backgroundColor: AppTheme.bgDark,
                  body: Stack(
                    children: [
                      Positioned(
                        top: -40,
                        left: -40,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: AppTheme.primaryMagenta.withOpacity(0.25), blurRadius: 120, spreadRadius: 40)],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  const Text(
                                    "PRIKITIWW MUSIC",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.more_vert, color: Colors.white),
                                    onPressed: widget.onAddPlaylist,
                                  ),
                                ],
                              ),
                              const Spacer(),

                              Container(
                                width: double.infinity,
                                height: 300,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppTheme.primaryMagenta, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryMagenta.withOpacity(0.4),
                                      blurRadius: 30,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: widget.song.isNetworkImage
                                      ? Image.network(widget.song.thumbnail,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                                color: AppTheme.cardBg,
                                                child: const Icon(Icons.music_note, size: 80, color: AppTheme.primaryMagenta),
                                              ))
                                      : Image.asset(widget.song.thumbnail,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                                color: AppTheme.cardBg,
                                                child: const Icon(Icons.music_note, size: 80, color: AppTheme.primaryMagenta),
                                              )),
                                ),
                              ),
                              const Spacer(),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mediaItem?.title ?? widget.song.title,
                                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          mediaItem?.artist ?? widget.song.artist,
                                          style: const TextStyle(color: AppTheme.grayText, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      widget.isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: AppTheme.primaryMagenta,
                                      size: 28,
                                    ),
                                    onPressed: widget.onToggleLike,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  activeTrackColor: AppTheme.primaryMagenta,
                                  inactiveTrackColor: Colors.white12,
                                  thumbColor: AppTheme.primaryMagenta,
                                ),
                                child: Slider(
                                  value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                                  max: duration.inSeconds.toDouble(),
                                  onChanged: (val) {
                                    globalAudioHandler?.seek(Duration(seconds: val.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(_formatDuration(position), style: const TextStyle(color: AppTheme.grayText, fontSize: 12)),
                                    Text(_formatDuration(duration), style: const TextStyle(color: AppTheme.grayText, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.shuffle_rounded, color: widget.isShuffle ? AppTheme.primaryMagenta : Colors.white54),
                                    onPressed: widget.onToggleShuffle,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                                    onPressed: widget.onPrevious,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      if (isPlaying) {
                                        globalAudioHandler?.pause();
                                      } else {
                                        globalAudioHandler?.play();
                                      }
                                    },
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(colors: [AppTheme.primaryMagenta, AppTheme.secondaryPurple]),
                                        boxShadow: [BoxShadow(color: AppTheme.primaryMagenta, blurRadius: 15)],
                                      ),
                                      child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                                    onPressed: widget.onNext,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.repeat_rounded, color: widget.isRepeat ? AppTheme.primaryMagenta : Colors.white54),
                                    onPressed: widget.onToggleRepeat,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),

                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppTheme.primaryMagenta.withOpacity(0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: widget.onAddPlaylist,
                                icon: const Icon(Icons.playlist_add_rounded, color: AppTheme.primaryMagenta),
                                label: const Text("Tambah ke Playlist", style: TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
} 