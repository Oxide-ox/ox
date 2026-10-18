import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final song = provider.currentSong;

    if (song == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("Tidak ada lagu yang diputar", style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Warna gelap ala Spotify
      body: SafeArea(
        child: Column(
          children: [
            // TOMBOL KEMBALI (PANAH BAWAH)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), 
                  const Text(
                    "Now Playing",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // GAMBAR THUMBNAIL BESAR
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          song['thumbnail'] ?? '',
                          width: MediaQuery.of(context).size.width - 48,
                          height: MediaQuery.of(context).size.width - 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: MediaQuery.of(context).size.width - 48,
                            height: MediaQuery.of(context).size.width - 48,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // JUDUL DAN ARTIS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song['title'] ?? 'Unknown Title',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  song['artist'] ?? 'Unknown Artist',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // TOMBOL FAVORIT
                          IconButton(
                            icon: Icon(
                              provider.isSaved(song) ? Icons.favorite : Icons.favorite_border,
                              color: provider.isSaved(song) ? Colors.green : Colors.white,
                              size: 32,
                            ),
                            onPressed: () => provider.togglePlaylist(song),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // SLIDER PROGRESS BAR
                      StreamBuilder<Duration>(
                        stream: provider.player.positionStream,
                        builder: (context, snapshot) {
                          final position = snapshot.data ?? Duration.zero;
                          final duration = provider.player.duration ?? Duration.zero;
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: Colors.white,
                                ),
                                child: Slider(
                                  value: position.inSeconds.toDouble(),
                                  max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                                  onChanged: (value) {
                                    provider.player.seek(Duration(seconds: value.toInt()));
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  Text(_formatDuration(duration), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // TOMBOL PLAY, NEXT, PREV
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            iconSize: 40,
                            icon: const Icon(Icons.skip_previous, color: Colors.white),
                            onPressed: () => provider.previousSong(),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              iconSize: 50,
                              icon: provider.isLoadingAudio 
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : Icon(
                                      provider.isPlaying ? Icons.pause : Icons.play_arrow,
                                      color: Colors.black,
                                    ),
                              onPressed: provider.isLoadingAudio ? null : () => provider.togglePlayPause(),
                            ),
                          ),
                          IconButton(
                            iconSize: 40,
                            icon: const Icon(Icons.skip_next, color: Colors.white),
                            onPressed: () => provider.nextSong(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // KOTAK LIRIK (Scrollable mengikuti scroll halaman)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Lyrics",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (provider.isLoadingLyrics)
                                  const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.isLoadingLyrics 
                                  ? "Memuat lirik..." 
                                  : (provider.currentLyrics ?? "Lirik tidak tersedia."),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
