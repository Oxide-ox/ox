import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'models.dart';

class GameProvider extends ChangeNotifier {
  late GameState state;
  bool isLoading = true;

  // Waktu Operasional Game
  int jam = 6;
  int menit = 0;
  bool isWarungBuka = false;

  GameProvider() {
    state = GameState(listKaryawan: {}, listQuest: []);
    loadGameOffline();
  }

  Future<void> loadGameOffline() async {
    final prefs = await SharedPreferences.getInstance();
    final String? gameDataRaw = prefs.getString('bakso_save_data_v3');

    if (gameDataRaw != null) {
      Map<String, dynamic> json = jsonDecode(gameDataRaw);
      state.uangTunai = json['uangTunai'] ?? 200000;
      state.saldoQRIS = json['saldoQRIS'] ?? 300000;
      state.levelWarung = json['levelWarung'] ?? 1;
      state.expWarung = json['expWarung'] ?? 0;
      state.hariGame = json['hariGame'] ?? 1;
      state.sisaHariTagihan = json['sisaHariTagihan'] ?? 7;
      state.kabelDipotong = json['kabelDipotong'] ?? false;
      state.ratingWarung = json['ratingWarung'] ?? 4.0;
      state.stokBakso = json['stokBakso'] ?? 50;
      state.jumlahMejaKursi = json['jumlahMejaKursi'] ?? 2;
      state.jumlahAksesoris = json['jumlahAksesoris'] ?? 0;
      
      state.listKaryawan = {
        'Masak': Karyawan(posisi: 'Tukang Masak', level: json['masak_lv'] ?? 1, isUnlocked: json['masak_un'] ?? false),
        'Kasir': Karyawan(posisi: 'Kasir', level: json['kasir_lv'] ?? 1, isUnlocked: json['kasir_un'] ?? false),
        'Waiters': Karyawan(posisi: 'Waiters', level: json['waiters_lv'] ?? 1, isUnlocked: json['waiters_un'] ?? false),
      };
    } else {
      _inisialisasiDataBaru();
    }

    state.listQuest = [
      Quest(id: 'q1', judul: 'Kuliner Malang', deskripsi: 'Ngobrol dengan Cak Malik', targetJumlah: 2, rewardExp: 40),
      Quest(id: 'q2', judul: 'Juragan Bakso', deskripsi: 'Beli Perlengkapan Warung', targetJumlah: 5, rewardExp: 60),
    ];

    isLoading = false;
    notifyListeners();
  }

