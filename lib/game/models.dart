class Karyawan {
  final String posisi; 
  int level;           
  bool isUnlocked;

  Karyawan({required this.posisi, this.level = 1, this.isUnlocked = false});

  double get bonusKecepatan {
    if (level == 2) return 0.10; // Level 2: +10%
    if (level == 3) return 0.25; // Level 3: +25%
    return 0.07;                 // Level 1: +7%
  }
}

class Quest {
  final String id;
  final String judul;
  final String deskripsi;
  final int targetJumlah;
  int progresSaatIni;
  final int rewardExp;
  bool isClaimed;

  Quest({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.targetJumlah,
    this.progresSaatIni = 0,
    required this.rewardExp,
    this.isClaimed = false,
  });

  bool get isComplete => progresSaatIni >= targetJumlah;
}

class GameState {
  int uangTunai;
  int saldoQRIS;
  int levelWarung; 
  int expWarung;
  int hariGame; 
  int sisaHariTagihan; 
  bool kabelDipotong;
  double ratingWarung; 

  int stokBakso;
  int jumlahMejaKursi;
  int jumlahAksesoris;

  Map<String, Karyawan> listKaryawan;
  List<Quest> listQuest;

  GameState({
    this.uangTunai = 200000, 
    this.saldoQRIS = 300000, 
    this.levelWarung = 1,
    this.expWarung = 0,
    this.hariGame = 1,
    this.sisaHariTagihan = 7,
    this.kabelDipotong = false,
    this.ratingWarung = 4.0,
    this.stokBakso = 50,
    this.jumlahMejaKursi = 2,
    this.jumlahAksesoris = 0,
    required this.listKaryawan,
    required this.listQuest,
  });
}
