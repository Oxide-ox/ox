import 'package:http/http.dart' as http;
import 'dart:convert';

class SoundCloudScraper {
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  // Helper untuk fetch
  static Future<String> _fetch(String url, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': userAgent,
          'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
          if (headers != null) ...headers,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Fetch error: $e');
    }
  }

  // ==========================================
  // SOUNDCLOUD SEARCH (>= 25 Data)
  // ==========================================
  static Future<List<SoundCloudTrack>> scSearch(String query) async {
    try {
      // Client-ID ekstrak dari SC web
      final clientId = await _getClientId();

      final apiUrl =
          'https://api-v2.soundcloud.com/search/tracks?q=${Uri.encodeComponent(query)}&client_id=$clientId&limit=30';

      final html = await _fetch(apiUrl);
      final parsed = jsonDecode(html) as Map<String, dynamic>;

      final tracks = <SoundCloudTrack>[];

      if (parsed['collection'] is List) {
        for (var t in parsed['collection']) {
          if (t is Map<String, dynamic>) {
            try {
              String artwork = '';
              if (t['artwork_url'] != null) {
                artwork = (t['artwork_url'] as String)
                    .replaceFirst('-large.jpg', '-t500x500.jpg');
              } else if (t['user'] != null && t['user']['avatar_url'] != null) {
                artwork = t['user']['avatar_url'];
              }

              tracks.add(SoundCloudTrack(
                title: t['title'] ?? 'Unknown',
                url: t['permalink_url'] ?? '',
                trackId: t['id'] ?? 0,
                thumbnail: artwork,
                artist: SoundCloudArtist(
                  name: t['user']?['username'] ?? 'Unknown',
                  url: t['user']?['permalink_url'] ?? '',
                  followers: t['user']?['followers_count'] ?? 0,
                ),
                duration: Duration(milliseconds: t['duration'] ?? 0),
                playCount: t['playback_count'] ?? 0,
              ));
            } catch (e) {
              debugPrint('Error parsing track: $e');
            }
          }
        }
      }

      return tracks;
    } catch (e) {
      debugPrint('SoundCloud Search Error: $e');
      rethrow;
    }
  }

  // ==========================================
  // SOUNDCLOUD DOWNLOADER / RESOLVER
  // ==========================================
  static Future<SoundCloudDownloadData> scDownload(String scUrl) async {
    try {
      final html = await _fetch(scUrl);

      // Extract meta data
      final titleMatch = RegExp(r'<meta property="og:title" content="(.*?)"\/>')
          .firstMatch(html);
      final imageMatch = RegExp(r'<meta property="og:image" content="(.*?)"\/>')
          .firstMatch(html);
      final descMatch = RegExp(r'<meta property="og:description" content="(.*?)"\/>')
          .firstMatch(html);

      if (titleMatch == null) {
        throw Exception('URL SoundCloud tidak valid');
      }

      final title = titleMatch.group(1) ?? 'Unknown';
      final thumbnail = imageMatch?.group(1) ?? '';
      final artist = descMatch?.group(1) ?? 'Unknown Artist';

      // Ambil audio URL dari JS inline atau data
      final audioUrl = _extractAudioUrl(html);

      return SoundCloudDownloadData(
        title: title,
        artist: artist,
        thumbnail: thumbnail,
        soundcloudUrl: scUrl,
        audioUrl: audioUrl,
      );
    } catch (e) {
      debugPrint('SoundCloud Download Error: $e');
      rethrow;
    }
  }

  // ==========================================
  // EXTRACT CLIENT ID
  // ==========================================
  static Future<String> _getClientId() async {
    try {
      final html = await _fetch('https://soundcloud.com');

      // Cari script URL
      final scriptRegex =
          RegExp(r'https://a-v2\.sndcdn\.com/assets/[a-zA-Z0-9\-]+\.js');
      final scriptMatches = scriptRegex.allMatches(html).toList();

      // Cek 3 script terakhir
      for (int i = scriptMatches.length - 1; i >= scriptMatches.length - 3 && i >= 0; i--) {
        final jsUrl = scriptMatches[i].group(0);
        if (jsUrl != null) {
          try {
            final jsText = await _fetch(jsUrl);
            final clientMatch =
                RegExp(r'client_id[:=]"([a-zA-Z0-9]{32})"').firstMatch(jsText);

            if (clientMatch != null) {
              return clientMatch.group(1) ?? 'iZIs9mchVUYP3fh3R0L5R9Rz3N1g5dK';
            }
          } catch (e) {
            debugPrint('Error fetching script: $e');
          }
        }
      }

      // Fallback Client ID
      return 'iZIs9mchVUYP3fh3R0L5R9Rz3N1g5dK';
    } catch (e) {
      debugPrint('Get ClientID Error: $e');
      return 'iZIs9mchVUYP3fh3R0L5R9Rz3N1g5dK';
    }
  }

  // ==========================================
  // EXTRACT AUDIO URL DARI HTML
  // ==========================================
  static String _extractAudioUrl(String html) {
    try {
      // Cari progressive URL dari inline JS
      final progressiveMatch = RegExp(
        r'"progressive":\[\{"url":"([^"]+)"',
      ).firstMatch(html);

      if (progressiveMatch != null) {
        return progressiveMatch.group(1) ?? '';
      }

      // Cari HLS URL
      final hlsMatch = RegExp(
        r'"hls_mp3_128_url":"([^"]+)"',
      ).firstMatch(html);

      if (hlsMatch != null) {
        return hlsMatch.group(1) ?? '';
      }

      // Cari data dari window object
      final dataMatch = RegExp(
        r'window\.__data\s*=\s*({.*?"url":"([^"]+)".*?})',
      ).firstMatch(html);

      if (dataMatch != null) {
        return dataMatch.group(2) ?? '';
      }

      return '';
    } catch (e) {
      debugPrint('Extract Audio URL Error: $e');
      return '';
    }
  }

  // ==========================================
  // GET DIRECT DOWNLOAD LINK
  // ==========================================
  static Future<String> getDirectDownloadUrl(String scUrl) async {
    try {
      final data = await scDownload(scUrl);

      if (data.audioUrl.isEmpty) {
        throw Exception('Failed to extract audio URL from SoundCloud');
      }

      return data.audioUrl;
    } catch (e) {
      debugPrint('Get Direct Download URL Error: $e');
      rethrow;
    }
  }
}

