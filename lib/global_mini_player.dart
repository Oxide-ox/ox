import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'providers/music_provider.dart'; // Ganti sesuai letak file provider-mu
import 'screens/full_player_screen.dart'; // Ganti sesuai letak full player

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
        return Positioned(
      top: 55, // Jarak dari atas layar (sesuaikan agar pas di bawah tombol dashboardmu)
      left: 16,
      right: 70, // Beri jarak kanan agar tidak menutupi tombol lonceng/profil
      child: Consumer<MusicProvider>(
        builder: (context, provider, child) {
          if (provider.currentSong == null) return const SizedBox.shrink();
          
          return Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                // Gunakan PUSH biasa alih-alih BottomSheet
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FullPlayerScreen()),
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
