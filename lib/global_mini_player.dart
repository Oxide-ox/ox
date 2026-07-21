import 'package:flutter/material.dart';
import 'music_service.dart';

class GlobalMiniPlayer extends StatefulWidget {
  const GlobalMiniPlayer({super.key});

  @override
  State<GlobalMiniPlayer> createState() =>
      _GlobalMiniPlayerState();
}

class _GlobalMiniPlayerState
    extends State<GlobalMiniPlayer> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: MusicService.stateStream,
      builder: (context, snapshot) {

        if (MusicService.currentTitle ==
            "Tidak ada lagu") {
          return const SizedBox();
        }

        return Container(
          height: 70,
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Row(
            children: [

              if (MusicService.currentImage
                  .isNotEmpty)
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child: Image.network(
                    MusicService.currentImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      MusicService.currentTitle,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      MusicService.currentArtist,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  MusicService.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  color: Colors.white,
                  size: 35,
                ),
                onPressed: () async {
                  if (MusicService.isPlaying) {
                    await MusicService.pause();
                  } else {
                    await MusicService.resume();
                  }
                },
              ),

              IconButton(
                icon: const Icon(
                  Icons.stop_circle,
                  color: Colors.red,
                  size: 35,
                ),
                onPressed: () async {
                  await MusicService.stop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}