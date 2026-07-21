import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';
import 'handphone_screen.dart';
import 'laptop_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  double playerX = 180.0;
  double playerY = 250.0;
  final double speed = 12.0;

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<GameProvider>(context);
    if (provider.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    var state = provider.state;
    String jamKembar = provider.jam.toString().padLeft(2, '0');
    String menitKembar = provider.menit.toString().padLeft(2, '0');

    return Scaffold(
      body: Stack(
        children: [
          // MAP ARENA
          Container(
            width: double.infinity, height: double.infinity,
            color: state.kabelDipotong ? Colors.black45 : Colors.blueGrey[900],
            child: Stack(
              children: [
                Positioned(
                  top: 100, left: 100,
                  child: Container(
                    width: 150, height: 130,
                    decoration: BoxDecoration(color: state.kabelDipotong ? Colors.grey[800] : Colors.amber[800], borderRadius: BorderRadius.circular(8)),
                    child: Center(
                      child: Text(
                        provider.isWarungBuka ? "🍜 Warung Buka" : "💤 Warung Tutup", 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      )
                    ),
                  ),
                ),
                Positioned(
                  top: 140, left: 340,
                  child: GestureDetector(
                    onTap: () => _interaksiNPC(context, provider),
                    child: Column(
                      children: [
                        Icon(Icons.person, size: 45, color: state.kabelDipotong ? Colors.red : Colors.cyan),
                        Text(state.kabelDipotong ? "Petugas PLN" : "Cak Malik (NPC)", style: const TextStyle(fontSize: 11, backgroundColor: Colors.black45)),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: playerY, left: playerX,
                  child: Container(
                    width: 35, height: 35,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.directions_walk, size: 20, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),

          // VIRTUAL D-PAD CONTROLLER
          Positioned(
            bottom: 20, left: 20,
            child: Container(
              width: 130, height: 130,
              decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
              child: Stack(
                children: [
                  Align(alignment: Alignment.topCenter, child: IconButton(icon: const Icon(Icons.arrow_drop_up, size: 32), onPressed: () => setState(() => playerY -= speed))),
                  Align(alignment: Alignment.bottomCenter, child: IconButton(icon: const Icon(Icons.arrow_drop_down, size: 32), onPressed: () => setState(() => playerY += speed))),
                  Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_left, size: 32), onPressed: () => setState(() => playerX -= speed))),
                  Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.arrow_right, size: 32), onPressed: () => setState(() => playerX += speed))),
                ],
              ),
            ),
          ),

          // HUD PANEL UTAMA
          Positioned(
            top: 15, left: 15, right: 15,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("💵 Tunai: Rp ${state.uangTunai}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                      Text("📱 QRIS: Rp ${state.saldoQRIS}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                      Text("🍲 Stok: ${state.stokBakso} Porsi | 🏷️ Harga: Rp ${provider.hargaBaksoSekarang}"),
                      Text("📈 EXP: ${state.expWarung}/100 (Lv.${state.levelWarung})"),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("📅 Hari ke-${state.hariGame} | ⏰ $jamKembar:$menitKembar", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
                      Text(state.kabelDipotong ? "⚡ MATI LAMPU" : "🔌 Sisa Listrik: ${state.sisaHariTagihan} Hari", style: TextStyle(color: state.kabelDipotong ? Colors.red : Colors.white)),
                      const SizedBox(height: 4),
                      if (!provider.isWarungBuka)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Pengganti agar tombol tetap compact/padat
                        ),
                         onPressed: () => provider.bukaWarungMulaiHari(),
                         child: const Text("Buka Warung (06:00)"),
                       )

                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green[900], borderRadius: BorderRadius.circular(4)),
                          child: const Text("Warung Operasional", style: TextStyle(fontSize: 11)),
                        )
                    ],
                  ),
                )
              ],
            ),
          ),

          // GADGET BUTTONS
          Positioned(
            bottom: 30, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: "pelanggan_btn", 
                  label: const Text("Layani Pelanggan"), 
                  icon: const Icon(Icons.hail), 
                  backgroundColor: provider.isWarungBuka ? Colors.purple : Colors.grey,
                  onPressed: () {
                    String hasil = provider.layaniPelanggan();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hasil), duration: const Duration(milliseconds: 1500)));
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: "hp_btn", label: const Text("Buka HP"), icon: const Icon(Icons.phone_android), backgroundColor: Colors.blue[800],
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HandphoneScreen())),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton.extended(
                      heroTag: "laptop_btn", label: const Text("Laptop"), icon: const Icon(Icons.laptop), backgroundColor: Colors.grey[850],
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaptopScreen())),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _interaksiNPC(BuildContext context, GameProvider provider) {
    if (provider.state.kabelDipotong) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Petugas PLN: 'Kabel tak potong sam, ndang bayaren tagihanmu nang laptop!'")));
    } else {
      if (provider.state.listQuest[0].progresSaatIni < provider.state.listQuest[0].targetJumlah) {
        provider.state.listQuest[0].progresSaatIni += 2;
        provider.saveGameOffline();
        provider.paksaUpdate();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cak Malik: 'Bakso kene pancen oyi sam! Kapan-kapan tak mampir maneh.' (Quest Selesai!)")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cak Malik: 'Yo opo kabare, Sam? Ndang dilariske bakso Malange!'")));
      }
    }
  }
}
