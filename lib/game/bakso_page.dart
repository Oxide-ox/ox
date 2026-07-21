import 'dart:async';
import 'package:flutter/material.dart';

import '../services/game_service.dart';
import '../services/customer_service.dart';
import '../services/achievement_service.dart';
import '../services/redeem_service.dart';
import '../models/employee_model.dart';

class BaksoPage extends StatefulWidget {
  final String sessionKey;
  
  const BaksoPage({
  super.key,
  required this.sessionKey,
  });

  @override
  State<BaksoPage> createState() => _BaksoPageState();
}

class _BaksoPageState extends State<BaksoPage> {
   
   
  int uang = 0;
  int bahan = 10;
  int pelanggan = 0;

  int mejaLevel = 1;
  int komporLevel = 1;
  int bannerLevel = 1;

  int employeeLevel = 0;
  
  void beliBahan() {

  if (uang < 50) return;

  setState(() {
    uang -= 50;
    bahan += 10;
  });

  saveGame();
}

void jualBakso() {

  if (bahan <= 0) return;

  setState(() {

    bahan--;

    uang +=
        20 +
        (komporLevel * 5);

    pelanggan++;
  });

  saveGame();
}

void upgradeMeja() {

  int harga = mejaLevel * 200;

  if (uang < harga) return;

  setState(() {
    uang -= harga;
    mejaLevel++;
  });

  saveGame();
}

void upgradeKompor() {

  int harga = komporLevel * 300;

  if (uang < harga) return;

  setState(() {
    uang -= harga;
    komporLevel++;
  });

  saveGame();
}

void upgradeBanner() {

  int harga = bannerLevel * 500;

  if (uang < harga) return;

  setState(() {
    uang -= harga;
    bannerLevel++;
  });

  saveGame();
}

void hireEmployee() {

  if (employeeLevel >=
      employees.length) {
    return;
  }

  final emp =
      employees[employeeLevel];

  if (uang < emp.salary) {
    return;
  }

  setState(() {
    uang -= emp.salary;
    employeeLevel++;
  });

  saveGame();
}
  List<String> achievements = [];

  final redeemController =
      TextEditingController();

  Timer? incomeTimer;

  @override
  void initState() {
    super.initState();
    loadData();
    startIdleIncome();
  }

  Future<void> loadData() async {
  await GameService.instance.loadGame();

  final game = GameService.instance;

  setState(() {
    uang = game.uang;
    pelanggan = game.pelanggan;

    mejaLevel = game.mejaLevel;
    komporLevel = game.komporLevel;
    bannerLevel = game.bannerLevel;

    employeeLevel = game.karyawan;

    bahan =
        game.daging +
        game.mie +
        game.bumbu;
  });

  achievements =
      await AchievementService.getUnlocked();
}

  Future<void> saveGame() async {
    await GameService.instance.saveGame();
  }

  void startIdleIncome() {
    incomeTimer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {

        setState(() {

          int income =
              pelanggan *
              (1 + employeeLevel);

          uang += income;

          pelanggan +=
              bannerLevel;

        });

        saveGame();
      },
    );
  }
  
  Future<void> useRedeem() async {
  final result = await RedeemService.redeem(
    sessionKey: widget.sessionKey,
    code: redeemController.text.trim(),
  );

  if (!mounted) return;

  if (result["success"] == true) {
    setState(() {
      uang += (result["reward"] ?? 0) as int;
    });

    await saveGame();
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result["message"]),
    ),
  );

  redeemController.clear();
}

  @override
  void dispose() {
    incomeTimer?.cancel();
    redeemController.dispose();
    super.dispose();
  }
  
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        "🍜 Bakso Simulator",
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          Card(
            child: ListTile(
              title: Text("💰 Uang"),
              subtitle: Text("Rp $uang"),
            ),
          ),

          Card(
            child: ListTile(
              title: Text("🥩 Bahan"),
              subtitle: Text("$bahan"),
            ),
          ),

          Card(
            child: ListTile(
              title: Text("👥 Pelanggan"),
              subtitle: Text("$pelanggan"),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: beliBahan,
            child: const Text(
              "Beli Bahan (+10)"
            ),
          ),

          ElevatedButton(
            onPressed: jualBakso,
            child: const Text(
              "Jual Bakso"
            ),
          ),

          ElevatedButton(
            onPressed: upgradeMeja,
            child: Text(
              "Upgrade Meja Lv.$mejaLevel"
            ),
          ),

          ElevatedButton(
            onPressed: upgradeKompor,
            child: Text(
              "Upgrade Kompor Lv.$komporLevel"
            ),
          ),

          ElevatedButton(
            onPressed: upgradeBanner,
            child: Text(
              "Upgrade Banner Lv.$bannerLevel"
            ),
          ),

          ElevatedButton(
            onPressed: hireEmployee,
            child: Text(
              "Hire Karyawan ($employeeLevel)"
            ),
          ),

          const Divider(),

          TextField(
  controller: redeemController,
  decoration: const InputDecoration(
    labelText: "Kode Redeem",
  ),
),

const SizedBox(height: 10),

ElevatedButton(
  onPressed: useRedeem,
  child: const Text("Redeem"),
),

          const SizedBox(height: 20),

          const Text(
            "🏆 Achievement",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          ...achievements.map(
            (e) => ListTile(
              leading: const Icon(
                Icons.emoji_events,
              ),
              title: Text(e),
            ),
          ),
        ],
      ),
    ),
  );
}
  }