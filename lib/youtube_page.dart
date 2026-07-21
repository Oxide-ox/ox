// =============================================================
// yt.dart
// Aplikasi Flutter YouTube Player - Tema Cyberpunk (Single File)
// Updated: Custom Color Theme, Double-Tap Seek (±10s), & Fullscreen Mode
// =============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

// =============================================================
// TOP-LEVEL CALLBACK - Wajib untuk flutter_downloader
// =============================================================
@pragma('vm:entry-point')
void downloadCallback(String id, int status, int progress) {
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);
  FlutterDownloader.registerCallback(downloadCallback);
  
  // Kunci orientasi awal ke Portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const YoutubeCyberApp());
}

// =============================================================
// 1. CYBER THEME - Palet Warna Baru (Neon Magenta & Gold Accent)
// =============================================================
class CyberTheme {
  static const Color bgPurpleDark = Color(0xFF0F0C1B);
  static const Color bgBlack = Color(0xFF05030A);
  static const Color cardPurple = Color(0xFF1E1430);
  
  // Warna Utama Baru: Neon Magenta / Pink & Gold Accent
  static const Color neonPink = Color(0xFFFF007F);
  static const Color neonGold = Color(0xFFFFD700);
  static const Color white = Color(0xFFFFFFFF);
  static const Color greyText = Color(0xFFB5A8C8);

  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgPurpleDark, bgBlack],
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardPurple,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: neonPink.withOpacity(0.7), width: 1.2),
    boxShadow: [
      BoxShadow(color: neonPink.withOpacity(0.25), blurRadius: 12, spreadRadius: 1),
    ],
  );

  static BoxDecoration glowButton = BoxDecoration(
    color: cardPurple,
    borderRadius: BorderRadius.circular(50),
    border: Border.all(color: neonPink, width: 1.5),
    boxShadow: [
      BoxShadow(color: neonPink.withOpacity(0.6), blurRadius: 16, spreadRadius: 2),
    ],
  );

  static const TextStyle titleStyle = TextStyle(
    color: white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.3,
  );

  static const TextStyle subStyle = TextStyle(
    color: greyText, fontSize: 12, fontWeight: FontWeight.w500,
  );

  static const TextStyle neonLabel = TextStyle(
    color: neonPink, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0,
  );

  static ThemeData themeData = ThemeData(
    scaffoldBackgroundColor: bgPurpleDark,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(primary: neonPink, secondary: neonGold),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: neonPink),
      titleTextStyle: TextStyle(
        color: neonPink, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.2,
      ),
    ),
  );
}

// =============================================================
// 2. VIDEO MODEL
// =============================================================
class VideoModel {
  final String title;
  final String channel;
  final String duration;
  final String thumbnail;
  final String views;
  final String url;

  VideoModel({
    required this.title,
    required this.channel,
    required this.duration,
    required this.thumbnail,
    required this.views,
    required this.url,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    String pick(List<String> keys, [String fallback = '-']) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return fallback;
    }

    return VideoModel(
      title: pick(['title'], 'Tanpa Judul'),
      channel: pick(['channel'], 'Unknown Channel'),
      duration: pick(['duration'], '00:00'),
      thumbnail: pick(['imageUrl', 'thumbnail'], ''),
      views: pick(['views', 'viewCount'], '-'),
      url: pick(['link', 'url'], ''),
    );
  }
}

// =============================================================
// APP ROOT
// =============================================================
class YoutubeCyberApp extends StatelessWidget {
  const YoutubeCyberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YouTube Player Cyberpunk',
      theme: CyberTheme.themeData,
      home: const HomeScreen(),
    );
  }
}

