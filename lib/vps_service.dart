import 'dart:convert';
import 'package:http/http.dart' as http;
import 'btrapps/.dart';

final baseUrl = Api.api;

class VpsNode {
  final String id;
  final String name;
  final String host;
  final int port;

  VpsNode({required this.id, required this.name, required this.host, required this.port});

  factory VpsNode.fromJson(Map<String, dynamic> json) {
    return VpsNode(
      id: json['id'],
      name: json['name'],
      host: json['host'],
      port: json['port'] is int ? json['port'] : int.parse(json['port'].toString()),
    );
  }

  String get fullUrl => "$host:$port";
}

class VpsService {
  final String mainServerUrl; // Host utama tempat simpan list VPS

  VpsService({this.mainServerUrl = '$baseUrl'});

  // Ambil daftar VPS (/air/vps/list)
  Future<List<VpsNode>> fetchVpsList() async {
    try {
      final res = await http.get(Uri.parse('$mainServerUrl/air/vps/list'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List list = data['data'] ?? [];
        return list.map((e) => VpsNode.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // Tambah VPS - Khusus Role Developer (/air/vps/add)
  Future<bool> addVps(String role, String name, String host, int port) async {
    try {
      final res = await http.post(
        Uri.parse('$mainServerUrl/air/vps/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role, 'name': name, 'host': host, 'port': port}),
      );
      return jsonDecode(res.body)['success'] ?? false;
    } catch (_) {
      return false;
    }
  }

  // Hapus VPS - Khusus Role Developer (/air/vps/delete/:id)
  Future<bool> deleteVps(String role, String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$mainServerUrl/air/vps/delete/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role}),
      );
      return jsonDecode(res.body)['success'] ?? false;
    } catch (_) {
      return false;
    }
  }
}
