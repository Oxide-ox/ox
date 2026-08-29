import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SoundCloudScraper {
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  static const String fallbackClientId = 'iZIs9mchVUYP3fh3R0L5R9Rz3N1g5dK';
  static String _cachedClientId = fallbackClientId;

  static Future<String> _fetch(String url, {Map<String, String>? headers, int retries = 2}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        debugPrint('🌐 Fetching (attempt ${attempt + 1}): $url');
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': userAgent,
            'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
            'Accept': 'application/json, text/plain, */*',
            'Referer': 'https://soundcloud.com/',
            if (headers != null) ...headers,
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          debugPrint('✅ Fetch success');
          return response.body;
        } else if (response.statusCode == 429) {
          debugPrint('⚠️ Rate limited, retry...');
          await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('❌ Fetch error (attempt ${attempt + 1}): $e');
        if (attempt < retries) {
          await Future.delayed(Duration(seconds: 2));
        } else {
          throw Exception('Fetch failed after $retries retries: $e');
        }
      }
    }
    throw Exception('Fetch failed');
  }

  // ==========================================
  // GET CLIENT ID (with cache)
  // ==========================================
  static Future<String> _getClientId() async {
    try {
      debugPrint('🔑 Getting ClientID...');
      final html = await _fetch('https://soundcloud.com');

      final scriptRegex = RegExp(r'https://a-v2\.sndcdn\.com/assets/[a-zA-Z0-9\-]+\.js');
      final scriptMatches = scriptRegex.allMatches(html).toList();

      debugPrint('📝 Found ${scriptMatches.length} script tags');

      for (int i = scriptMatches.length - 1; i >= scriptMatches.length - 5 && i >= 0; i--) {
        try {
          final jsUrl = scriptMatches[i].group(0);
          if (jsUrl != null) {
            final jsText = await _fetch(jsUrl);
            final clientMatch = RegExp(r'client_id[:=]["\']?([a-zA-Z0-9]{32})["\']?').firstMatch(jsText);

            if (clientMatch != null) {
              final clientId = clientMatch.group(1) ?? fallbackClientId;
              _cachedClientId = clientId;
              debugPrint('✅ ClientID found: $clientId');
              return clientId;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching script: $e');
        }
      }

      debugPrint('⚠️ Using fallback ClientID');
      return fallbackClientId;
    } catch (e) {
      debugPrint('❌ Get ClientID Error: $e, using fallback');
      return fallbackClientId;
    }
  }

  // ==========================================
  // SOUNDCLOUD SEARCH
  // ==========================================
  static Future<List<SoundCloudTrack>> scSearch(String query) async {
    try {
      debugPrint('🔍 Searching: "$query"');
      final clientId = _cachedClientId;

      final apiUrl =
          'https://api-v2.soundcloud.com/search/tracks?q=${Uri.encodeComponent(query)}&client_id=$clientId&limit=30';

      final html = await _fetch(apiUrl);
      final parsed = jsonDecode(html) as Map<String, dynamic>;

      final tracks = <SoundCloudTrack>[];

      if (parsed['collection'] is List) {
        for (var t in parsed['collection']) {
          if (t is Map<String, dynamic>) {
            try {
              // Extract essential fields
              final id = t['id'];
              final title = t['title'] ?? 'Unknown';
              final url = t['permalink_url'] ?? '';
              
              if (url.isEmpty) continue;

              // Artwork
              String artwork = '';
              if (t['artwork_url'] != null) {
                artwork = (t['artwork_url'] as String)
                    .replaceFirst('-large.jpg', '-t500x500.jpg');
              } else if (t['user'] != null && t['user']['avatar_url'] != null) {
                artwork = t['user']['avatar_url'];
              }

              // Duration
              final duration = Duration(milliseconds: t['duration'] ?? 0);

              // Artist info
              final artist = SoundCloudArtist(
                name: t['user']?['username'] ?? 'Unknown Artist',
                url: t['user']?['permalink_url'] ?? '',
                followers: t['user']?['followers_count'] ?? 0,
              );

              tracks.add(SoundCloudTrack(
                title: title,
                url: url,
                trackId: id ?? 0,
                thumbnail: artwork,
                artist: artist,
                duration: duration,
                playCount: t['playback_count'] ?? 0,
              ));

              debugPrint('📌 Added: $title by ${artist.name}');
            } catch (e) {
              debugPrint('⚠️ Error parsing track: $e');
            }
          }
        }
      }

      debugPrint('✅ Found ${tracks.length} tracks');
      return tracks;
    } catch (e) {
      debugPrint('❌ Search Error: $e');
      return [];
    }
  }

  // ==========================================
  // EXTRACT AUDIO URL
  // ==========================================
  static String _extractAudioUrl(String html) {
    try {
      // Try progressive URL first (best quality)
      var progressiveMatch = RegExp(
        r'"progressive":\s*\[\s*\{\s*"url":\s*"([^"]+)"',
      ).firstMatch(html);

      if (progressiveMatch != null) {
        final url = progressiveMatch.group(1);
        if (url != null && url.isNotEmpty) {
          debugPrint('✅ Found progressive URL');
          return url;
        }
      }

      // Try HLS URL
      var hlsMatch = RegExp(
        r'"hls_mp3_128_url":\s*"([^"]+)"',
      ).firstMatch(html);

      if (hlsMatch != null) {
        final url = hlsMatch.group(1);
        if (url != null && url.isNotEmpty) {
          debugPrint('✅ Found HLS URL');
          return url;
        }
      }

      // Try media.transcodings
      var transcodingMatch = RegExp(
        r'"media":\s*\{\s*"transcodings":\s*\[\s*\{\s*"url":\s*"([^"]+)"',
      ).firstMatch(html);

      if (transcodingMatch != null) {
        final url = transcodingMatch.group(1);
        if (url != null && url.isNotEmpty) {
          debugPrint('✅ Found transcoding URL');
          return url;
        }
      }

      // Try window.__data
      var dataMatch = RegExp(
        r'window\.__data\s*=\s*({.*?"url":\s*"([^"]+)"',
      ).firstMatch(html);

      if (dataMatch != null) {
        final url = dataMatch.group(2);
        if (url != null && url.isNotEmpty) {
          debugPrint('✅ Found window data URL');
          return url;
        }
      }

      debugPrint('⚠️ No audio URL found in HTML');
      return '';
    } catch (e) {
      debugPrint('❌ Extract Audio URL Error: $e');
      return '';
    }
  }

  // ==========================================
  // SOUNDCLOUD DOWNLOAD
  // ==========================================
  static Future<SoundCloudDownloadData> scDownload(String scUrl) async {
    try {
      debugPrint('📥 Downloading: $scUrl');
      final html = await _fetch(scUrl);

      // Extract title
      var titleMatch = RegExp(r'<meta\s+property="og:title"\s+content="([^"]+)"').firstMatch(html);
      final title = titleMatch?.group(1) ?? 'Unknown Track';

      // Extract image
      var imageMatch = RegExp(r'<meta\s+property="og:image"\s+content="([^"]+)"').firstMatch(html);
      final thumbnail = imageMatch?.group(1) ?? '';

      // Extract description
      var descMatch = RegExp(r'<meta\s+property="og:description"\s+content="([^"]+)"').firstMatch(html);
      final artist = descMatch?.group(1) ?? 'Unknown Artist';

      // Extract audio URL
      final audioUrl = _extractAudioUrl(html);

      if (audioUrl.isEmpty) {
        debugPrint('⚠️ Failed to extract audio URL');
      }

      return SoundCloudDownloadData(
        title: title,
        artist: artist,
        thumbnail: thumbnail,
        soundcloudUrl: scUrl,
        audioUrl: audioUrl,
      );
    } catch (e) {
      debugPrint('❌ Download Error: $e');
      rethrow;
    }
  }

  // ==========================================
  // GET DIRECT DOWNLOAD LINK
  // ==========================================
  static Future<String> getDirectDownloadUrl(String scUrl) async {
    try {
      debugPrint('🎵 Getting direct URL for: $scUrl');
      final data = await scDownload(scUrl);

      if (data.audioUrl.isEmpty) {
        debugPrint('❌ No audio URL found');
        throw Exception('Failed to extract audio URL from SoundCloud');
      }

      debugPrint('✅ Got direct URL: ${data.audioUrl.substring(0, 80)}...');
      return data.audioUrl;
    } catch (e) {
      debugPrint('❌ Get Direct Download URL Error: $e');
      rethrow;
    }
  }
}

// ==========================================
// DATA MODELS
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
  String toString() => 'SoundCloudArtist(name: $name, followers: $followers)';
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
