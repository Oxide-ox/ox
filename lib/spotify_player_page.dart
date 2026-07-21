import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'music_service.dart';

// =============================================================
// MODEL SONG & PLAYLIST
// =============================================================
class SongItem {
  final String title;
  final String artist;
  final String thumbnail;
  final String duration;
  final String downloadUrl;
  final DateTime timestamp;

  SongItem({
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.duration,
    required this.downloadUrl,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        "title": title,
        "artist": artist,
        "thumbnail": thumbnail,
        "duration": duration,
        "downloadUrl": downloadUrl,
        "timestamp": timestamp.toIso8601String(),
      };

  factory SongItem.fromJson(Map<String, dynamic> json) => SongItem(
        title: json["title"] ?? "",
        artist: json["artist"] ?? "",
        thumbnail: json["thumbnail"] ?? "",
        duration: json["duration"] ?? "",
        downloadUrl: json["downloadUrl"] ?? "",
        timestamp: json["timestamp"] != null
            ? DateTime.tryParse(json["timestamp"]) ?? DateTime.now()
            : DateTime.now(),
      );
}

class PlaylistItem {
  final String name;
  final List<SongItem> songs;

  PlaylistItem({required this.name, required this.songs});

  Map<String, dynamic> toJson() => {
        "name": name,
        "songs": songs.map((e) => e.toJson()).toList(),
      };

  factory PlaylistItem.fromJson(Map<String, dynamic> json) => PlaylistItem(
        name: json["name"] ?? "Playlist Baru",
        songs: (json["songs"] as List<dynamic>?)
                ?.map((e) => SongItem.fromJson(e))
                .toList() ??
            [],
      );
}

// =============================================================
// MAIN PAGE
// =============================================================
class SpotifyPlayerPage extends StatefulWidget {
  const SpotifyPlayerPage({super.key});

  @override
  State<SpotifyPlayerPage> createState() => _SpotifyPlayerPageState();
}

class _SpotifyPlayerPageState extends State<SpotifyPlayerPage> {
  static const _historyKey = "spotify_history_v2";
  static const _queueKey = "spotify_queue_v2";
  static const _playlistKey = "spotify_playlists_v2";
  static const _maxHistory = 20;

  final player = MusicService.player;
  final TextEditingController controller = TextEditingController();

  StreamSubscription<PlayerState>? _playerStateSub;

  bool loading = false;
  String title = "";
  String artist = "";
  String duration = "";
  String thumbnail = "";
  String downloadUrl = "";

  List<SongItem> history = [];
  List<SongItem> queue = [];
  List<PlaylistItem> playlists = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _listenForCompletion();
  }

  // ================= LOCAL STORAGE =================

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load History
    final rawHistory = prefs.getStringList(_historyKey) ?? [];
    history = rawHistory.map((e) => SongItem.fromJson(jsonDecode(e))).toList();

    // Load Queue
    final rawQueue = prefs.getStringList(_queueKey) ?? [];
    queue = rawQueue.map((e) => SongItem.fromJson(jsonDecode(e))).toList();

    // Load Playlists
    final rawPlaylists = prefs.getStringList(_playlistKey) ?? [];
    playlists = rawPlaylists.map((e) => PlaylistItem.fromJson(jsonDecode(e))).toList();