// =============================================================
// 3. HOME SCREEN
// =============================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<VideoModel> _videos = [];
  bool _loading = false;
  String? _error;

  static const String _searchApi = 'http://api.ikyyxd.my.id/search/youtube';
  static const String _apiKey = 'kyzz';

  Future<void> _searchVideos(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _videos = [];
    });

    try {
      final uri = Uri.parse(
        '$_searchApi?apikey=$_apiKey&query=${Uri.encodeComponent(query)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        throw Exception('Server merespon status ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      if (decoded['status'] != true) {
        throw Exception('API mengembalikan status gagal');
      }

      final List<dynamic> rawList = decoded['result'] ?? decoded['data'] ?? [];
      final parsed = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => VideoModel.fromJson(e))
          .toList();

      setState(() {
        _videos = parsed.take(5).toList();
        _loading = false;
        if (_videos.isEmpty) {
          _error = 'Tidak ada hasil ditemukan untuk "$query"';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Gagal mengambil data: $e';
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: CyberTheme.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('⚡ YOUTUBE CYBER'), centerTitle: true),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: CyberTheme.cardPurple,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: CyberTheme.neonPink, width: 1.4),
        boxShadow: [
          BoxShadow(color: CyberTheme.neonPink.withOpacity(0.4), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        textInputAction: TextInputAction.search,
        onSubmitted: _searchVideos,
        decoration: InputDecoration(
          hintText: 'Cari video di YouTube...',
          hintStyle: const TextStyle(color: CyberTheme.greyText),
          prefixIcon: const Icon(Icons.search, color: CyberTheme.neonPink),
          suffixIcon: IconButton(
            icon: const Icon(Icons.arrow_forward, color: CyberTheme.neonPink),
            onPressed: () => _searchVideos(_searchCtrl.text),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: CyberTheme.neonPink));
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: CyberTheme.greyText), textAlign: TextAlign.center),
      );
    }
    if (_videos.isEmpty) {
      return const Center(
        child: Text(
          'Ketik kata kunci lalu tekan Enter\nuntuk mencari video 🔍',
          style: TextStyle(color: CyberTheme.greyText),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      itemCount: _videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _VideoCard(video: _videos[index]),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final VideoModel video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(video: video)));
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: CyberTheme.cardDecoration,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: video.thumbnail,
                width: 120,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 120, height: 80, color: CyberTheme.bgBlack,
                  child: const Icon(Icons.movie, color: CyberTheme.neonPink),
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 120, height: 80, color: CyberTheme.bgBlack,
                  child: const Icon(Icons.broken_image, color: CyberTheme.neonPink),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title, style: CyberTheme.titleStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(video.channel, style: CyberTheme.subStyle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 12, color: CyberTheme.neonPink),
                      const SizedBox(width: 4),
                      Text(video.duration, style: CyberTheme.subStyle),
                      if (video.views != '-') ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.remove_red_eye, size: 12, color: CyberTheme.neonPink),
                        const SizedBox(width: 4),
                        Expanded(child: Text(video.views, style: CyberTheme.subStyle, overflow: TextOverflow.ellipsis)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 4. PLAYER SCREEN (Dengan Double Tap Seek & Fullscreen Toggle)
// =============================================================
class PlayerScreen extends StatefulWidget {
  final VideoModel video;
  const PlayerScreen({super.key, required this.video});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  static const String _downloadApi = 'http://api.ikyyxd.my.id/download/ytmp4';

  VideoPlayerController? _controller;
  bool _resolving = true;
  String? _errorMsg;
  String? _resolvedMp4Url;
  double _speed = 1.0;

  // Visual Overlay Indikator Seek (+10 / -10)
  bool _showSeekForwardOverlay = false;
  bool _showSeekBackwardOverlay = false;
  Timer? _seekOverlayTimer;

  final ReceivePort _port = ReceivePort();
  String? _taskId;
  int _downloadStatus = -1;
  int _downloadProgress = 0;

  final List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _bindDownloaderPort();
    _resolveAndInitPlayer();
  }

  void _bindDownloaderPort() {
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      final id = data[0] as String;
      final status = data[1] as int;
      final progress = data[2] as int;
      if (id == _taskId) {
        setState(() {
          _downloadStatus = status;
          _downloadProgress = progress;
        });
      }
    });
  }

  Future<String?> _extractDownloadUrl(Map<String, dynamic> json) async {
    final result = json['result'];
    if (result is Map<String, dynamic>) {
      final videoUrlObj = result['VideoUrl'];
      if (videoUrlObj is Map<String, dynamic>) {
        final url = videoUrlObj['url'];
        if (url != null && url.toString().trim().isNotEmpty) {
          return url.toString();
        }
      }
    }

    String? tryKeys(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return null;
    }

    var found = tryKeys(json, ['url', 'downloadUrl', 'download_url', 'link', 'mp4']);
    if (found != null) return found;

    for (final wrapperKey in ['data', 'result']) {
      final wrapper = json[wrapperKey];
      if (wrapper is Map<String, dynamic>) {
        found = tryKeys(wrapper, ['url', 'downloadUrl', 'download_url', 'link', 'mp4']);
        if (found != null) return found;
      }
    }
    return null;
  }

  Future<void> _resolveAndInitPlayer() async {
    setState(() {
      _resolving = true;
      _errorMsg = null;
    });

    try {
      final uri = Uri.parse(
        '$_downloadApi?q=${Uri.encodeComponent(widget.video.url)}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 30));

      if (res.statusCode != 200) {
        throw Exception('Server download API status ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final mp4Url = await _extractDownloadUrl(decoded);

      if (mp4Url == null || mp4Url.isEmpty) {
        throw Exception('Link mp4 tidak ditemukan pada response API');
      }

      _resolvedMp4Url = mp4Url;

      final controller = VideoPlayerController.networkUrl(Uri.parse(mp4Url));
      await controller.initialize();
      controller.setPlaybackSpeed(_speed);
      controller.addListener(() => setState(() {}));
      controller.play();

      setState(() {
        _controller = controller;
        _resolving = false;
      });
    } catch (e) {
      setState(() {
        _resolving = false;
        _errorMsg = 'Gagal memuat video: $e';
      });
    }
  }

  @override
  void dispose() {
    _seekOverlayTimer?.cancel();
    _controller?.dispose();
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    // Pastikan orientasi kembali ke normal saat halaman ditutup
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  void _changeSpeed(double speed) {
    setState(() => _speed = speed);
    _controller?.setPlaybackSpeed(speed);
  }

  // Seek maju +10 detik
  void _seekForward() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final currentPos = c.value.position;
    final maxDuration = c.value.duration;
    final newPos = currentPos + const Duration(seconds: 10);
    c.seekTo(newPos > maxDuration ? maxDuration : newPos);

    _triggerSeekOverlay(isForward: true);
  }

  // Seek mundur -10 detik
  void _seekBackward() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final currentPos = c.value.position;
    final newPos = currentPos - const Duration(seconds: 10);
    c.seekTo(newPos < Duration.zero ? Duration.zero : newPos);

    _triggerSeekOverlay(isForward: false);
  }

  void _triggerSeekOverlay({required bool isForward}) {
    _seekOverlayTimer?.cancel();
    setState(() {
      if (isForward) {
        _showSeekForwardOverlay = true;
        _showSeekBackwardOverlay = false;
      } else {
        _showSeekBackwardOverlay = true;
        _showSeekForwardOverlay = false;
      }
    });

    _seekOverlayTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showSeekForwardOverlay = false;
          _showSeekBackwardOverlay = false;
        });
      }
    });
  }

  // Buka Mode Fullscreen
  Future<void> _openFullScreen() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenPlayerPage(
          controller: c,
          onSeekForward: _seekForward,
          onSeekBackward: _seekBackward,
        ),
      ),
    );

    // Kembalikan ke UI Portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _startDownload() async {
    if (_resolvedMp4Url == null) {
      _showSnack('Link download belum siap, coba lagi');
      return;
    }

    final status = await Permission.storage.request();
    if (!status.isGranted && !status.isLimited) {
      _showSnack('Izin penyimpanan ditolak, download dibatalkan');
      return;
    }

    try {
      Directory? dir = await getExternalStorageDirectory();
      dir ??= await getApplicationDocumentsDirectory();

      final safeTitle = widget.video.title.replaceAll(RegExp(r'[^\w\s-]'), '');
      final fileName = '$safeTitle.mp4';

      final taskId = await FlutterDownloader.enqueue(
        url: _resolvedMp4Url!,
        savedDir: dir.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
      );

      setState(() {
        _taskId = taskId;
        _downloadStatus = 1;
        _downloadProgress = 0;
      });

      _showSnack('Download dimulai, cek notifikasi untuk progres');
    } catch (e) {
      _showSnack('Gagal memulai download: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '${twoDigits(d.inHours)}:$minutes:$seconds'.replaceFirst(RegExp(r'^00:'), '');
  }

  String _downloadLabel() {
    if (_downloadStatus == 1) return 'Mengunduh... $_downloadProgress%';
    if (_downloadStatus == 3) return 'Download selesai ✅';
    if (_downloadStatus == 4) return 'Gagal mengunduh ❌';
    return 'DOWNLOAD VIDEO';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: CyberTheme.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('▶ NOW PLAYING')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildVideoArea(),
                const SizedBox(height: 16),
                Text(widget.video.title, style: CyberTheme.titleStyle.copyWith(fontSize: 17)),
                const SizedBox(height: 6),
                Text(widget.video.channel, style: CyberTheme.subStyle),
                const SizedBox(height: 20),
                _buildProgressBar(),
                const SizedBox(height: 16),
                _buildControls(),
                const SizedBox(height: 24),
                _buildSpeedControls(),
                const SizedBox(height: 24),
                _buildDownloadButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CyberTheme.neonPink, width: 1.4),
        boxShadow: [BoxShadow(color: CyberTheme.neonPink.withOpacity(0.35), blurRadius: 14, spreadRadius: 1)],
      ),
      clipBehavior: Clip.hardEdge,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _errorMsg != null
            ? Container(
                color: CyberTheme.cardPurple,
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('⚠ $_errorMsg', style: const TextStyle(color: CyberTheme.greyText), textAlign: TextAlign.center),
                ),
              )
            : (_resolving || _controller == null || !_controller!.value.isInitialized)
                ? Container(
                    color: CyberTheme.cardPurple,
                    alignment: Alignment.center,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: CyberTheme.neonPink),
                        SizedBox(height: 10),
                        Text('Menyiapkan video...', style: TextStyle(color: CyberTheme.greyText)),
                      ],
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller!),

                      // Deteksi Gestur Ketuk 2x Kiri (-10s) & Kanan (+10s)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onDoubleTap: _seekBackward,
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onDoubleTap: _seekForward,
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        ],
                      ),

                      // Indikator Overlay Mundur -10 detik
                      if (_showSeekBackwardOverlay)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(left: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fast_rewind, color: CyberTheme.neonPink, size: 28),
                                SizedBox(width: 4),
                                Text('-10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),

                      // Indikator Overlay Maju +10 detik
                      if (_showSeekForwardOverlay)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(right: 20),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('+10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Icon(Icons.fast_forward, color: CyberTheme.neonPink, size: 28),
                              ],
                            ),
                          ),
                        ),

                      // Tombol Play saat Pause
                      if (!_controller!.value.isPlaying && !_showSeekForwardOverlay && !_showSeekBackwardOverlay)
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            decoration: CyberTheme.glowButton,
                            padding: const EdgeInsets.all(14),
                            child: const Icon(Icons.play_arrow, color: CyberTheme.neonPink, size: 36),
                          ),
                        ),

                      // Tombol Fullscreen (Perbesar Video)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen, color: CyberTheme.neonPink, size: 28),
                          onPressed: _openFullScreen,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final c = _controller;
    final duration = c?.value.duration ?? Duration.zero;
    final position = c?.value.position ?? Duration.zero;
    final maxMs = duration.inMilliseconds.toDouble();
    final curMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs == 0 ? 1.0 : maxMs);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: CyberTheme.neonPink,
            inactiveTrackColor: CyberTheme.cardPurple,
            thumbColor: CyberTheme.neonPink,
            overlayColor: CyberTheme.neonPink.withOpacity(0.2),
            trackHeight: 3,
          ),
          child: Slider(
            min: 0,
            max: maxMs == 0 ? 1.0 : maxMs,
            value: curMs,
            onChanged: (c == null || maxMs == 0) ? null : (v) => c.seekTo(Duration(milliseconds: v.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(position), style: CyberTheme.subStyle),
              Text(_formatDuration(duration), style: CyberTheme.subStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    final isPlaying = _controller?.value.isPlaying ?? false;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: CyberTheme.neonPink, size: 32),
          onPressed: _seekBackward,
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: _togglePlayPause,
          child: Container(
            decoration: CyberTheme.glowButton,
            padding: const EdgeInsets.all(18),
            child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: CyberTheme.neonPink, size: 34),
          ),
        ),
        const SizedBox(width: 20),
        IconButton(
          icon: const Icon(Icons.forward_10, color: CyberTheme.neonPink, size: 32),
          onPressed: _seekForward,
        ),
      ],
    );
  }

  Widget _buildSpeedControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('KECEPATAN VIDEO', style: CyberTheme.neonLabel),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _speedOptions.map((s) {
            final selected = s == _speed;
            return GestureDetector(
              onTap: () => _changeSpeed(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? CyberTheme.neonPink : CyberTheme.cardPurple,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CyberTheme.neonPink, width: 1.2),
                  boxShadow: selected
                      ? [BoxShadow(color: CyberTheme.neonPink.withOpacity(0.6), blurRadius: 10, spreadRadius: 1)]
                      : [],
                ),
                child: Text(
                  '${s}x',
                  style: TextStyle(color: selected ? CyberTheme.bgBlack : CyberTheme.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    final isRunning = _downloadStatus == 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DOWNLOAD', style: CyberTheme.neonLabel),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: isRunning ? null : _startDownload,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: CyberTheme.cardPurple,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CyberTheme.neonPink, width: 1.3),
              boxShadow: [BoxShadow(color: CyberTheme.neonPink.withOpacity(0.35), blurRadius: 10, spreadRadius: 1)],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download, color: CyberTheme.neonPink),
                const SizedBox(width: 8),
                Text(
                  _downloadLabel(),
                  style: const TextStyle(color: CyberTheme.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
        if (isRunning) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _downloadProgress / 100,
              minHeight: 8,
              backgroundColor: CyberTheme.cardPurple,
              valueColor: const AlwaysStoppedAnimation(CyberTheme.neonPink),
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================
// 5. FULLSCREEN PLAYER PAGE (Halaman Pemutar Video Layar Penuh)
// =============================================================
class FullScreenPlayerPage extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;

  const FullScreenPlayerPage({
    super.key,
    required this.controller,
    required this.onSeekForward,
    required this.onSeekBackward,
  });

  @override
  State<FullScreenPlayerPage> createState() => _FullScreenPlayerPageState();
}

class _FullScreenPlayerPageState extends State<FullScreenPlayerPage> {
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    // Rotasi layar ke Landscape & sembunyikan status bar
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            // Deteksi Ketuk 2x Kiri / Kanan pada Mode Fullscreen
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: () {
                      widget.onSeekBackward();
                      _startHideControlsTimer();
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onDoubleTap: () {
                      widget.onSeekForward();
                      _startHideControlsTimer();
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),

            // Control Overlay (Play/Pause, Exit Fullscreen)
            if (_showControls) ...[
              Container(color: Colors.black38),
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: CyberTheme.neonPink, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
                  });
                  _startHideControlsTimer();
                },
                child: Container(
                  decoration: CyberTheme.glowButton,
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: CyberTheme.neonPink,
                    size: 40,
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: CyberTheme.neonPink, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}