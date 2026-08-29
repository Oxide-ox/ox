import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class LK21Scraper {
  static const String baseUrl = 'https://tv12.lk21official.cc';
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';

  static Future<String> _fetch(String url, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': userAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'id-ID,id;q=0.9',
          'Referer': baseUrl,
          if (headers != null) ...headers,
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return response.body;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Fetch error: $e');
    }
  }

  static Future<List<LK21Film>> searchFilms(String query) async {
    try {
      final searchUrl = '$baseUrl/?s=${Uri.encodeComponent(query)}';
      debugPrint('🔍 Searching: $searchUrl');
      final html = await _fetch(searchUrl);

      final films = <LK21Film>[];

      // Pattern 1: Generic link with img
      final patterns = [
        RegExp(
          r'<a[^>]*href="([^"]*?/(?:film|streaming)/[^/"]+/?)"\s*[^>]*>\s*(?:<img[^>]*src="([^"]*)"[^>]*alt="([^"]*)")?',
          multiLine: true,
        ),
        // Pattern 2: Alternative structure
        RegExp(
          r'<article[^>]*>.*?<a[^>]*href="([^"]+)"[^>]*>.*?<img[^>]*src="([^"]*)"[^>]*alt="([^"]*)"',
          dotAll: true,
        ),
        // Pattern 3: Flexible pattern
        RegExp(
          r'<a[^>]*href="([^"]+)"[^>]*title="([^"]*)"[^>]*>.*?<img[^>]*src="([^"]*)"',
          multiLine: true,
        ),
      ];

      for (var pattern in patterns) {
        final matches = pattern.allMatches(html);
        for (var match in matches) {
          try {
            final url = match.group(1)?.trim() ?? '';
            final poster = match.group(2)?.trim() ?? '';
            final title = match.group(3)?.trim() ?? 'Unknown';

            if (url.isNotEmpty && url.contains('/')) {
              final fullUrl = url.startsWith('http') ? url : '$baseUrl$url';
              if (!fullUrl.contains('/page/') && !fullUrl.contains('/feed/')) {
                final film = LK21Film(
                  title: _cleanTitle(title),
                  url: fullUrl,
                  poster: poster,
                  type: 'Movie',
                );
                
                if (!films.any((f) => f.url == film.url)) {
                  films.add(film);
                }
              }
            }
          } catch (e) {
            debugPrint('Parse error: $e');
          }
        }

        if (films.isNotEmpty) break; // Gunakan pattern pertama yang berhasil
      }

      debugPrint('✅ Found ${films.length} films');
      return films;
    } catch (e) {
      debugPrint('❌ Search Error: $e');
      return [];
    }
  }

  static Future<LK21FilmDetails> getFilmDetails(String filmUrl) async {
    try {
      final html = await _fetch(filmUrl);

      // Flexible title extraction
      final titlePatterns = [
        RegExp(r'<h1[^>]*>([^<]+)</h1>'),
        RegExp(r'<meta\s+property="og:title"\s+content="([^"]+)"'),
        RegExp(r'<title>([^<]+)</title>'),
      ];

      String title = 'Unknown';
      for (var pattern in titlePatterns) {
        final match = pattern.firstMatch(html);
        if (match != null) {
          title = match.group(1) ?? 'Unknown';
          break;
        }
      }

      // Poster extraction
      final posterPatterns = [
        RegExp(r'<img[^>]*class="[^"]*poster[^"]*"[^>]*src="([^"]+)"'),
        RegExp(r'<meta\s+property="og:image"\s+content="([^"]+)"'),
        RegExp(r'<img[^>]*src="([^"]*(?:jpg|jpeg|png))"'),
      ];

      String poster = '';
      for (var pattern in posterPatterns) {
        final match = pattern.firstMatch(html);
        if (match != null) {
          poster = match.group(1) ?? '';
          if (poster.isNotEmpty) break;
        }
      }

      // Quality extraction
      final qualityMatches =
          RegExp(r'(720p|1080p|480p|360p|SD|HD|FHD|4K)').allMatches(html);
      final qualities = qualityMatches
          .map((m) => m.group(1)!)
          .toSet()
          .toList();

      // Download links extraction
      final downloadLinks = _extractDownloadLinks(html);

      return LK21FilmDetails(
        title: _cleanTitle(title),
        poster: poster,
        synopsis: 'Sinopsis tidak tersedia',
        year: 'Unknown',
        rating: 0,
        qualities: qualities.isNotEmpty ? qualities : ['HD'],
        downloadLinks: downloadLinks,
      );
    } catch (e) {
      debugPrint('❌ Film Details Error: $e');
      rethrow;
    }
  }

  static List<DownloadLink> _extractDownloadLinks(String html) {
    final links = <DownloadLink>[];

    // Look for any link containing "streaming", "download", "server", "play"
    final patterns = [
      RegExp(
        r'<a[^>]*(?:href|data-url)="([^"]+)"[^>]*class="[^"]*(?:streaming|download|server|player)[^"]*"[^>]*>([^<]+)</a>',
        multiLine: true,
      ),
      RegExp(
        r'<button[^>]*data-url="([^"]+)"[^>]*>([^<]+)</button>',
        multiLine: true,
      ),
      RegExp(
        r'<a[^>]*href="([^"]*(?:zippyshare|uptobox|google|drive)[^"]*)"[^>]*>([^<]+)</a>',
        multiLine: true,
      ),
    ];

    for (var pattern in patterns) {
      final matches = pattern.allMatches(html);
      for (var match in matches) {
        try {
          final url = match.group(1)?.trim() ?? '';
          final serverName = match.group(2)?.trim() ?? 'Server';

          if (url.isNotEmpty) {
            links.add(DownloadLink(
              serverName: _cleanServerName(serverName),
              url: url,
              quality: 'HD',
              isStream: false,
            ));
          }
        } catch (e) {
          debugPrint('Link parse error: $e');
        }
      }
    }

    return links;
  }

  static Future<String> getDirectUrl(String downloadUrl) async {
    try {
      if (downloadUrl.contains('google') || downloadUrl.contains('drive')) {
        return downloadUrl;
      }
      if (downloadUrl.contains('.mp4') || downloadUrl.contains('.m3u8')) {
        return downloadUrl;
      }
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Get Direct URL Error: $e');
      return downloadUrl;
    }
  }

  static String _cleanTitle(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .trim();
  }

  static String _cleanServerName(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

// ==========================================
// MODELS
// ==========================================

class LK21Film {
  final String title;
  final String url;
  final String poster;
  final String type;

  LK21Film({
    required this.title,
    required this.url,
    required this.poster,
    required this.type,
  });

  @override
  String toString() => 'LK21Film(title: $title, url: $url)';
}

class LK21FilmDetails {
  final String title;
  final String poster;
  final String synopsis;
  final String year;
  final double rating;
  final List<String> qualities;
  final List<DownloadLink> downloadLinks;

  LK21FilmDetails({
    required this.title,
    required this.poster,
    required this.synopsis,
    required this.year,
    required this.rating,
    required this.qualities,
    required this.downloadLinks,
  });
}

class DownloadLink {
  final String serverName;
  final String url;
  final String quality;
  final bool isStream;

  DownloadLink({
    required this.serverName,
    required this.url,
    required this.quality,
    this.isStream = false,
  });
}
