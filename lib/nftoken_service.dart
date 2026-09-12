import 'dart:async';

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
    this.country = 'ID',
    this.plan = 'Premium',
  });
}

// Sub-model Links
class NfTokenLinks {
  final String pc;
  final String tv;

  NfTokenLinks({
    this.pc = '',
    this.tv = '',
  });
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

  String formatForCopy() {
    return "Token: $token\nCountry: ${profile.country}\nPlan: ${profile.plan}\nExpired: $expiry\nPC: ${links.pc}\nTV: ${links.tv}";
  }
}

// Service Utama
class NfTokenService {
  int remainingQuota = 10;
  int maxDailyLimit = 10;

  Future<NfTokenResult> generate() async {
    await Future.delayed(const Duration(seconds: 1));

    if (remainingQuota <= 0) {
      throw RateLimitException(
        message: 'Batas kuota harian telah habis.',
        formattedTimeLeft: '12:00:00',
      );
    }

    remainingQuota--;

    return NfTokenResult(
      token: 'NF_${DateTime.now().millisecondsSinceEpoch}',
      isSuccess: true,
      message: 'Token berhasil dibuat',
      expiry: '30 Hari',
      profile: NfTokenProfile(country: 'Indonesia', plan: 'Ultra HD 4K'),
      links: NfTokenLinks(
        pc: 'https://netflix.com/activate?code=PC-12345',
        tv: 'https://netflix.com/activate?code=TV-67890',
      ),
    );
  }
}
