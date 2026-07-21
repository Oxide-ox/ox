import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';
import 'dialog_pembayaran.dart';

class HandphoneScreen extends StatelessWidget {
  const HandphoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<GameProvider>(context);
    var state = provider.state;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Prikitiww Smart-OS Mobile"),
          backgroundColor: Colors.blue[800],
          bottom: const TabBar(tabs: [Tab(text: "Bakol Online"), Tab(text: "Quest App")]),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBelanjaItem(context, provider, "Bahan Bakso Halus (x10)", 45000, "Bakso", 10),
                _buildBelanjaItem(context, provider, "Set Meja Kursi Kayu", 120000, "MejaKursi", 1),
                _buildBelanjaItem(context, provider, "Spanduk Bakso Malang", 60000, "Aksesoris", 1),
              ],
            ),
            ListView.builder(
              itemCount: state.listQuest.length,
              itemBuilder: (context, index) {
                var q = state.listQuest[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(q.judul, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${q.deskripsi}\nProgres: (${q.progresSaatIni}/${q.targetJumlah})"),
                    trailing: ElevatedButton(
                      onPressed: q.isComplete && !q.isClaimed ? () => provider.claimQuestReward(q.id) : null,
                      child: Text(q.isClaimed ? "Selesai" : "Klaim"),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBelanjaItem(BuildContext context, GameProvider p, String nama, int harga, String jenis, int qty) {
    return Card(
      child: ListTile(
        title: Text(nama),
        subtitle: Text("Rp $harga"),
        trailing: ElevatedButton(
          onPressed: () {
            tampilkanDialogPembayaran(context, harga, (metode) {
              bool sukses = p.beliBarang(jenis, harga, qty, metode);
              if (!sukses) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saldo $metode tidak cukup!")));
            });
          },
          child: const Text("Beli"),
        ),
      ),
    );
  }
}
