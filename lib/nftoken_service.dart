import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Exception khusus rate limit
class RateLimitException implements Exception {
  final String message;
  final String formattedTimeLeft;

  RateLimitException({
    this.message = 'Terlalu banyak permintaan (Rate Limit).',
    this.formattedTimeLeft = '00:00:00',
  });

  @override
  String toString() => message;
}

// Exception umum NF Token
class NfTokenException implements Exception {
  final String message;
  NfTokenException([this.message = 'Terjadi kesalahan pada layanan NF Token.']);

  @override
  String toString() => message;
}

// Sub-model Profile
class NfTokenProfile {
  final String country;
  final String plan;

  NfTokenProfile({
    this.country = 'Unknown',
    this.plan = 'Unknown',
  });

  factory NfTokenProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NfTokenProfile();
    return NfTokenProfile(
      country: json['country']?.toString() ?? 'Unknown',
      plan: json['plan']?.toString() ?? 'Unknown',
    );
  }
}

// Sub-model Links (3 Tipe: PC, TV, Android)
class NfTokenLinks {
  final String pc;
  final String tv;
  final String android;

  NfTokenLinks({
    this.pc = '',
    this.tv = '',
    this.android = '',
  });

  factory NfTokenLinks.fromJson(Map<String, dynamic>? json) {
    if (json == null) return NfTokenLinks();
    return NfTokenLinks(
      pc: json['pc']?.toString() ?? json['web']?.toString() ?? '',
      tv: json['tv']?.toString() ?? '',
      android: json['android']?.toString() ??
          json['mobile']?.toString() ??
          json['app']?.toString() ??
          '',
    );
  }
}

// Model Hasil Token
class NfTokenResult {
  final String? token;
  final bool isSuccess;
  final String? message;
  final NfTokenProfile profile;
  final String expiry;
  final NfTokenLinks links;

  NfTokenResult({
    this.token,
    required this.isSuccess,
    this.message,
    NfTokenProfile? profile,
    this.expiry = '-',
    NfTokenLinks? links,
  })  : profile = profile ?? NfTokenProfile(),
        links = links ?? NfTokenLinks();

  factory NfTokenResult.fromJson(Map<String, dynamic> json) {
    return NfTokenResult(
      token: json['token']?.toString(),
      isSuccess: json['success'] == true,
      message: json['message']?.toString() ??
          (json['success'] == true
              ? 'Token berhasil dibuat'
              : 'Gagal membuat token'),
      expiry: json['expiry']?.toString() ?? '-',
      profile: NfTokenProfile.fromJson(json['profile']),
      links: NfTokenLinks.fromJson(json['links']),
    );
  }

  String formatForCopy() {
    return "Token: $token\nCountry: ${profile.country}\nPlan: ${profile.plan}\nExpired: $expiry\nPC: ${links.pc}\nTV: ${links.tv}\nAndroid: ${links.android}";
  }
}

// Service Utama
class NfTokenService {
  static const String _apiUrl = 'https://nftoken.zone.id/api/auto-generate';

  int remainingQuota = 10;
  int maxDailyLimit = 10;

  Future<NfTokenResult> generate() async {
    if (remainingQuota <= 0) {
      throw RateLimitException(
        message: 'Batas kuota harian telah habis.',
        formattedTimeLeft: '12:00:00',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 429) {
        throw RateLimitException(
          message: 'Terlalu banyak permintaan ke server API.',
          formattedTimeLeft: '00:05:00',
        );
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          remainingQuota--;
          return NfTokenResult.fromJson(data);
        } else {
          throw NfTokenException(
              data['message']?.toString() ?? 'API mengembalikan status gagal.');
        }
      } else {
        throw NfTokenException(
            'Gagal terhubung ke API (HTTP ${response.statusCode})');
      }
    } on RateLimitException {
      rethrow;
    } on TimeoutException {
      throw NfTokenException('Koneksi ke server timeout (15 detik).');
    } catch (e) {
      throw NfTokenException('Terjadi kesalahan: ${e.toString()}');
    }
  }
}
