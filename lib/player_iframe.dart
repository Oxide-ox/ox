import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class PlayerIframePage extends StatefulWidget {
  final String videoId;

  const PlayerIframePage({
    super.key,
    required this.videoId,
  });

  @override
  State<PlayerIframePage> createState() =>
      _PlayerIframePageState();
}

class _PlayerIframePageState
    extends State<PlayerIframePage> {

  late YoutubePlayerController controller;

  @override
  void initState() {
    super.initState();

    controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        // PENTING: Tambahkan ini untuk mengelabui sistem YouTube
        // seolah-olah video diputar dari situs resmi mereka.
        origin: 'https://www.youtube.com', 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Tambahkan AppBar jika ingin user bisa menekan tombol kembali (back)
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: YoutubePlayerScaffold(
        controller: controller,
        builder: (context, player) {
          return Center(
            child: player,
          );
        },
      ),
    );
  }

  // Tambahkan dispose untuk mencegah kebocoran memori (memory leak)
  @override
  void dispose() {
    controller.close();
    super.dispose();
  }
}
