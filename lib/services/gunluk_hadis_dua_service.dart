import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'kuran_veri_service.dart';
import 'language_service.dart';

/// Günün ayeti / hadisi / duası için **tek kaynak**.
///
/// Hem ana ekrandaki "Günün İçeriği" kartı hem de günlük içerik bildirimleri
/// buradan beslenir; böylece ikisi her zaman aynı içeriği gösterir.
///
/// - Ayet: cihazda gömülü tam Kur'an'dan (Elmalılı Hamdi Yazır meali) —
///   tarihe göre deterministik, internet gerektirmez.
/// - Hadis / Dua: ücretsiz ve kayıtsız CDN'den (fawazahmed0/hadith-api,
///   Sahih-i Buhârî Türkçe çevirisi) çekilir. Sonuç **tarih anahtarlı** olarak
///   önbelleğe yazılır; bildirimler ileri tarihler için önceden çektiğinde o
///   gün gelince kart aynı önbellekten okur ve içerik birebir aynı olur.
/// - İnternet yoksa dil dosyasındaki yerel havuza düşülür ve o metin de
///   önbelleğe yazılır, böylece tutarlılık yine korunur.
class GunlukHadisDuaService {
  static const _tekHadisBase =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/tur-bukhari';

  // Sahih-i Buhârî Türkçe edisyonunda hadis numaraları 1-7563 arası.
  static const int _hadisMinNo = 1;
  static const int _hadisMaxNo = 7563;

  // 80. Bölüm "Invocations" (Dualar): 6304-6411 arası.
  static const int _duaMinNo = 6304;
  static const int _duaMaxNo = 6411;

  // Kart ve bildirimde makul görünmesi için uzunluk sınırı (karakter).
  static const int _maxUzunluk = 500;

  static String _gunAnahtari(DateTime tarih) =>
      '${tarih.year}-${tarih.month}-${tarih.day}';

  static String _cacheMetinKey(String tur, DateTime tarih) =>
      'gunluk_${tur}_metin_${_gunAnahtari(tarih)}';

  static String _cacheKaynakKey(String tur, DateTime tarih) =>
      'gunluk_${tur}_kaynak_${_gunAnahtari(tarih)}';

  /// Referans tarihten bu yana geçen gün sayısına göre [aralikBaslangic]
  /// ile [aralikBitis] (dahil) arasında dönen bir hadis numarası üretir.
  static int _gunlukNo(DateTime tarih, int aralikBaslangic, int aralikBitis) {
    final referans = DateTime(2024, 1, 1);
    final bugun = DateTime(tarih.year, tarih.month, tarih.day);
    final gunSayisi = bugun.difference(referans).inDays;
    final genislik = aralikBitis - aralikBaslangic + 1;
    final index = ((gunSayisi % genislik) + genislik) % genislik;
    return aralikBaslangic + index;
  }

  /// Yerel yedek havuz için ay bazında dönen index (eski davranışla aynı).
  static int _yerelIndex({
    required DateTime date,
    required int length,
    required int contentOffset,
  }) {
    if (length <= 0) return 0;
    final monthKey = date.year * 12 + date.month;
    final monthOffset = (monthKey * 17 + contentOffset) % length;
    final dayOffset = date.day - 1;
    return (monthOffset + dayOffset) % length;
  }

  /// Referans metninde geçen "Tekrar: 54, 2529...", "Diğer Tahric:: ..."
  /// gibi kaynakça kırıntılarını ve tıklama notlarını temizler.
  static String _metniTemizle(String text) {
    var temiz = text;
    temiz = temiz.split('İZAHI İÇİN BURAYA TIKLA').first;
    temiz = temiz.replaceAll(RegExp(r'Tekrar:[^.]*\.'), '');
    temiz = temiz.replaceAll(RegExp(r'Diğer Tahric:.*$', dotAll: true), '');
    return temiz.trim();
  }

