import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';

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
      child: Column(
        children: [
          const SizedBox(height: 70), // Beri jarak agar tidak tertutup Mini Player
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari lagu...',
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    provider.searchMusic(_searchController.text);
                  },
                ),
              ),
              onSubmitted: (value) => provider.searchMusic(value),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: provider.isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.searchResults.length,
                    itemBuilder: (context, index) {
                      final song = provider.searchResults[index];
                      final isSelected = provider.currentIndex == index;
                      
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
                          style: TextStyle(
                            color: isSelected ? Colors.blueAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(song['artist'], style: const TextStyle(color: Colors.grey)),
                        trailing: isSelected && provider.isPlaying 
                            ? const Icon(Icons.equalizer, color: Colors.blueAccent)
                            : const Icon(Icons.play_arrow, color: Colors.grey),
                        onTap: () => provider.playSong(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
