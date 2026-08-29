import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

// ==========================================
// 1. SOUNDCLOUD SCRAPER & MODELS
// ==========================================

class SoundCloudArtist {
  final String name;
  final String url;
  final int followers;

  SoundCloudArtist({
    required this.name,
    required this.url,
    required this.followers,
  });
}

class SoundCloudTrack {
  final String title;
  final String url;
  final int trackId;
  final String thumbnail;
  final SoundCloudArtist artist;
  final Duration duration;
  final int playCount;

  SoundCloudTrack({
    required this.title,
    required this.url,
    required this.trackId,
    required this.thumbnail,
    required this.artist,
    required this.duration,
    required this.playCount,
  });
}

class SoundCloudScraper {
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  static Future<String> _fetch(String url, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': userAgent,
          'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
          if (headers != null) ...headers,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fetch error: $e');
    }
  }

  static Future<String> _getClientId() async {
    try {
      final html = await _fetch('https://soundcloud.com');
      final scriptRegex = RegExp(r'https://a-v2\.sndcdn\.com/assets/[a-zA-Z0-9\-]+\.js');
      final scriptMatches = scriptRegex.allMatches(html).toList();

      for (int i = scriptMatches.length - 1; i >= scriptMatches.length - 3 && i >= 0; i--) {
        final jsUrl = scriptMatches[i].group(0);
        if (jsUrl != null) {
          try {
            final jsText = await _fetch(jsUrl);
            final clientMatch = RegExp(r'client_id[:=]"([a-zA-Z0-9]{32})"').firstMatch(jsText);
            if (clientMatch != null) {
              return clientMatch.group(1) ?? 'iZIs9mchVUYP3fh3R0L5R9Rz3N1g5dK';
            }
          } catch (e) {
            debugPrint('Error fetching script: $e');
          }
        }
      }
      return 'iZIs9mchVUYP3fh3R0L5R9Rz3N1g5dK';
    } catch (e) {
      debugPrint('Get ClientID Error: $e');
      return 'iZIs9mchVUYP3fh3R0L5R9Rz3N1g5dK';
    }
  }

  static Future<List<SoundCloudTrack>> scSearch(String query) async {
    try {
      final clientId = await _getClientId();
      final apiUrl =
          'https://api-v2.soundcloud.com/search/tracks?q=${Uri.encodeComponent(query)}&client_id=$clientId&limit=30';

      final html = await _fetch(apiUrl);
      final parsed = jsonDecode(html) as Map<String, dynamic>;
      final tracks = <SoundCloudTrack>[];

      if (parsed['collection'] is List) {
        for (var t in parsed['collection']) {
          if (t is Map<String, dynamic>) {
            try {
              String artwork = '';
              if (t['artwork_url'] != null) {
                artwork = (t['artwork_url'] as String).replaceFirst('-large.jpg', '-t500x500.jpg');
              } else if (t['user'] != null && t['user']['avatar_url'] != null) {
                artwork = t['user']['avatar_url'];
              }

              tracks.add(SoundCloudTrack(
                title: t['title'] ?? 'Unknown',
                url: t['permalink_url'] ?? '',
                trackId: t['id'] ?? 0,
                thumbnail: artwork,
                artist: SoundCloudArtist(
                  name: t['user']?['username'] ?? 'Unknown',
                  url: t['user']?['permalink_url'] ?? '',
                  followers: t['user']?['followers_count'] ?? 0,
                ),
                duration: Duration(milliseconds: t['duration'] ?? 0),
                playCount: t['playback_count'] ?? 0,
              ));
            } catch (e) {
              debugPrint('Error parsing track: $e');
            }
          }
        }
      }
      return tracks;
    } catch (e) {
      debugPrint('SoundCloud Search Error: $e');
      rethrow;
    }
  }

  static Future<String> getDirectDownloadUrl(String scUrl) async {
    try {
      final html = await _fetch(scUrl);
      final progressiveMatch = RegExp(r'"progressive":\[\{"url":"([^"]+)"').firstMatch(html);
      if (progressiveMatch != null) return progressiveMatch.group(1) ?? '';

      final hlsMatch = RegExp(r'"hls_mp3_128_url":"([^"]+)"').firstMatch(html);
      if (hlsMatch != null) return hlsMatch.group(1) ?? '';

      return '';
    } catch (e) {
      debugPrint('Get Direct Download URL Error: $e');
      rethrow;
    }
  }
}

// ==========================================
// 2. STATE MANAGEMENT (GLOBAL APP STATE)
// ==========================================

class AppState extends ChangeNotifier {
  final List<SoundCloudTrack> _history = [];
  final List<SoundCloudTrack> _playlist = [];
  
  SoundCloudTrack? _currentTrack;
  String? _currentAudioUrl;
  bool _isPlaying = false;
  bool _isLoadingTrack = false;

  List<SoundCloudTrack> get history => _history;
  List<SoundCloudTrack> get playlist => _playlist;
  SoundCloudTrack? get currentTrack => _currentTrack;
  String? get currentAudioUrl => _currentAudioUrl;
  bool get isPlaying => _isPlaying;
  bool get isLoadingTrack => _isLoadingTrack;

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void addToPlaylist(SoundCloudTrack track) {
    if (!_playlist.any((t) => t.trackId == track.trackId)) {
      _playlist.add(track);
      notifyListeners();
    }
  }

  void removeFromPlaylist(SoundCloudTrack track) {
    _playlist.removeWhere((t) => t.trackId == track.trackId);
    notifyListeners();
  }

  bool isInPlaylist(SoundCloudTrack track) {
    return _playlist.any((t) => t.trackId == track.trackId);
  }