  static Future<Map<String, String>?> _hadisNoGetir(int no) async {
    try {
      final response = await http
          .get(Uri.parse('$_tekHadisBase/$no.json'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;
      final data = json.decode(utf8.decode(response.bodyBytes));
      final hadithler = data['hadiths'];
      if (hadithler is! List || hadithler.isEmpty) return null;
      final ilk = hadithler.first;
      final metin = _metniTemizle(ilk['text']?.toString() ?? '');
      if (metin.isEmpty) return null;
      return {
        'text': metin,
        'source': 'Buhârî, ${ilk['hadithnumber']}',
      };
    } catch (_) {
      return null;
    }
  }

  /// [baslangicNo]'dan itibaren, uzunluğu uygun olan ilk hadisi bulana kadar
  /// aralık içinde ileri doğru arar (en fazla [denemeSayisi] adım).
  static Future<Map<String, String>?> _uygunHadisBul({
    required int baslangicNo,
    required int aralikBaslangic,
    required int aralikBitis,
    int denemeSayisi = 8,
  }) async {
    var no = baslangicNo;
    for (int i = 0; i < denemeSayisi; i++) {
      final sonuc = await _hadisNoGetir(no);
      if (sonuc != null && (sonuc['text'] ?? '').length <= _maxUzunluk) {
        return sonuc;
      }
      no++;
      if (no > aralikBitis) no = aralikBaslangic;
    }
    return null;
  }

  static Map<String, String> _yerelHavuzdan({
    required String listeAnahtari,
    required DateTime tarih,
    required int contentOffset,
  }) {
    final liste = LanguageService()[listeAnahtari];
    if (liste is List && liste.isNotEmpty) {
      final index = _yerelIndex(
        date: tarih,
        length: liste.length,
        contentOffset: contentOffset,
      );
      final oge = liste[index];
      if (oge is Map) {
        return {
          'text': oge['text']?.toString() ?? '',
          'source': oge['source']?.toString() ?? '',
        };
      }
    }
    return {'text': '', 'source': ''};
  }

  /// Günün ayeti — gömülü tam Kur'an'dan, tarihe göre deterministik.
  /// Kur'an verisi henüz yüklenmemişse yerel havuza düşer.
  static Map<String, String> gununAyeti(DateTime tarih) {
    if (KuranVeriService.yuklendiMi) {
      final ayet = KuranVeriService.gununAyeti(tarih);
      if ((ayet['text'] ?? '').isNotEmpty) return ayet;
    }
    return _yerelHavuzdan(
      listeAnahtari: 'verses',
      tarih: tarih,
      contentOffset: 0,
    );
  }

  /// Ortak akış: önbellek → ağ → yerel havuz. Sonuç her durumda önbelleğe
  /// yazılır, böylece kart ve bildirim aynı içeriği gösterir.
  static Future<Map<String, String>> _icerikGetir({
    required String tur,
    required DateTime tarih,
    required int aralikBaslangic,
    required int aralikBitis,
    required String yerelListeAnahtari,
    required int yerelOffset,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final metinKey = _cacheMetinKey(tur, tarih);
    final kaynakKey = _cacheKaynakKey(tur, tarih);

    final onbellekMetin = prefs.getString(metinKey);
    if (onbellekMetin != null && onbellekMetin.isNotEmpty) {
      return {
        'text': onbellekMetin,
        'source': prefs.getString(kaynakKey) ?? '',
      };
    }

    final baslangicNo = _gunlukNo(tarih, aralikBaslangic, aralikBitis);
    final agSonucu = await _uygunHadisBul(
      baslangicNo: baslangicNo,
      aralikBaslangic: aralikBaslangic,
      aralikBitis: aralikBitis,
    );

    final sonuc = agSonucu ??
        _yerelHavuzdan(
          listeAnahtari: yerelListeAnahtari,
          tarih: tarih,
          contentOffset: yerelOffset,
        );

    if ((sonuc['text'] ?? '').isNotEmpty) {
      await prefs.setString(metinKey, sonuc['text']!);
      await prefs.setString(kaynakKey, sonuc['source'] ?? '');
      await _eskiOnbellegiTemizle(prefs);
    }

    return sonuc;
  }

  /// Günün hadisi (Sahih-i Buhârî, Türkçe).
  static Future<Map<String, String>> gununHadisi(DateTime tarih) {
    return _icerikGetir(
      tur: 'hadis',
      tarih: tarih,
      aralikBaslangic: _hadisMinNo,
      aralikBitis: _hadisMaxNo,
      yerelListeAnahtari: 'hadiths',
      yerelOffset: 14,
    );
  }

  /// Günün duası (Buhârî, "Dualar/Da'avât" bölümü).
  static Future<Map<String, String>> gununDuasi(DateTime tarih) {
    return _icerikGetir(
      tur: 'dua',
      tarih: tarih,
      aralikBaslangic: _duaMinNo,
      aralikBitis: _duaMaxNo,
      yerelListeAnahtari: 'prayers',
      yerelOffset: 7,
    );
  }

  /// 30 günden eski önbellek kayıtlarını siler (SharedPreferences şişmesin).
  static Future<void> _eskiOnbellegiTemizle(SharedPreferences prefs) async {
    final sinir = DateTime.now().subtract(const Duration(days: 30));
    for (final key in prefs.getKeys().toList()) {
      if (!key.startsWith('gunluk_hadis_') && !key.startsWith('gunluk_dua_')) {
        continue;
      }
      final parcalar = key.split('_');
      if (parcalar.length < 4) continue;
      final tarihParcalari = parcalar.last.split('-');
      if (tarihParcalari.length != 3) continue;
      final yil = int.tryParse(tarihParcalari[0]);
      final ay = int.tryParse(tarihParcalari[1]);
      final gun = int.tryParse(tarihParcalari[2]);
      if (yil == null || ay == null || gun == null) continue;
      if (DateTime(yil, ay, gun).isBefore(sinir)) {
        await prefs.remove(key);
      }
    }
  }
}
