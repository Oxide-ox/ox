import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';
import 'dialog_pembayaran.dart';

class LaptopScreen extends StatelessWidget {
  const LaptopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<GameProvider>(context);
    var state = provider.state;

    return Scaffold(
      appBar: AppBar(title: const Text("Laptop Admin Warung"), backgroundColor: Colors.grey[900]),
      body: Row(
        children: [
          Container(
            width: 150, color: Colors.black26,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(padding: EdgeInsets.all(12), child: Text("MENU UTAMA", style: TextStyle(color: Colors.grey))),
                ListTile(leading: Icon(Icons.flash_on), title: Text("PLN/PDAM")),
                ListTile(leading: Icon(Icons.people), title: Text("Staf")),
                ListTile(leading: Icon(Icons.arrow_upward), title: Text("Upgrade")),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Manajemen Tagihan Air & Listrik", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Card(
                    color: state.kabelDipotong ? Colors.red[900] : Colors.blueGrey[800],
                    child: ListTile(
                      title: Text(state.kabelDipotong ? "⚠️ STATUS: KABEL DIPOTONG" : "💡 STATUS: Aman"),
                      subtitle: Text(state.kabelDipotong ? "Denda Jatuh Tempo: Rp 25.000" : "Sisa Waktu: ${state.sisaHariTagihan} Hari (Biaya: Rp 15.000)"),
                      trailing: ElevatedButton(
                        onPressed: () {
                          tampilkanDialogPembayaran(context, state.kabelDipotong ? 25000 : 15000, (metode) {
                            bool sukses = provider.bayarTagihan(metode);
                            if (!sukses) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saldo $metode tidak cukup!")));
                          });
                        }, 
                        child: const Text("Bayar")
                      ),
                    ),
                  ),
                  const Divider(),
                  const Text("Upgrade Level Warung", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ListTile(
                    title: Text("Warung Saat Ini: Level ${state.levelWarung}"),
                    subtitle: Text(state.levelWarung == 1 ? "Butuh 100 EXP untuk membuka Karyawan (Lv.2)" : "Level Maksimal Saat Ini"),
                    trailing: ElevatedButton(onPressed: (state.levelWarung == 1 && state.expWarung >= 100) ? () => provider.upgradeWarung() : null, child: const Text("Upgrade")),
                  ),
                  const Divider(),
                  const Text("Upgrade Karyawan (Terbuka Lv. 2)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: state.levelWarung < 2 
                    ? const Center(child: Text("🔒 Naikkan Warung ke Level 2 untuk Membuka Karyawan", style: TextStyle(color: Colors.grey)))
                    : ListView(
                        children: state.listKaryawan.values.map((k) {
                          return ListTile(
                            title: Text("${k.posisi} (Level ${k.level}/3)"),
                            subtitle: Text("Efisiensi: +${(k.bonusKecepatan * 100).toInt()}%"),
                            trailing: ElevatedButton(
                              onPressed: k.level >= 3 ? null : () {
                                tampilkanDialogPembayaran(context, 250000, (metode) {
                                  bool sukses = provider.upgradeKaryawan(k.posisi, metode);
                                  if (!sukses) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saldo $metode tidak cukup!")));
                                });
                              },
                              child: Text(k.level >= 3 ? "MAX" : "Upgrade (Rp 250k)"),
                            ),
                          );
                        }).toList(),
                      ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
