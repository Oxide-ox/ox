import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen> {
  // Flag untuk memastikan API Lirik hanya dipanggil sekali saat layar ini dibuka
  bool _hasFetchedLyrics = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final song = provider.currentSong;

    if (song == null) return const SizedBox.shrink();

    // Jalankan API lirik otomatis saat lagu ini diputar di Full Player
    if (!_hasFetchedLyrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchLyrics(song['title'], song['artist']);
      });
      _hasFetchedLyrics = true;
    }

    // Warna dasar Spotify (Bisa disesuaikan dengan tema Oxide)
    final Color bgColor = const Color(0xFF121212);
    final Color dominantColor = const Color(0xFF8B0000); // Merah gelap sebagai contoh gradasi

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // --- 1. BACKGROUND GRADIENT ---
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  dominantColor.withOpacity(0.8),
                  bgColor,
                ],
              ),
            ),
          ),

          // --- 2. KONTEN UTAMA (SCROLLABLE) ---
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER: TOMBOL KEMBALI & MENU ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                        // Tombol panah ini akan menutup Full Player dan kembali ke Dashboard
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        "SEDANG MEMUTAR",
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // --- COVER ARTWORK (KOTAK BESAR) ---
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: song['thumbnail'],
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: MediaQuery.of(context).size.width * 0.85,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: MediaQuery.of(context).size.width * 0.85,
                          color: Colors.grey[800],
                          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- JUDUL LAGU & ARTIS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song['title'],
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song['artist'],
                              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                        onPressed: () {}, // Fitur tambah playlist/favorit
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- SLIDER & WAKTU REALTIME ---
                  StreamBuilder<Duration>(
                    stream: provider.player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = provider.player.duration ?? Duration.zero;

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white30,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              min: 0,
                              max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                              value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0),
                              onChanged: (value) => provider.player.seek(Duration(seconds: value.toInt())),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(position), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              Text(_formatDuration(duration), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // --- KONTROL MEDIA (PLAY/PAUSE/NEXT) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle, color: Colors.white54, size: 28),
                        onPressed: () {},
                      ),
                      IconButton(
                        iconSize: 40,
                        color: Colors.white,
                        icon: const Icon(Icons.skip_previous),
                        onPressed: () {
                          _hasFetchedLyrics = false; // Reset lirik saat ganti lagu
                          provider.previousSong();
                        },
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          iconSize: 38,
                          color: Colors.black,
                          icon: provider.isLoadingAudio
                              ? const CircularProgressIndicator(color: Colors.black)
                              : Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: () => provider.togglePlayPause(),
                        ),
                      ),
                      IconButton(
                        iconSize: 40,
                        color: Colors.white,
                        icon: const Icon(Icons.skip_next),
                        onPressed: () {
                          _hasFetchedLyrics = false; // Reset lirik saat ganti lagu
                          provider.nextSong();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat, color: Colors.white54, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- 3. BAGIAN LIRIK (Scroll ke Bawah) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828), // Warna card abu-abu gelap
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Lirik",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.open_in_full, color: Colors.white.withOpacity(0.5), size: 18),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Isi Lirik
                        if (provider.isLoadingLyrics)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30.0),
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          )
                        else if (provider.currentLyrics == null || provider.currentLyrics!.isEmpty)
                          const Text(
                            "Lirik tidak tersedia.",
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          )
                        else
                          Text(
                            provider.currentLyrics!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.6, // Jarak antar baris
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50), // Spasi bawah agar enak di-scroll
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Format durasi audio (00:00)
  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
