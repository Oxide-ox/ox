import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/music_provider.dart';
import 'search_screen.dart';
import 'full_player_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background UI (Pencarian & List)
          const SearchScreen(),
          
          // Mini Player Mengambang di Atas (Top)
          Positioned(
            top: 50,
            left: 20,
            right: 80,
            child: Consumer<MusicProvider>(
              builder: (context, provider, child) {
                if (provider.currentSong == null) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () => _showFullPlayer(context),
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
                            width: 35, height: 35, fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            provider.currentSong!['title'],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => const FullPlayerScreen(),
    );
  }
}
