import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Günün hadisi ve günün duasını, ücretsiz/kayıtsız CDN üzerinden
/// (fawazahmed0/hadith-api, Sahih-i Buhârî Türkçe çevirisi) her gün canlı
/// olarak çeker. Tek hadis boyutu ~1KB olduğu için hafif ve hızlıdır.
///
/// Günlük sonuç SharedPreferences'ta önbelleklenir; internet yoksa (veya
/// içerik uygunsuz uzunluktaysa) çağıran taraf yerel yedek havuza düşer.
class GunlukHadisDuaService {
  static const _tekHadisBase =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/tur-bukhari';

  // Sahih-i Buhârî Türkçe edisyonunda hadis numaraları 1-7563 arası.
  static const int _hadisMinNo = 1;
  static const int _hadisMaxNo = 7563;

  // 80. Bölüm "Invocations" (Dualar): 6304-6411 arası.
  static const int _duaMinNo = 6304;
  static const int _duaMaxNo = 6411;

  // Kart içinde makul görünmesi için uzunluk sınırı (karakter).
  static const int _maxUzunluk = 500;

  static const _prefsHadisTarih = 'gunluk_hadis_tarih';
  static const _prefsHadisMetin = 'gunluk_hadis_metin';
  static const _prefsHadisKaynak = 'gunluk_hadis_kaynak';

  static const _prefsDuaTarih = 'gunluk_dua_tarih';
  static const _prefsDuaMetin = 'gunluk_dua_metin';
  static const _prefsDuaKaynak = 'gunluk_dua_kaynak';

  static String _gunAnahtari(DateTime tarih) =>
      '${tarih.year}-${tarih.month}-${tarih.day}';

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
        'no': no.toString(),
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

  /// Günün hadisini döndürür. Önce bugüne ait önbelleği kontrol eder,
  /// yoksa canlı çeker ve önbelleğe alır. Başarısız olursa null döner
  /// (çağıran taraf yerel yedek havuzu kullanmalı).
  static Future<Map<String, String>?> gununHadisi(DateTime tarih) async {
    final prefs = await SharedPreferences.getInstance();
    final anahtar = _gunAnahtari(tarih);

    if (prefs.getString(_prefsHadisTarih) == anahtar) {
      final metin = prefs.getString(_prefsHadisMetin);
      final kaynak = prefs.getString(_prefsHadisKaynak);
      if (metin != null && metin.isNotEmpty) {
        return {'text': metin, 'source': kaynak ?? ''};
      }
    }

    final baslangicNo = _gunlukNo(tarih, _hadisMinNo, _hadisMaxNo);
    final sonuc = await _uygunHadisBul(
      baslangicNo: baslangicNo,
      aralikBaslangic: _hadisMinNo,
      aralikBitis: _hadisMaxNo,
    );
    if (sonuc == null) return null;

    await prefs.setString(_prefsHadisTarih, anahtar);
    await prefs.setString(_prefsHadisMetin, sonuc['text']!);
    await prefs.setString(_prefsHadisKaynak, sonuc['source']!);
    return sonuc;
  }

  /// Günün duasını döndürür (Buhârî, 80. Bölüm "Dualar/Da'avât").
  static Future<Map<String, String>?> gununDuasi(DateTime tarih) async {
    final prefs = await SharedPreferences.getInstance();
    final anahtar = _gunAnahtari(tarih);

    if (prefs.getString(_prefsDuaTarih) == anahtar) {
      final metin = prefs.getString(_prefsDuaMetin);
      final kaynak = prefs.getString(_prefsDuaKaynak);
      if (metin != null && metin.isNotEmpty) {
        return {'text': metin, 'source': kaynak ?? ''};
      }
    }

    final baslangicNo = _gunlukNo(tarih, _duaMinNo, _duaMaxNo);
    final sonuc = await _uygunHadisBul(
      baslangicNo: baslangicNo,
      aralikBaslangic: _duaMinNo,
      aralikBitis: _duaMaxNo,
    );
    if (sonuc == null) return null;

    await prefs.setString(_prefsDuaTarih, anahtar);
    await prefs.setString(_prefsDuaMetin, sonuc['text']!);
    await prefs.setString(_prefsDuaKaynak, sonuc['source']!);
    return sonuc;
  }
}
