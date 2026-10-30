import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';
import '../global_mini_player.dart';
import 'playlist_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);

    return SafeArea(
      child: Stack(
        children: [
          // 1. KONTEN UTAMA (Search Bar & List Lagu)
          Column(
            children: [
              const SizedBox(height: 20),
              
              // SEARCH BAR & BUTTON PLAYLIST
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Cari lagu, artis, atau lirik...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search, color: Colors.white),
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (_searchController.text.isNotEmpty) {
                                provider.searchMusic(_searchController.text);
                              }
                            },
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) provider.searchMusic(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                      child: IconButton(
                        icon: const Icon(Icons.library_music, color: Color(0xFF4A6BFF)),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistScreen()));
                        },
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // DAFTAR LAGU (Dikasih spasi bawah biar nggak tertutup mini player)
              Expanded(
                child: provider.isSearching
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A6BFF)))
                    : _buildSearchResults(provider),
              ),
            ],
          ),

          // 2. GLOBAL MINI PLAYER DI PINDAH KE BAWAH (Melayang di atas list lagu)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 10, // Posisi di bawah, aman dari kotak kuning atas!
            child: GlobalMiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(MusicProvider provider) {
    if (provider.searchResults.isEmpty) {
      return const Center(
        child: Text(
          "Ketik judul lagu atau artis di atas untuk mulai mencari.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 70), // Spasi agar item terakhir tidak tertutup mini player bawah
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final song = provider.searchResults[index];
        final isSelected = provider.currentIndex == index && provider.activeQueue == provider.searchResults;
        final isSaved = provider.isSaved(song);
        
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: song['thumbnail'] ?? '',
              width: 55, 
              height: 55, 
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const Icon(Icons.music_note, color: Colors.white),
            ),
          ),
          title: Text(
            song['title'] ?? 'Unknown Title',
            style: TextStyle(
              color: isSelected ? const Color(0xFF4A6BFF) : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song['artist'] ?? 'Unknown Artist', 
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved ? const Color(0xFF4A6BFF) : Colors.grey,
                ),
                onPressed: () => provider.togglePlaylist(song),
              ),
              if (isSelected && provider.isPlaying)
                const Icon(Icons.equalizer, color: Color(0xFF4A6BFF))
              else
                const Icon(Icons.play_arrow, color: Colors.grey),
            ],
          ),
          onTap: () => provider.playSong(index),
        );
      },
    );
  }
}
