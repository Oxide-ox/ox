import 'package:flutter/material.dart';

class ProfileIgPage extends StatefulWidget {
  final String? username;

  const ProfileIgPage({super.key, this.username});

  @override
  State<ProfileIgPage> createState() => _ProfileIgPageState();
}

class _ProfileIgPageState extends State<ProfileIgPage> {
  final List<String> imagesUrl = [
    'https://picsum.photos/300/300?random=1',
    'https://picsum.photos/300/300?random=2',
    'https://picsum.photos/300/300?random=3',
  ];

  @override
  Widget build(BuildContext context) {
    final displayUsername = widget.username ?? 'user_instagram';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0E),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.lock_outline, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              displayUsername,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info Profil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 45, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('3', 'Postingan'),
                        _buildStatColumn('140', 'Pengikut'),
                        _buildStatColumn('120', 'Mengikuti'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bio Profil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayUsername,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Digital Creator 🚀\nWelcome to my Instagram Profile!',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Edit Profil
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF261A1A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Text(
                    'Edit Profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Bar Icon Grid
            const Divider(color: Colors.white10, height: 1),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(Icons.grid_on, color: Colors.white),
                  onPressed: null,
                ),
                IconButton(
                  icon: Icon(Icons.video_collection_outlined, color: Colors.grey),
                  onPressed: null,
                ),
                IconButton(
                  icon: Icon(Icons.person_pin_outlined, color: Colors.grey),
                  onPressed: null,
                ),
              ],
            ),

            // Grid Foto
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: imagesUrl.length,
              itemBuilder: (context, index) {
                return Image.network(
                  imagesUrl[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade900,
                    child: const Icon(Icons.image, color: Colors.white24),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