  Future<void> saveGameOffline() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> saveData = {
      'uangTunai': state.uangTunai,
      'saldoQRIS': state.saldoQRIS,
      'levelWarung': state.levelWarung,
      'expWarung': state.expWarung,
      'hariGame': state.hariGame,
      'sisaHariTagihan': state.sisaHariTagihan,
      'kabelDipotong': state.kabelDipotong,
      'ratingWarung': state.ratingWarung,
      'stokBakso': state.stokBakso,
      'jumlahMejaKursi': state.jumlahMejaKursi,
      'jumlahAksesoris': state.jumlahAksesoris,
      'masak_lv': state.listKaryawan['Masak']?.level,
      'masak_un': state.listKaryawan['Masak']?.isUnlocked,
      'kasir_lv': state.listKaryawan['Kasir']?.level,
      'kasir_un': state.listKaryawan['Kasir']?.isUnlocked,
      'waiters_lv': state.listKaryawan['Waiters']?.level,
      'waiters_un': state.listKaryawan['Waiters']?.isUnlocked,
    };
    await prefs.setString('bakso_save_data_v3', jsonEncode(saveData));
  }

  void _inisialisasiDataBaru() {
    state.listKaryawan = {
      'Masak': Karyawan(posisi: 'Tukang Masak'),
      'Kasir': Karyawan(posisi: 'Kasir'),
      'Waiters': Karyawan(posisi: 'Waiters'),
    };
  }

  bool _potongSaldo(int jumlah, String metode) {
    if (metode == 'Tunai' && state.uangTunai >= jumlah) {
      state.uangTunai -= jumlah;
      return true;
    } else if (metode == 'QRIS' && state.saldoQRIS >= jumlah) {
      state.saldoQRIS -= jumlah;
      return true;
    }
    return false;
  }

  // Harga Bakso Berdasarkan Level Warung
  int get hargaBaksoSekarang {
    if (state.levelWarung >= 2) return 25000;
    return 15000;
  }

  String layaniPelanggan() {
    if (!isWarungBuka) return "Warung belum dibuka sam! Klik 'Buka Warung' dulu.";
    if (state.stokBakso <= 0) return "Stok Bakso Habis! Kulakan dulu di HP.";
    
    _tambahWaktu(30); // Setiap melayani bertambah 30 menit

    state.stokBakso -= 1;
    int hargaPorsi = hargaBaksoSekarang;
    bool bayarQRIS = Random().nextBool();
    
    if (bayarQRIS) {
      state.saldoQRIS += hargaPorsi;
    } else {
      state.uangTunai += hargaPorsi;
    }
    
    saveGameOffline();
    notifyListeners();
    
    String statusWaktu = " [Jam ${jam.toString().padLeft(2, '0')}:${menit.toString().padLeft(2, '0')}]";
    if (!isWarungBuka) {
      return "Pelanggan terakhir dilayani! Warung otomatis TUTUP (Sudah jam 21.30).";
    }
    return "Pelanggan membayar Rp $hargaPorsi via ${bayarQRIS ? 'QRIS' : 'Tunai'}$statusWaktu";
  }

  void _tambahWaktu(int tambahMenit) {
    menit += tambahMenit;
    if (menit >= 60) {
      jam += 1;
      menit = 0;
    }

    // Otomatis Tutup di jam 21.30
    if (jam > 21 || (jam == 21 && menit >= 30)) {
      tutupWarungOtomatis();
    }
  }

  void bukaWarungMulaiHari() {
    isWarungBuka = true;
    jam = 6;
    menit = 0;
    notifyListeners();
  }

  void tutupWarungOtomatis() {
    isWarungBuka = false;
    jam = 21;
    menit = 30;
    state.hariGame++;
    state.sisaHariTagihan--;
    if (state.sisaHariTagihan <= 0) {
      state.kabelDipotong = true;
    }
    saveGameOffline();
    notifyListeners();
  }

  // Set Harga Listrik Baru (Normal: 15k, Denda: 25k)
  bool bayarTagihan(String metode) {
    int biaya = state.kabelDipotong ? 25000 : 15000; 
    if (_potongSaldo(biaya, metode)) {
      state.sisaHariTagihan = 7;
      state.kabelDipotong = false;
      saveGameOffline();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool beliBarang(String jenis, int harga, int jumlah, String metode) {
    if (_potongSaldo(harga, metode)) {
      if (jenis == 'Bakso') state.stokBakso += jumlah;
      if (jenis == 'MejaKursi') state.jumlahMejaKursi += jumlah;
      if (jenis == 'Aksesoris') state.jumlahAksesoris += jumlah;
      
      if (state.listQuest[1].progresSaatIni < state.listQuest[1].targetJumlah) {
        state.listQuest[1].progresSaatIni += jumlah;
      }
      saveGameOffline();
      notifyListeners();
      return true;
    }
    return false;
  }

  void upgradeWarung() {
    if (state.levelWarung == 1 && state.expWarung >= 100) {
      state.levelWarung = 2;
      state.listKaryawan.forEach((key, value) => value.isUnlocked = true);
      saveGameOffline();
      notifyListeners();
    }
  }

  bool upgradeKaryawan(String posisi, String metode) {
    var k = state.listKaryawan[posisi];
    int biayaUpgrade = 250000;
    if (k != null && k.isUnlocked && k.level < 3) {
      if (_potongSaldo(biayaUpgrade, metode)) {
        k.level++;
        saveGameOffline();
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void claimQuestReward(String questId) {
    var q = state.listQuest.firstWhere((element) => element.id == questId);
    if (q.isComplete && !q.isClaimed) {
      q.isClaimed = true;
      state.expWarung += q.rewardExp;
      saveGameOffline();
      notifyListeners();
    }
  }
  
  void paksaUpdate() => notifyListeners();
}
