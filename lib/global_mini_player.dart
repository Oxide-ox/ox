import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/music_provider.dart';
import 'screens/full_player_screen.dart';

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final song = provider.currentSong;

    // Jika tidak ada lagu yang dipilih, sembunyikan mini player
    if (song == null) return const SizedBox.shrink();

    // BUNGKUS DENGAN GESTURE DETECTOR UNTUK NAVIGASI KE FULL PLAYER
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FullPlayerScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.amberAccent.shade400, // Warna kuning sesuai desain kamu
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Thumbnail Mini
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                song['thumbnail'] ?? '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Judul dan Artis Mini
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song['title'] ?? 'Unknown Title',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    song['artist'] ?? 'Unknown Artist',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Tombol Play / Pause di Mini Player
            IconButton(
              icon: provider.isLoadingAudio
                  ? const SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)
                    )
                  : Icon(
                      provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.black,
                      size: 36,
                    ),
              onPressed: provider.isLoadingAudio ? null : () => provider.togglePlayPause(),
            ),
          ],
        ),
      ),
    );
  }
}
