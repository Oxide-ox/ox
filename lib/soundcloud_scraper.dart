import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SoundCloudScraper {
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

  static const String fallbackClientId = 'iZIs9mchVUYP3fh3R0L5R9Rz3N1g5dK';
  static String _cachedClientId = fallbackClientId;

  static Future<String> _fetch(String url) async {
    try {
      debugPrint('🌐 Fetching');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': userAgent,
          'Accept': 'application/json, text/plain, */*',
          'Referer': 'https://soundcloud.com/',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return response.body;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Fetch error: $e');
      rethrow;
    }
  }

  static Future<List<SoundCloudTrack>> scSearch(String query) async {
    try {
      debugPrint('🔍 Searching: $query');
      final clientId = _cachedClientId;

      final apiUrl =
          'https://api-v2.soundcloud.com/search/tracks?q=${Uri.encodeComponent(query)}&client_id=$clientId&limit=30';

      final response = await _fetch(apiUrl);
      final parsed = jsonDecode(response) as Map<String, dynamic>;

      final tracks = <SoundCloudTrack>[];

      if (parsed['collection'] is List) {
        for (var t in parsed['collection']) {
          if (t is! Map<String, dynamic>) continue;

          try {
            final id = t['id'];
            final title = t['title'] ?? 'Unknown';
            final url = t['permalink_url'] ?? '';

            if (url.isEmpty) continue;

            String artwork = '';
            if (t['artwork_url'] != null) {
              artwork = t['artwork_url'].toString()
                  .replaceFirst('-large.jpg', '-t500x500.jpg');
            }

            final duration = Duration(milliseconds: t['duration'] ?? 0);

            final artist = SoundCloudArtist(
              name: t['user']?['username'] ?? 'Unknown',
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

            debugPrint('📌 $title');
          } catch (e) {
            debugPrint('⚠️ Parse: $e');
          }
        }
      }

      debugPrint('✅ Found ${tracks.length}');
      return tracks;
    } catch (e) {
      debugPrint('❌ Search: $e');
      return [];
    }
  }

  static String _extractAudioUrl(String html) {
    try {
      // Look for progressive stream URL
      if (html.contains('progressive')) {
        final idx = html.indexOf('progressive');
        final substr = html.substring(idx, idx + 300);
        final match = RegExp(r'"url":"([^"]+)"').firstMatch(substr);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }

      // Look for HLS URL
      if (html.contains('hls_mp3')) {
        final match = RegExp(r'"hls_mp3[^"]*":"([^"]+)"').firstMatch(html);
        if (match != null) {
          return match.group(1) ?? '';
        }
      }

      // Look for any m3u8 URL
      final m3u8Match = RegExp(r'(https://[^"]*\.m3u8[^"]*)')
          .firstMatch(html);
      if (m3u8Match != null) {
        return m3u8Match.group(1) ?? '';
      }

      return '';
    } catch (e) {
      debugPrint('❌ Extract: $e');
      return '';
    }
  }

  static Future<SoundCloudDownloadData> scDownload(String scUrl) async {
    try {
      debugPrint('📥 Download');
      final html = await _fetch(scUrl);

      // Extract title
      var titleMatch = RegExp(r'"title":"([^"]+)"').firstMatch(html);
      final title = titleMatch?.group(1) ?? 'Unknown';

      // Extract artist
      var artistMatch = RegExp(r'"username":"([^"]+)"').firstMatch(html);
      final artist = artistMatch?.group(1) ?? 'Unknown';

      // Extract image
      var imageMatch = RegExp(r'"avatar_url":"([^"]+)"').firstMatch(html);
      final thumbnail = imageMatch?.group(1) ?? '';

      // Extract audio URL
      final audioUrl = _extractAudioUrl(html);

      return SoundCloudDownloadData(
        title: title,
        artist: artist,
        thumbnail: thumbnail,
        soundcloudUrl: scUrl,
        audioUrl: audioUrl,
      );
    } catch (e) {
      debugPrint('❌ Download: $e');
      rethrow;
    }
  }

  static Future<String> getDirectDownloadUrl(String scUrl) async {
    try {
      debugPrint('🎵 Get URL');
      final data = await scDownload(scUrl);

      if (data.audioUrl.isEmpty) {
        throw Exception('No audio URL');
      }

      debugPrint('✅ Ready');
      return data.audioUrl;
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }
}

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
  String toString() => 'Track($title)';
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
  String toString() => 'Artist($name)';
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
}