// ==========================================
// MODEL DATA STRUCTURES
// ==========================================

class SoundCloudTrack {
  final String title;
  final String url;
  final int trackId;
  final String thumbnail;
  final SoundCloudArtist artist;
  final Duration duration;
  final int playCount;

  SoundCloudTrack({
    required this.title,
    required this.url,
    required this.trackId,
    required this.thumbnail,
    required this.artist,
    required this.duration,
    required this.playCount,
  });

  @override
  String toString() {
    return '''SoundCloudTrack(
      title: $title,
      url: $url,
      trackId: $trackId,
      artist: ${artist.name},
      duration: ${duration.inSeconds}s,
      playCount: $playCount
    )''';
  }
}

class SoundCloudArtist {
  final String name;
  final String url;
  final int followers;

  SoundCloudArtist({
    required this.name,
    required this.url,
    required this.followers,
  });

  @override
  String toString() {
    return 'SoundCloudArtist(name: $name, followers: $followers)';
  }
}

class SoundCloudDownloadData {
  final String title;
  final String artist;
  final String thumbnail;
  final String soundcloudUrl;
  final String audioUrl;

  SoundCloudDownloadData({
    required this.title,
    required this.artist,
    required this.thumbnail,
    required this.soundcloudUrl,
    required this.audioUrl,
  });

  @override
  String toString() {
    return '''SoundCloudDownloadData(
      title: $title,
      artist: $artist,
      audioUrl: ${audioUrl.isNotEmpty ? 'Available' : 'Not found'}
    )''';
  }
}
