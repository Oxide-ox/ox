import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/music_provider.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MusicProvider>(context);
    final song = provider.currentSong;

    if (song == null) return const SizedBox.shrink();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(25),
      child: Column(
        children: [
          Container(
            width: 40, height: 5,
            decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 40),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: song['thumbnail'],
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            song['title'],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(song['artist'], style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 30),
          StreamBuilder<Duration>(
            stream: provider.player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = provider.player.duration ?? Duration.zero;

              return Column(
                children: [
                  Slider(
                    activeColor: Colors.blueAccent,
                    inactiveColor: Colors.grey[800],
                    min: 0,
                    max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                    value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0),
                    onChanged: (value) => provider.player.seek(Duration(seconds: value.toInt())),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position), style: const TextStyle(color: Colors.grey)),
                        Text(_formatDuration(duration), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(iconSize: 45, color: Colors.white, icon: const Icon(Icons.skip_previous), onPressed: () => provider.previousSong()),
              GestureDetector(
                onTap: () => provider.togglePlayPause(),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  child: provider.isLoadingAudio 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, size: 40, color: Colors.white),
                ),
              ),
              IconButton(iconSize: 45, color: Colors.white, icon: const Icon(Icons.skip_next), onPressed: () => provider.nextSong()),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