  Future<void> playTrack(SoundCloudTrack track) async {
    _currentTrack = track;
    _isLoadingTrack = true;
    _isPlaying = false;
    notifyListeners();

    // Tambah ke History
    _history.removeWhere((t) => t.trackId == track.trackId);
    _history.insert(0, track);

    try {
      final audioUrl = await SoundCloudScraper.getDirectDownloadUrl(track.url);
      _currentAudioUrl = audioUrl;
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error playing track: $e');
    } finally {
      _isLoadingTrack = false;
      notifyListeners();
    }
  }
}

final globalAppState = AppState();

// ==========================================
// 3. MAIN MUSIC PLAYER SCREEN (ENTRY POINT)
// ==========================================

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({Key? key}) : super(Key: key);

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    HistoryScreen(),
    PlaylistScreen(),
  ];

  @override
  void initState() {
    super.initState();
    globalAppState.addListener(_onStateChange);
  }

  @override
  void dispose() {
    globalAppState.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          if (globalAppState.currentTrack != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildMiniPlayer(context),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFFFF5500),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'Playlist'),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context) {
    final track = globalAppState.currentTrack!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NowPlayingScreen()),
        );
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.thumbnail,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.grey[800]),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    track.artist.name,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (globalAppState.isLoadingTrack)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF5500)),
              )
            else
              IconButton(
                icon: Icon(
                  globalAppState.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: const Color(0xFFFF5500),
                ),
                onPressed: () => globalAppState.togglePlayPause(),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. HOME PAGE (TOP MUSIC INDONESIA 2026 + SEARCH)
// ==========================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SoundCloudTrack> _topIndonesia = [];
  List<SoundCloudTrack> _searchResults = [];
  bool _isLoadingTop = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchTopIndonesia();
  }

  Future<void> _fetchTopIndonesia() async {
    try {
      final results = await SoundCloudScraper.scSearch('Pop Indonesia Hits 2026');
      if (mounted) {
        setState(() {
          _topIndonesia = results;
          _isLoadingTop = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTop = false);
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final results = await SoundCloudScraper.scSearch(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearchingMode = _searchController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('SoundCloud Explorer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onSubmitted: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Cari lagu atau artis...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF5500)),
                suffixIcon: isSearchingMode
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults.clear());
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF282828),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (isSearchingMode) ...[
              const Text('Hasil Pencarian', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _isSearching
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5500)))
                  : _buildTrackList(_searchResults),
            ] else ...[
              // Section Top Indonesia 2026
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('🔥 Top Music Indonesia 2026', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Lihat Semua', style: TextStyle(color: Color(0xFFFF5500), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              _isLoadingTop
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5500)))
                  : _buildTrackList(_topIndonesia),
            ],
            const SizedBox(height: 80), // Padding untuk mini player
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(List<SoundCloudTrack> tracks) {
    if (tracks.isEmpty) {
      return const Center(
        child: Text('Lagu tidak ditemukan', style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: track.thumbnail,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.grey[800]),
            ),
          ),
          title: Text(track.title, maxLines: 1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(track.artist.name, maxLines: 1, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: IconButton(
            icon: Icon(
              globalAppState.isInPlaylist(track) ? Icons.favorite : Icons.favorite_border,
              color: const Color(0xFFFF5500),
            ),
            onPressed: () {
              if (globalAppState.isInPlaylist(track)) {
                globalAppState.removeFromPlaylist(track);
              } else {
                globalAppState.addToPlaylist(track);
              }
              setState(() {});
            },
          ),
          onTap: () => globalAppState.playTrack(track),
        );
      },
    );
  }
}

// ==========================================
// 5. HISTORY PAGE
// ==========================================

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final history = globalAppState.history;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Riwayat Pemutaran', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text('Belum ada riwayat musik yang diputar', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final track = history[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: track.thumbnail,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(track.title, maxLines: 1, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(track.artist.name, style: const TextStyle(color: Colors.grey)),
                  onTap: () => globalAppState.playTrack(track),
                );
              },
            ),
    );
  }
}

// ==========================================
// 6. PLAYLIST PAGE
// ==========================================

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  @override
  Widget build(BuildContext context) {
    final playlist = globalAppState.playlist;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Playlist Favorit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: playlist.isEmpty
          ? const Center(
              child: Text('Playlist favorit kamu masih kosong', style: TextStyle(color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: playlist.length,
              itemBuilder: (context, index) {
                final track = playlist[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: track.thumbnail,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(track.title, maxLines: 1, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(track.artist.name, style: const TextStyle(color: Colors.grey)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () {
                      globalAppState.removeFromPlaylist(track);
                      setState(() {});
                    },
                  ),
                  onTap: () => globalAppState.playTrack(track),
                );
              },
            ),
    );
  }
}

// ==========================================
// 7. NOW PLAYING SCREEN (FULL PLAYER)
// ==========================================

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final track = globalAppState.currentTrack;

    if (track == null) return const Scaffold();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sedang Diputar', style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: track.thumbnail,
                width: 280,
                height: 280,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              track.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              track.artist.name,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    globalAppState.isInPlaylist(track) ? Icons.favorite : Icons.favorite_border,
                    color: const Color(0xFFFF5500),
                    size: 28,
                  ),
                  onPressed: () {
                    if (globalAppState.isInPlaylist(track)) {
                      globalAppState.removeFromPlaylist(track);
                    } else {
                      globalAppState.addToPlaylist(track);
                    }
                  },
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5500),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      globalAppState.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () => globalAppState.togglePlayPause(),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
