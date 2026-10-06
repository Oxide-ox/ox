import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'music_provider.dart'; // Ganti sesuai letak file provider-mu
import 'full_player_screen.dart'; // Ganti sesuai letak full player

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50, // Posisi dari atas (sesuaikan agar tidak nabrak AppBar)
      left: 20,
      right: 80, // Diberi jarak kanan agar tidak menutupi tombol profil/menu
      child: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          if (provider.currentSong == null) return const SizedBox.shrink(); // Sembunyikan jika tidak ada lagu
          
          return Material(
            color: Colors.transparent, // Penting agar tidak ada background kotak putih
            child: GestureDetector(
              onTap: () {
                // Tampilkan Full Player saat di-klik
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: const Color(0xFF0F172A),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                  builder: (context) => const FullPlayerScreen(),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: provider.currentSong!['thumbnail'],
                        width: 35,
                        height: 35,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.currentSong!['title'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: provider.isLoadingAudio 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(provider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.blueAccent),
                      onPressed: () => provider.togglePlayPause(),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
