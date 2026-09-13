import 'package:flutter/material.dart';
import 'vps_service.dart';
import 'btrapps/.dart';

final baseUrl = Api.api;

class VpsManagePage extends StatefulWidget {
  final String username;
  final String role;
  final String sessionKey;

  const VpsManagePage({
    super.key,
    required this.username,
    required this.role,
    required this.sessionKey,
  });

  @override
  State<VpsManagePage> createState() => _VpsManagePageState();
}

class _VpsManagePageState extends State<VpsManagePage> {
  late VpsService _vpsService;
  List<VpsNode> _vpsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _vpsService = VpsService();
    _loadVps();
  }

  Future<void> _loadVps() async {
    setState(() => _isLoading = true);
    final list = await _vpsService.fetchVpsList();
    setState(() {
      _vpsList = list;
      _isLoading = false;
    });
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final hostCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '3000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F2C),
        title: const Text('Tambah Server VPS', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nama Server (ex: SG-Node1)',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: hostCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Host / IP (ex: http://103.x.x.x)',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
            TextField(
              controller: portCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Port API',
                labelStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && hostCtrl.text.isNotEmpty) {
                await _vpsService.addVps(
                  widget.role,
                  nameCtrl.text,
                  hostCtrl.text,
                  int.parse(portCtrl.text),
                );
                Navigator.pop(ctx);
                _loadVps();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDev = widget.role == 'developer';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        title: const Text('Manajemen List VPS'),
        backgroundColor: const Color(0xFF16161E),
      ),
      floatingActionButton: isDev
          ? FloatingActionButton.extended(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add),
              label: const Text('Tambah VPS'),
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _vpsList.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (ctx, i) {
                final vps = _vpsList[i];
                return Card(
                  color: const Color(0xFF1A1A24),
                  child: ListTile(
                    leading: const Icon(Icons.dns, color: Colors.cyanAccent),
                    title: Text(
                      vps.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      vps.fullUrl,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: isDev
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              await _vpsService.deleteVps(widget.role, vps.id);
                              _loadVps();
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
