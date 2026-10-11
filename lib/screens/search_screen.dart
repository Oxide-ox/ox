import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';
import 'playlist_screen.dart'; // Import halaman playlist baru

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isTyping = false; // Deteksi apakah user sedang mencari lagu

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);

    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 60), // Jarak aman untuk Mini Player
          
          // --- HEADER & SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _isTyping = val.isNotEmpty);
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari lagu, artis, atau lirik...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E293B), // Warna search box Oxide
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
                // Tombol Buka Playlist
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF1E293B), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.library_music, color: Colors.blueAccent),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistScreen()));
                    },
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // --- KONTEN UTAMA ---
          // Jika user sedang mengetik atau mencari, tampilkan List Pencarian
          // Jika kosong, tampilkan Tampilan Home (Spotify-like)
          Expanded(
            child: provider.isSearching
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _isTyping || provider.searchResults.isNotEmpty
                    ? _buildSearchResults(provider)
                    : _buildSpotifyHome(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // UI 1: TAMPILAN HASIL PENCARIAN (LIST)
  // ---------------------------------------------------------
  Widget _buildSearchResults(MusicProvider provider) {
    if (provider.searchResults.isEmpty) {
      return const Center(child: Text("Tidak ada hasil.", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final song = provider.searchResults[index];
        final isSelected = provider.currentIndex == index;
        final isSaved = provider.isSaved(song); // Cek status playlist
        
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tombol Tambah ke Playlist
              IconButton(
                icon: Icon(
                  isSaved ? Icons.favorite : Icons.favorite_border,
                  color: isSaved ? Colors.blueAccent : Colors.grey,
                ),
                onPressed: () => provider.togglePlaylist(song),
              ),
              if (isSelected && provider.isPlaying)
                const Icon(Icons.equalizer, color: Colors.blueAccent)
              else
                const Icon(Icons.play_arrow, color: Colors.grey),
            ],
          ),
          onTap: () => provider.playSong(index),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // UI 2: TAMPILAN HOME ALA SPOTIFY (SAAT KOSONG)
  // ---------------------------------------------------------
  Widget _buildSpotifyHome() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. CHIPS (Semua, Musik, Podcast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildChip("Semua", isActive: true),
                const SizedBox(width: 10),
                _buildChip("Musik"),
                const SizedBox(width: 10),
                _buildChip("Podcast & Acara"),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. GRID KOTAK 2 KOLOM (Campuran Playlist)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildGridCard("Discover Weekly", Colors.purple),
                _buildGridCard("Good Vibes", Colors.orange),
                _buildGridCard("Viral Indonesia", Colors.green),
                _buildGridCard("Oxide Mix", Colors.blueAccent),
                _buildGridCard("Top Hits", Colors.redAccent),
                _buildGridCard("Chill Track", Colors.teal),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // 3. HORIZONTAL LIST (Baru Saja Didengar)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text("Baru saja didengar", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildHorizontalCard("Lagi Viral", Icons.trending_up, Colors.green),
                _buildHorizontalCard("Daily Mix 1", Icons.album, Colors.blue),
                _buildHorizontalCard("Acoustic", Icons.music_note, Colors.brown),
                _buildHorizontalCard("Syam Music", Icons.headphones, Colors.deepPurple),
              ],
            ),
          ),
          const SizedBox(height: 100), // Spasi bawah
        ],
      ),
    );
  }

  // Komponen Helper untuk UI Home
  Widget _buildChip(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blueAccent : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildGridCard(String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), bottomLeft: Radius.circular(6))),
            child: const Center(child: Icon(Icons.music_note, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildHorizontalCard(String title, IconData icon, Color color) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110, width: 110,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Icon(icon, size: 40, color: Colors.white54)),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
