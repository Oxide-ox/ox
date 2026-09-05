import 'package:flutter/material.dart';

class UserPost extends StatefulWidget {
  final String username;
  final String caption;
  final String userImage;
  final String postImage;
  final String likesCount;
  final String commentsCount;
  final String timeAgo;

  const UserPost({
    super.key,
    this.username = 'user_instagram',
    this.caption = 'Postingan Instagram baru 🔥',
    this.userImage = 'https://picsum.photos/100/100',
    this.postImage = 'https://picsum.photos/400/400',
    this.likesCount = '1.234',
    this.commentsCount = '25',
    this.timeAgo = '1 hari yang lalu',
  });

  @override
  State<UserPost> createState() => _UserPostState();
}

class _UserPostState extends State<UserPost> {
  bool isLiked = false;
  bool isSaved = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF160A22), // Tema Gelap Oxide2
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserPosted(),
          _buildPostImage(),
          _buildIconsButton(),
          _buildAmountOfLikes(),
          const SizedBox(height: 4),
          _buildNameAndCaption(),
          const SizedBox(height: 4),
          _buildComments(),
          const SizedBox(height: 8),
          _buildAddComment(),
          const SizedBox(height: 6),
          _buildPublicationTime(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildUserPosted() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: NetworkImage(widget.userImage),
              ),
              const SizedBox(width: 10),
              Text(
                widget.username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Icon(Icons.more_vert, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          isLiked = true;
        });
      },
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        width: double.infinity,
        child: Image.network(
          widget.postImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 250,
            color: Colors.black26,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white54, size: 50),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconsButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  isLiked = !isLiked;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.send_outlined, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        IconButton(
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              isSaved = !isSaved;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAmountOfLikes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        '${widget.likesCount} menyukai',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildNameAndCaption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.white),
          children: [
            TextSpan(
              text: '${widget.username} ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: widget.caption,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComments() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        'Lihat semua ${widget.commentsCount} komentar',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildAddComment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.grey.shade800,
                backgroundImage: NetworkImage(widget.userImage),
              ),
              const SizedBox(width: 10),
              const Text(
                'Tambahkan komentar...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Row(
            children: [
              Text('😂', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text('❤️', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Icon(Icons.add_circle_outline, color: Colors.grey, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPublicationTime() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        widget.timeAgo,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 11,
        ),
      ),
    );
  }
}