    setState(() {});
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, history.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_queueKey, queue.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_playlistKey, playlists.map((e) => jsonEncode(e.toJson())).toList());
  }

  Future<void> _addToHistory(SongItem song) async {
    setState(() {
      history.removeWhere((e) => e.title == song.title && e.artist == song.artist);
      history.insert(0, song);
      if (history.length > _maxHistory) {
        history = history.sublist(0, _maxHistory);
      }
    });
    await _saveHistory();
  }

  // ================= PLAYER CORE =================

  void _listenForCompletion() {
    _playerStateSub = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playNextInQueue();
      }
    });
  }

  Future<void> _playSong(SongItem song, {bool addHistory = true}) async {
    setState(() {
      title = song.title;
      artist = song.artist;
      duration = song.duration;
      thumbnail = song.thumbnail;
      downloadUrl = song.downloadUrl;
    });

    await MusicService.handler.playSong(
      song.downloadUrl,
      song.title,
      song.artist,
      song.thumbnail,
    );

    if (addHistory) {
      await _addToHistory(song);
    }
  }

  Future<void> searchSong() async {
    if (controller.text.isEmpty) return;
    setState(() => loading = true);

    try {
      final search = await http.get(
        Uri.parse("https://api.ikyyxd.my.id/search/spotifyplay?query=${Uri.encodeComponent(controller.text)}"),
      );

      if (search.statusCode != 200 || !search.body.trim().startsWith('{')) {
        throw Exception("Gagal mencari lagu");
      }

      final searchData = jsonDecode(search.body);
      final spotifyUrl = searchData["result"]?["url"];
      if (spotifyUrl == null) throw Exception("Lagu tidak ditemukan");

      final download = await http.get(
        Uri.parse("https://api.ikyyxd.my.id/download/spotifydl?url=${Uri.encodeComponent(spotifyUrl)}"),
      );

      if (!download.body.trim().startsWith('{')) throw Exception("Gagal mengunduh lagu");

      final data = jsonDecode(download.body);
      final song = data["result"];

      final newSong = SongItem(
        title: song["title"] ?? "Unknown",
        artist: song["artist"] ?? "Unknown",
        duration: song["duration"] ?? "0:00",
        thumbnail: song["thumbnail"] ?? "",
        downloadUrl: song["download"] ?? "",
      );

      await _playSong(newSong);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  // ================= QUEUE & PLAYLIST MANAGEMENT =================

  void _addToQueueCurrent() {
    if (title.isEmpty || downloadUrl.isEmpty) return;

    final song = SongItem(
      title: title,
      artist: artist,
      thumbnail: thumbnail,
      duration: duration,
      downloadUrl: downloadUrl,
    );

    setState(() => queue.add(song));
    _saveQueue();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ditambahkan ke Antrean")),
    );
  }

  Future<void> _playNextInQueue() async {
    if (queue.isEmpty) return;
    final next = queue.removeAt(0);
    setState(() {});
    await _saveQueue();
    await _playSong(next);
  }

  void _createPlaylist(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      playlists.add(PlaylistItem(name: name, songs: []));
    });
    _savePlaylists();
  }

  void _addSongToPlaylist(SongItem song, int playlistIndex) {
    setState(() {
      playlists[playlistIndex].songs.add(song);
    });
    _savePlaylists();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Masuk ke playlist '${playlists[playlistIndex].name}'")),
    );
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    super.dispose();
  }

  // ================= UI MODAL PROFIL & MUSIC LAB =================

  void _openProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF140202),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  
                  // Profile Header
                  ListTile(
                    leading: const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    title: const Text("Pengguna Cyber", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: const Text("Premium Audio Active", style: TextStyle(color: Colors.amber, fontSize: 12)),
                  ),

                  const TabBar(
                    indicatorColor: Colors.red,
                    labelColor: Colors.red,
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(icon: Icon(Icons.history), text: "History"),
                      Tab(icon: Icon(Icons.playlist_play), text: "Playlist"),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab History
                        _buildHistoryTab(scrollController),
                        // Tab Playlist
                        _buildPlaylistTab(scrollController),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab(ScrollController controller) {
    if (history.isEmpty) {
      return const Center(child: Text("Belum ada riwayat lagu", style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      controller: controller,
      itemCount: history.length,
      itemBuilder: (_, i) {
        final song = history[i];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(song.thumbnail, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.red)),
          ),
          title: Text(song.title, style: const TextStyle(color: Colors.white), maxLines: 1),
          subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54), maxLines: 1),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.amber),
            onPressed: () {
              Navigator.pop(context);
              _playSong(song);
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaylistTab(ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            final textCtrl = TextEditingController();
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF200000),
                title: const Text("Buat Playlist Baru", style: TextStyle(color: Colors.white)),
                content: TextField(
                  controller: textCtrl,
                  style: const TextStyle(color: Colors.amber),
                  decoration: const InputDecoration(hintText: "Nama Playlist", hintStyle: TextStyle(color: Colors.white38)),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
                  TextButton(
                    onPressed: () {
                      _createPlaylist(textCtrl.text);
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: const Text("Buat", style: TextStyle(color: Colors.red)),
                  )
                ],
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text("BUAT PLAYLIST BARU"),
        ),
        const SizedBox(height: 15),
        ...playlists.map((pl) => ExpansionTile(
              iconColor: Colors.amber,
              collapsedIconColor: Colors.white,
              title: Text(pl.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("${pl.songs.length} Lagu", style: const TextStyle(color: Colors.white54)),
              children: pl.songs.map((s) => ListTile(
                title: Text(s.title, style: const TextStyle(color: Colors.white)),
                subtitle: Text(s.artist, style: const TextStyle(color: Colors.white54)),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_fill, color: Colors.amber),
                  onPressed: () {
                    Navigator.pop(context);
                    _playSong(s);
                  },
                ),
              )).toList(),
            )),
      ],
    );
  }

  // ================= MAIN BUILD =================

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0D0000);
    const card = Color(0xFF180000);
    const red = Colors.red;
    const amber = Colors.amber;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("SPOTIFY CYBER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: red,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: _openProfileModal,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(20), border: Border.all(color: red)),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: amber),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.music_note, color: amber),
                      hintText: "Cari Judul Lagu / Artis...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : searchSong,
                      style: ElevatedButton.styleFrom(backgroundColor: red),
                      child: const Text("PUTAR MUSIK", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),
            if (loading) const CircularProgressIndicator(color: red),

            // Player Section
            if (thumbnail.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(thumbnail, width: 230, height: 230, fit: BoxFit.cover),
              ),
              const SizedBox(height: 15),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(artist, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 15),

              // Player Controls
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (_, snap) {
                  final playing = snap.data?.playing ?? false;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 64,
                        color: Colors.white,
                        icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
                        onPressed: () => playing ? MusicService.handler.pause() : MusicService.handler.play(),
                      ),
                      IconButton(
                        iconSize: 40,
                        color: amber,
                        icon: const Icon(Icons.skip_next),
                        onPressed: _playNextInQueue,
                      ),
                    ],
                  );
                },
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addToQueueCurrent,
                    icon: const Icon(Icons.playlist_add, color: amber),
                    label: const Text("ANTEAN", style: TextStyle(color: amber)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      if (playlists.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buat playlist terlebih dahulu di Profil!")));
                        return;
                      }
                      final song = SongItem(title: title, artist: artist, thumbnail: thumbnail, duration: duration, downloadUrl: downloadUrl);
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Container(
                          color: const Color(0xFF180000),
                          child: ListView.builder(
                            itemCount: playlists.length,
                            itemBuilder: (_, idx) => ListTile(
                              title: Text(playlists[idx].name, style: const TextStyle(color: Colors.white)),
                              onTap: () {
                                _addSongToPlaylist(song, idx);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.favorite_border, color: red),
                    label: const Text("SIMPAN", style: TextStyle(color: red)),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 25),

            // Queue Widget
            if (queue.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: amber.withOpacity(0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("PUTAR BERIKUTNYA (${queue.length})", style: const TextStyle(color: amber, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: queue.length,
                      itemBuilder: (_, i) => ListTile(
                        dense: true,
                        title: Text(queue[i].title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(queue[i].artist, style: const TextStyle(color: Colors.white54)),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                          onPressed: () {
                            setState(() => queue.removeAt(i));
                            _saveQueue();
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}