import 'package:flutter/material.dart';
import 'widgets/ig_user_post.dart'; // import widget user post yang dipindah

class InstagramMainFeedPage extends StatefulWidget {
  const InstagramMainFeedPage({super.key});

  @override
  State<InstagramMainFeedPage> createState() => _InstagramMainFeedPageState();
}

class _InstagramMainFeedPageState extends State<InstagramMainFeedPage> {
  // Warna tema khas oxide2
  final Color primaryDark = const Color(0xFF1A0505);
  final Color cardDark = const Color(0xFF261A1A);
  final Color primaryRed = const Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        title: const Text(
          'Instagram',
          style: TextStyle(
            fontFamily: 'Billabong', // atau font standar jika belum di-import
            fontSize: 28,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10, // Sesuaikan dengan jumlah data post
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            color: cardDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Post
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    'User_$index',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.more_vert, color: Colors.white),
                ),
                // Gambar Post
                Container(
                  height: 300,
                  width: double.infinity,
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                ),
                // Action Buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.mode_comment_outlined, color: Colors.white),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
