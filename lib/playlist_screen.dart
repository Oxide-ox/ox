import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final playlist = provider.myPlaylist;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Warna background gelap Oxide
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Playlist Favorit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Header Aksi (Mainkan & Acak)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${playlist.length} Lagu Disimpan", style: const TextStyle(color: Colors.grey)),
                Row(
                  children: [
                    // Tombol Acak / Shuffle
                    IconButton(
                      icon: const Icon(Icons.shuffle, color: Colors.blueAccent),
                      onPressed: () {
                        if (playlist.isNotEmpty) {
                          provider.shufflePlaylist();
                        }
                      },
                    ),
                    // Tombol Play Besar
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.blueAccent,
                      onPressed: () {
                        // Secara teknis kita perlu mengatur antrean (queue) terpisah, 
                        // tapi untuk saat ini bisa diakali dengan mencari index aslinya di searchResults
                        // (Karena sistem play API terhubung dengan search index)
                      },
                      child: const Icon(Icons.play_arrow, color: Colors.white),
                    ),
                  ],
                )
              ],
            ),
          ),
          
          // Daftar Lagu Playlist
          Expanded(
            child: playlist.isEmpty
                ? const Center(
                    child: Text("Belum ada lagu yang ditambahkan.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: playlist.length,
                    itemBuilder: (context, index) {
                      final song = playlist[index];
                      
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl: song['thumbnail'],
                            width: 55, height: 55, fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          song['title'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(song['artist'], style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          onPressed: () => provider.togglePlaylist(song),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
