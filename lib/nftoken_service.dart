import 'dart:async';

// --- CUSTOM EXCEPTIONS ---
class NfTokenException implements Exception {
  final String message;
  NfTokenException([this.message = 'Terjadi kesalahan pada layanan NF Token.']);

  @override
  String toString() => message;
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException([this.message = 'Terlalu banyak permintaan (Rate Limit). Coba lagi nanti.']);

  @override
  String toString() => message;
}

// --- RESULT MODEL ---
class NfTokenResult {
  final String? token;
  final bool isSuccess;
  final String? message;
  final Map<String, dynamic>? data;

  NfTokenResult({
    this.token,
    required this.isSuccess,
    this.message,
    this.data,
  });

  factory NfTokenResult.fromJson(Map<String, dynamic> json) {
    return NfTokenResult(
      token: json['token'] as String?,
      isSuccess: json['success'] ?? true,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

// --- SERVICE CLASS ---
class NfTokenService {
  final String baseUrl;

  NfTokenService({this.baseUrl = ''});

  /// Fungsi untuk memproses / mengambil token
  Future<NfTokenResult> fetchToken(String identifier) async {
    try {
      if (identifier.isEmpty) {
        throw NfTokenException('Identifier tidak boleh kosong');
      }

      // Simulasi panggilan API (ganti dengan logika HTTP request/backend kamu)
      await Future.delayed(const Duration(seconds: 1));

      return NfTokenResult(
        token: 'NFT_${DateTime.now().millisecondsSinceEpoch}',
        isSuccess: true,
        message: 'Token berhasil diproses',
        data: {'id': identifier, 'timestamp': DateTime.now().toIso8601String()},
      );
    } on RateLimitException {
      rethrow;
    } on NfTokenException {
      rethrow;
    } catch (e) {
      throw NfTokenException('Gagal mengambil token: $e');
    }
  }
}
