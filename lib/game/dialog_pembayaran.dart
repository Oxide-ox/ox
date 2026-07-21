import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'game_provider.dart';

void tampilkanDialogPembayaran(BuildContext context, int harga, Function(String) onPilih) {
  var state = Provider.of<GameProvider>(context, listen: false).state;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Pilih Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text("Total Tagihan: Rp $harga\n\nSilakan pilih metode:"),
      actions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
          icon: const Icon(Icons.money),
          label: Text("Tunai\n(Sisa: Rp ${state.uangTunai})", textAlign: TextAlign.center),
          onPressed: () {
            Navigator.pop(context);
            onPilih('Tunai');
          },
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
          icon: const Icon(Icons.qr_code_2),
          label: Text("QRIS\n(Sisa: Rp ${state.saldoQRIS})", textAlign: TextAlign.center),
          onPressed: () {
            Navigator.pop(context);
            onPilih('QRIS');
          },
        ),
      ],
    )
  );
}
