import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Import file scraper LK21 milikmu di sini:
import 'lk21_scraper.dart';

// ==========================================
// MAIN ENTRY APP (NETFLIX THEME)
// ==========================================
class NetflixMovieApp extends StatelessWidget {
  const NetflixMovieApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Netflix Lite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141414),
        primaryColor: const Color(0xFFE50914),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const NetflixHomeScreen(),
    );
  }
}

// ==========================================
// 1. HOME SCREEN (HERO BANNER & CAROUSEL)
// ==========================================
class NetflixHomeScreen extends StatefulWidget {
  const NetflixHomeScreen({Key? key}) : super(key: key);

  @override
  State<NetflixHomeScreen> createState() => _NetflixHomeScreenState();
}

class _NetflixHomeScreenState extends State<NetflixHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<LK21Film> _featuredFilms = [];
  List<LK21Film> _actionFilms = [];
  List<LK21Film> _searchResults = [];
  
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialCatalog();
  }

  Future<void> _loadInitialCatalog() async {
    setState(() => _isLoading = true);
    try {
      final featured = await LK21Scraper.searchFilms('2026');
      final action = await LK21Scraper.searchFilms('action');

      if (mounted) {
        setState(() {
          _featuredFilms = featured;
          _actionFilms = action;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _isSearching = false);
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final results = await LK21Scraper.searchFilms(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        title: const Text(
          'NETFLIX',
          style: TextStyle(
            color: Color(0xFFE50914),
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            if (_isLoading)
              const SizedBox(
                height: 400,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE50914)),
                ),
              )
            else if (_isSearching)
              _buildGridSection('Hasil Pencarian', _searchResults)
            else ...[
              if (_featuredFilms.isNotEmpty) _buildHeroBanner(_featuredFilms.first),
              _buildHorizontalSection(' Sedang Populer 2026', _featuredFilms),
              _buildHorizontalSection(' Film Aksi Terbaik', _actionFilms),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onSubmitted: _onSearch,
        decoration: InputDecoration(
          hintText: 'Cari film, serial TV, atau genre...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _isSearching = false);
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF2B2B2B),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(LK21Film film) {
    return GestureDetector(
      onTap: () => _openDetail(film),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: 420,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: film.poster,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
            ),
          ),
          Container(
            height: 420,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                  const Color(0xFF141414),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Text(
                  film.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      onPressed: () => _openDetail(film),
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: const Text('Putar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: () => _openDetail(film),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Detail'),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHorizontalSection(String title, List<LK21Film> films) {
    if (films.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: films.length,
            itemBuilder: (context, index) {
              final film = films[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _openDetail(film),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: film.poster,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey[900]),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.movie, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridSection(String title, List<LK21Film> films) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: films.length,
          itemBuilder: (context, index) {
            final film = films[index];
            return GestureDetector(
              onTap: () => _openDetail(film),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: film.poster,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.grey[900]),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _openDetail(LK21Film film) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetflixDetailScreen(film: film),
      ),
    );
  }
}

// ==========================================
// 2. FILM DETAIL SCREEN (MODAL VIEW)
// ==========================================
class NetflixDetailScreen extends StatefulWidget {
  final LK21Film film;

  const NetflixDetailScreen({Key? key, required this.film}) : super(key: key);

  @override
  State<NetflixDetailScreen> createState() => _NetflixDetailScreenState();
}

class _NetflixDetailScreenState extends State<NetflixDetailScreen> {
  LK21FilmDetails? _details;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final details = await LK21Scraper.getFilmDetails(widget.film.url);
      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster Backdrop
                  Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: _details?.poster ?? widget.film.poster,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        height: 300,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFF141414)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Metadata Info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _details?.title ?? widget.film.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '⭐ ${_details?.rating ?? 0}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_details?.year ?? '', style: const TextStyle(color: Colors.grey)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _details?.qualities.first ?? 'HD',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Synopsis
                        Text(
                          _details?.synopsis.isNotEmpty == true
                              ? _details!.synopsis
                              : 'Tidak ada sinopsis tersedia.',
                          style: TextStyle(color: Colors.grey[300], height: 1.4),
                        ),
                        const SizedBox(height: 24),

                        // Streaming Links Section
                        const Text(
                          'PILIH SERVER STREAMING / DOWNLOAD',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE50914),
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_details?.downloadLinks.isEmpty ?? true)
                          const Text('Server pemutar tidak ditemukan.',
                              style: TextStyle(color: Colors.grey))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _details!.downloadLinks.length,
                            itemBuilder: (context, index) {
                              final link = _details!.downloadLinks[index];
                              return Card(
                                color: const Color(0xFF222222),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    link.isStream ? Icons.play_circle : Icons.download,
                                    color: const Color(0xFFE50914),
                                  ),
                                  title: Text(
                                    link.serverName,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    'Kualitas: ${link.quality}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                  onTap: () => _playStream(link),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _playStream(DownloadLink link) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Membuka server ${link.serverName}...')),
    );

    final directUrl = await LK21Scraper.getDirectUrl(link.url);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NetflixVideoPlayerScreen(
          videoUrl: directUrl,
          title: widget.film.title,
        ),
      ),
    );
  }
}

// ==========================================
// 3. FULLSCREEN VIDEO PLAYER
// ==========================================
class NetflixVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const NetflixVideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    required this.title,
  }) : super(key: key);

  @override
  State<NetflixVideoPlayerScreen> createState() => _NetflixVideoPlayerScreenState();
}

class _NetflixVideoPlayerScreenState extends State<NetflixVideoPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  WebViewController? _webViewController;
  bool _isWebEmbed = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    // Jika link adalah format direct stream MP4 / M3U8
    if (widget.videoUrl.endsWith('.mp4') || widget.videoUrl.endsWith('.m3u8')) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFE50914),
          handleColor: const Color(0xFFE50914),
          backgroundColor: Colors.grey,
        ),
      );
      setState(() {});
    } else {
      // Jika link berupa Web Embed Player (Iframe)
      _isWebEmbed = true;
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(widget.videoUrl));
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
      ),
      body: Center(
        child: _isWebEmbed
            ? (_webViewController != null
                ? WebViewWidget(controller: _webViewController!)
                : const CircularProgressIndicator(color: Color(0xFFE50914)))
            : (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(color: Color(0xFFE50914))),
      ),
    );
  }
}
