import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Cihazda yerel olarak gömülü tam Kur'an-ı Kerim verisini (Elmalılı Hamdi
/// Yazır meali) yönetir. İnternet gerektirmeden Kur'an sayfasını ve günün
/// ayeti içeriğini besler.
class KuranVeriService {
  static Map<String, dynamic>? _veri;
  static List<_FlatAyet>? _tumAyetlerSirali;

  // Sure no (1-114) -> Türkçe sure adı.
  static const List<String> sureAdlari = [
    'Fatiha', 'Bakara', 'Âl-i İmrân', 'Nisâ', 'Mâide', "En'âm", "A'râf",
    'Enfâl', 'Tevbe', 'Yûnus', 'Hûd', 'Yûsuf', "Ra'd", 'İbrâhîm', 'Hicr',
    'Nahl', 'İsrâ', 'Kehf', 'Meryem', 'Tâhâ', 'Enbiyâ', 'Hac', "Mü'minûn",
    'Nûr', 'Furkân', 'Şuarâ', 'Neml', 'Kasas', 'Ankebût', 'Rûm', 'Lokmân',
    'Secde', 'Ahzâb', "Sebe'", 'Fâtır', 'Yâsîn', 'Sâffât', 'Sâd', 'Zümer',
    "Mü'min", 'Fussilet', 'Şûrâ', 'Zuhruf', 'Duhân', 'Câsiye', 'Ahkâf',
    'Muhammed', 'Fetih', 'Hucurât', 'Kâf', 'Zâriyât', 'Tûr', 'Necm', 'Kamer',
    'Rahmân', 'Vâkıa', 'Hadîd', 'Mücâdele', 'Haşr', 'Mümtehine', 'Saf',
    'Cuma', 'Münâfikûn', 'Teğâbün', 'Talâk', 'Tahrîm', 'Mülk', 'Kalem',
    'Hâkka', 'Meâric', 'Nûh', 'Cin', 'Müzzemmil', 'Müddessir', 'Kıyâme',
    'İnsân', 'Mürselât', "Nebe'", 'Nâziât', 'Abese', 'Tekvîr', 'İnfitâr',
    'Mutaffifîn', 'İnşikâk', 'Bürûc', 'Târık', "A'lâ", 'Gâşiye', 'Fecr',
    'Beled', 'Şems', 'Leyl', 'Duhâ', 'İnşirâh', 'Tîn', 'Alak', 'Kadir',
    'Beyyine', 'Zilzâl', 'Âdiyât', 'Kâria', 'Tekâsür', 'Asr', 'Hümeze',
    'Fîl', 'Kureyş', 'Mâûn', 'Kevser', 'Kâfirûn', 'Nasr', 'Tebbet', 'İhlâs',
    'Felak', 'Nâs',
  ];

  static bool get yuklendiMi => _veri != null;

  /// Yerel Kur'an verisini bir kez yükler ve bellekte tutar.
  static Future<void> yukle() async {
    if (_veri != null) return;
    final jsonStr = await rootBundle.loadString('assets/data/kuran_meal.json');
    _veri = json.decode(jsonStr) as Map<String, dynamic>;
  }

  /// Belirtilen sureye ait ayetleri döndürür.
  /// Her öğe: {'no': int, 'arapca': String, 'okunus': String, 'meal': String}
  static List<Map<String, dynamic>> sureAyetleri(int sureNo) {
    final veri = _veri;
    if (veri == null) return [];
    final liste = veri[sureNo.toString()];
    if (liste is! List) return [];
    return liste.cast<Map<String, dynamic>>();
  }

  static void _siraliListeyiOlustur() {
    if (_tumAyetlerSirali != null) return;
    final veri = _veri;
    if (veri == null) {
      _tumAyetlerSirali = [];
      return;
    }
    final sonuc = <_FlatAyet>[];
    for (int sureNo = 1; sureNo <= 114; sureNo++) {
      final ayetler = veri[sureNo.toString()];
      if (ayetler is! List) continue;
      for (final a in ayetler) {
        if (a is Map) {
          sonuc.add(
            _FlatAyet(
              sureNo: sureNo,
              ayetNo: a['no'] is int
                  ? a['no'] as int
                  : int.tryParse(a['no']?.toString() ?? '') ?? 0,
              meal: a['meal']?.toString() ?? '',
            ),
          );
        }
      }
    }
    _tumAyetlerSirali = sonuc;
  }

  /// Günün ayetini Kur'an sırasına göre (Fatiha 1'den başlayarak) döndürür.
  /// Sabit bir referans tarihe göre gün saydığı için her gün farklı bir ayet
  /// gösterir ve tüm Kur'an'ı bitirmesi ~17 yıl sürer.
  static Map<String, String> gununAyeti(DateTime tarih) {
    _siraliListeyiOlustur();
    final liste = _tumAyetlerSirali;
    if (liste == null || liste.isEmpty) return {'text': '', 'source': ''};

    final referans = DateTime(2024, 1, 1);
    final bugun = DateTime(tarih.year, tarih.month, tarih.day);
    final gunSayisi = bugun.difference(referans).inDays;
    final index = gunSayisi % liste.length;
    final normalizedIndex = index < 0 ? index + liste.length : index;

    final ayet = liste[normalizedIndex];
    final sureAdi = ayet.sureNo >= 1 && ayet.sureNo <= sureAdlari.length
        ? sureAdlari[ayet.sureNo - 1]
        : '';

    return {
      'text': ayet.meal,
      'source': '$sureAdi, ${ayet.ayetNo}',
    };
  }
}

class _FlatAyet {
  final int sureNo;
  final int ayetNo;
  final String meal;

  _FlatAyet({required this.sureNo, required this.ayetNo, required this.meal});
}
