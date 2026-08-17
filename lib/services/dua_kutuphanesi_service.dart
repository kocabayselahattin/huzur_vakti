import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Kütüphane > Dua Kütüphanesi'nde gösterilen, duruma göre kategorilenmiş
/// tek bir dua kaydı (Arapça + okunuş + meal).
class DuaKaydi {
  final String id;
  final String kategori;
  final String baslik;
  final String arapca;
  final String okunus;
  final String meal;
  final String kaynak;

  const DuaKaydi({
    required this.id,
    required this.kategori,
    required this.baslik,
    required this.arapca,
    required this.okunus,
    required this.meal,
    required this.kaynak,
  });

  factory DuaKaydi.fromJson(Map<String, dynamic> json) {
    return DuaKaydi(
      id: json['id']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? '',
      baslik: json['baslik']?.toString() ?? '',
      arapca: json['arapca']?.toString() ?? '',
      okunus: json['okunus']?.toString() ?? '',
      meal: json['meal']?.toString() ?? '',
      kaynak: json['kaynak']?.toString() ?? '',
    );
  }
}

/// Kütüphanedeki dua verisini (bkz. assets/data/dua_kutuphanesi.json) yükler
/// ve favori dua kayıtlarını cihazda saklar.
///
/// İçerik (Arapça/okunuş/meal) her zaman Türkçe hazırlanmıştır — tıpkı
/// Kur'an sayfasındaki meal/transliterasyon gibi, uygulama dilinden
/// bağımsızdır. Yalnızca kategori adları ve arayüz metinleri dile göre
/// çevrilir (bkz. assets/lang/*.json içindeki `dua_category_*` anahtarları).
class DuaKutuphanesiService {
  static const String _asset = 'assets/data/dua_kutuphanesi.json';
  static const String _favoriAnahtari = 'dua_favorileri';

  /// Sabit kategori sırası; sayfadaki sekme/çip sırasıyla birebir eşleşir.
  static const List<String> kategoriler = [
    'yemek',
    'uyku',
    'yolculuk',
    'sifa',
    'sikinti',
    'istihare',
  ];

  static List<DuaKaydi>? _tumDualar;
  static Future<List<DuaKaydi>>? _yuklemeFuture;

  static Future<List<DuaKaydi>> tumDualar() {
    if (_tumDualar != null) return Future.value(_tumDualar);
    return _yuklemeFuture ??= _yukle();
  }

  static Future<List<DuaKaydi>> _yukle() async {
    try {
      final jsonStr = await rootBundle.loadString(_asset);
      final liste = json.decode(jsonStr) as List;
      final dualar = liste
          .whereType<Map<String, dynamic>>()
          .map(DuaKaydi.fromJson)
          .where((d) => d.id.isNotEmpty)
          .toList();
      _tumDualar = dualar;
      return dualar;
    } catch (_) {
      _yuklemeFuture = null;
      return const [];
    }
  }

  static Future<List<DuaKaydi>> kategoriyeGoreDualar(String kategori) async {
    final tumu = await tumDualar();
    return tumu.where((d) => d.kategori == kategori).toList();
  }

  static Future<Set<String>> favoriIdleri() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_favoriAnahtari) ?? const []).toSet();
  }

  static Future<bool> favoriMi(String id) async {
    return (await favoriIdleri()).contains(id);
  }

  /// Favori durumunu tersine çevirir, yeni durumu döndürür.
  static Future<bool> favoriDegistir(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriler = (prefs.getStringList(_favoriAnahtari) ?? const [])
        .toSet();
    final eklendiMi = !favoriler.contains(id);
    if (eklendiMi) {
      favoriler.add(id);
    } else {
      favoriler.remove(id);
    }
    await prefs.setStringList(_favoriAnahtari, favoriler.toList());
    return eklendiMi;
  }

  static Future<List<DuaKaydi>> favoriDualar() async {
    final favoriler = await favoriIdleri();
    if (favoriler.isEmpty) return const [];
    final tumu = await tumDualar();
    return tumu.where((d) => favoriler.contains(d.id)).toList();
  }
}
