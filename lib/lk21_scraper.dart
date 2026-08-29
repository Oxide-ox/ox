import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class LK21Scraper {
  static const String baseUrl = 'https://tv12.lk21official.cc';
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  static Future<String> _fetch(String url, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': userAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
          'Referer': baseUrl,
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
  // SEARCH FILMS
  // ==========================================
  static Future<List<LK21Film>> searchFilms(String query) async {
    try {
      final searchUrl = '$baseUrl/?s=${Uri.encodeComponent(query)}';
      final html = await _fetch(searchUrl);

      final films = <LK21Film>[];

      // Pattern: <a href="..." class="lk-box-link">
      // Ekstrak link dan title dari grid hasil
      final linkPattern = RegExp(
        r'<a\s+href="([^"]+)"\s+class="lk-box-link"[^>]*>\s*<img[^>]*alt="([^"]*)"[^>]*src="([^"]*)"',
        dotAll: true,
      );

      final matches = linkPattern.allMatches(html);

      for (var match in matches) {
        try {
          final url = match.group(1) ?? '';
          final title = match.group(2) ?? 'Unknown';
          final poster = match.group(3) ?? '';

          if (url.isNotEmpty && title.isNotEmpty) {
            films.add(LK21Film(
              title: _cleanTitle(title),
              url: url,
              poster: poster,
              type: _detectType(title),
            ));
          }
        } catch (e) {
          debugPrint('Error parsing film: $e');
        }
      }

      return films;
    } catch (e) {
      debugPrint('LK21 Search Error: $e');
      rethrow;
    }
  }

  // ==========================================
  // GET FILM DETAILS & DOWNLOAD LINKS
  // ==========================================
  static Future<LK21FilmDetails> getFilmDetails(String filmUrl) async {
    try {
      final html = await _fetch(filmUrl);

      // Extract title
      final titleMatch = RegExp(r'<h1\s+class="lk-title"[^>]*>([^<]+)</h1>')
          .firstMatch(html);
      final title = titleMatch?.group(1) ?? 'Unknown';

      // Extract poster
      final posterMatch = RegExp(r'<img\s+class="lk-poster"[^>]*src="([^"]*)"')
          .firstMatch(html);
      final poster = posterMatch?.group(1) ?? '';

      // Extract synopsis
      final synopsisMatch = RegExp(
        r'<div\s+class="lk-synopsis"[^>]*>\s*<p>([^<]+)</p>',
      ).firstMatch(html);
      final synopsis = synopsisMatch?.group(1) ?? '';

      // Extract year
      final yearMatch = RegExp(r'<span[^>]*class="lk-year"[^>]*>(\d{4})</span>')
          .firstMatch(html);
      final year = yearMatch?.group(1) ?? 'Unknown';

      // Extract rating
      final ratingMatch = RegExp(r'<span[^>]*class="lk-rating"[^>]*>([0-9.]+)/10</span>')
          .firstMatch(html);
      final rating = ratingMatch?.group(1) ?? '0';

      // Extract quality options
      final qualities = _extractQualities(html);

      // Extract download links
      final downloadLinks = _extractDownloadLinks(html);

      return LK21FilmDetails(
        title: _cleanTitle(title),
        poster: poster,
        synopsis: synopsis,
        year: year,
        rating: double.tryParse(rating) ?? 0,
        qualities: qualities,
        downloadLinks: downloadLinks,
      );
    } catch (e) {
      debugPrint('LK21 Film Details Error: $e');
      rethrow;
    }
  }

  // ==========================================
  // EXTRACT QUALITIES
  // ==========================================
  static List<String> _extractQualities(String html) {
    final qualities = <String>[];

    // Pattern: 720p, 1080p, SD, HD, etc
    final qualityPattern = RegExp(r'(720p|1080p|480p|360p|SD|HD|FHD|4K)');
    final matches = qualityPattern.allMatches(html);

    for (var match in matches) {
      final quality = match.group(1) ?? '';
      if (!qualities.contains(quality)) {
        qualities.add(quality);
      }
    }

    return qualities.isNotEmpty ? qualities : ['HD'];
  }

  // ==========================================
  // EXTRACT DOWNLOAD LINKS
  // ==========================================
  static List<DownloadLink> _extractDownloadLinks(String html) {
    final links = <DownloadLink>[];

    // Pattern 1: Server links (Zippyshare, Uptobox, etc)
    final serverPattern = RegExp(
      r'<a[^>]*class="lk-download-link"[^>]*href="([^"]+)"[^>]*>\s*([^<]+)\s*</a>',
      dotAll: true,
    );

    final serverMatches = serverPattern.allMatches(html);
    for (var match in serverMatches) {
      try {
        final url = match.group(1) ?? '';
        final serverName = match.group(2) ?? 'Unknown';

        if (url.isNotEmpty) {
          links.add(DownloadLink(
            serverName: _cleanServerName(serverName),
            url: url,
            quality: _extractQualityFromText(serverName),
          ));
        }
      } catch (e) {
        debugPrint('Error parsing download link: $e');
      }
    }

    // Pattern 2: Stream links (Streaming servers)
    final streamPattern = RegExp(
      r'<button[^>]*class="lk-stream-btn"[^>]*data-url="([^"]*)"[^>]*>\s*([^<]+)\s*</button>',
      dotAll: true,
    );

    final streamMatches = streamPattern.allMatches(html);
    for (var match in streamMatches) {
      try {
        final url = match.group(1) ?? '';
        final serverName = match.group(2) ?? 'Unknown';

        if (url.isNotEmpty) {
          links.add(DownloadLink(
            serverName: _cleanServerName(serverName),
            url: url,
            quality: _extractQualityFromText(serverName),
            isStream: true,
          ));
        }
      } catch (e) {
        debugPrint('Error parsing stream link: $e');
      }
    }

    return links;
  }

  // ==========================================
  // HELPER FUNCTIONS
  // ==========================================

  static String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&#039;', "'")
        .trim();
  }

  static String _detectType(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('series') || lower.contains('episode')) {
      return 'Series';
    } else if (lower.contains('movie') || lower.contains('film')) {
      return 'Movie';
    }
    return 'Unknown';
  }

  static String _cleanServerName(String name) {
    return name
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _extractQualityFromText(String text) {
    final qualityRegex = RegExp(r'(720p|1080p|480p|360p|SD|HD|FHD|4K)');
    final match = qualityRegex.firstMatch(text);
    return match?.group(1) ?? 'HD';
  }

  // Get direct streaming/download URL
  static Future<String> getDirectUrl(String downloadUrl) async {
    try {
      final html = await _fetch(downloadUrl);

      // Try to extract actual download/stream URL
      // Different servers have different patterns

      if (downloadUrl.contains('zippyshare')) {
        return _extractZippyshareUrl(html);
      } else if (downloadUrl.contains('uptobox')) {
        return _extractUptoboxUrl(html);
      } else if (downloadUrl.contains('google')) {
        return _extractGoogleDriveUrl(html);
      } else {
        // Generic extraction - look for common patterns
        final urlMatch = RegExp(
          r'(https?://[^\s"<>]+\.(?:mp4|mkv|avi|webm|m3u8))',
        ).firstMatch(html);

        return urlMatch?.group(1) ?? downloadUrl;
      }
    } catch (e) {
      debugPrint('Get Direct URL Error: $e');
      return downloadUrl;
    }
  }

  static String _extractZippyshareUrl(String html) {
    // Zippyshare memerlukan parsing JS
    final match = RegExp(r'href="([^"]*download[^"]*)"').firstMatch(html);
    return match?.group(1) ?? '';
  }

  static String _extractUptoboxUrl(String html) {
    // Uptobox premium link
    final match = RegExp(r'data-url="([^"]+)"').firstMatch(html);
    return match?.group(1) ?? '';
  }

  static String _extractGoogleDriveUrl(String html) {
    // Google Drive extraction
    final match = RegExp(r'id=([a-zA-Z0-9-_]+)').firstMatch(html);
    if (match != null) {
      return 'https://drive.google.com/uc?id=${match.group(1)}&export=download';
    }
    return '';
  }
}

// ==========================================
// MODEL DATA STRUCTURES
// ==========================================

class LK21Film {
  final String title;
  final String url;
  final String poster;
  final String type; // Movie, Series, etc

  LK21Film({
    required this.title,
    required this.url,
    required this.poster,
    required this.type,
  });

  @override
  String toString() => 'LK21Film(title: $title, type: $type)';
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

  @override
  String toString() => '''LK21FilmDetails(
    title: $title,
    year: $year,
    rating: $rating,
    qualities: $qualities,
    downloadLinks: ${downloadLinks.length} links
  )''';
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

  @override
  String toString() => 'DownloadLink(server: $serverName, quality: $quality)';
}
