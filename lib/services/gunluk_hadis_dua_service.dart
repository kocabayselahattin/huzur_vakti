import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
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
  static const _cdnBase =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';

  /// Havuz dosyası: hangi kitabın hangi hadis numaralarının günlük içerik
  /// olarak kullanılabileceğini tutar. Metinlerin kendisi değil, yalnızca
  /// numaralar burada; içerik her gün CDN'den tek tek çekilir.
  ///
  /// Numaralar önceden süzülmüştür (çeviri mevcut ve karta/bildirime sığacak
  /// uzunlukta). Aksi halde uygun içeriği bulmak için ileri arama gerekiyor ve
  /// ardışık günler aynı hadise düşebiliyordu.
  static const _havuzAsset = 'assets/data/gunluk_icerik_havuzu.json';

  static List<_HavuzKaynagi>? _hadisKaynaklari;
  static List<_HavuzKaynagi>? _duaKaynaklari;
  static Future<void>? _havuzFuture;

  static Future<void> _havuzuYukle() {
    if (_hadisKaynaklari != null) return Future.value();
    return _havuzFuture ??= _havuzuOku();
  }

  static Future<void> _havuzuOku() async {
    try {
      final jsonStr = await rootBundle.loadString(_havuzAsset);
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      _hadisKaynaklari = _kaynaklariAyristir(data['hadis']);
      _duaKaynaklari = _kaynaklariAyristir(data['dua']);
    } catch (_) {
      _havuzFuture = null;
    }
  }

  static List<_HavuzKaynagi> _kaynaklariAyristir(dynamic liste) {
    if (liste is! List) return [];
    return liste
        .whereType<Map<String, dynamic>>()
        .map(
          (k) => _HavuzKaynagi(
            kitap: k['kitap']?.toString() ?? '',
            kisaAd: k['kisa']?.toString() ?? '',
            nolar: (k['nolar'] as List?)?.whereType<int>().toList() ?? const [],
          ),
        )
        .where((k) => k.kitap.isNotEmpty && k.nolar.isNotEmpty)
        .toList();
  }

  static String _gunAnahtari(DateTime tarih) =>
      '${tarih.year}-${tarih.month}-${tarih.day}';

  static String _cacheMetinKey(String tur, DateTime tarih) =>
      'gunluk_${tur}_metin_${_gunAnahtari(tarih)}';

  static String _cacheKaynakKey(String tur, DateTime tarih) =>
      'gunluk_${tur}_kaynak_${_gunAnahtari(tarih)}';

  /// Referans tarihten bu yana geçen gün sayısı (tarihe göre deterministik).
  static int _gunSayisi(DateTime tarih) {
    final referans = DateTime(2024, 1, 1);
    final bugun = DateTime(tarih.year, tarih.month, tarih.day);
    return bugun.difference(referans).inDays;
  }

  /// Birden fazla kitabın numara listelerini tek bir sıralı havuz gibi ele
  /// alır; verilen sıra numarasının hangi kitabın hangi hadisine denk
  /// geldiğini döndürür. Havuzdaki her numara kullanılabilir olduğu için
  /// ardışık günler farklı içerik alır.
  static ({String kitap, String kisaAd, int no})? _havuzKonumu(
    List<_HavuzKaynagi> kaynaklar,
    int sira,
  ) {
    final toplam = kaynaklar.fold<int>(0, (t, k) => t + k.nolar.length);
    if (toplam == 0) return null;
    var kalan = ((sira % toplam) + toplam) % toplam;
    for (final kaynak in kaynaklar) {
      if (kalan < kaynak.nolar.length) {
        return (
          kitap: kaynak.kitap,
          kisaAd: kaynak.kisaAd,
          no: kaynak.nolar[kalan],
        );
      }
      kalan -= kaynak.nolar.length;
    }
    return null;
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

  /// Tek bir hadisi CDN'den çeker (~1 KB'lık istek).
  static Future<Map<String, String>?> _hadisNoGetir(
    String kitap,
    String kisaAd,
    int no,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$_cdnBase/$kitap/$no.json'))
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
        'source': '$kisaAd, ${ilk['hadithnumber']}',
      };
    } catch (_) {
      return null;
    }
  }

  /// Havuzdaki [baslangicSira] konumundan başlayarak, uzunluğu karta/bildirime
  /// sığan ilk hadisi arar. Aradaki numaralar eksik olabildiği (ve bazı
  /// rivayetler çok uzun olduğu) için sırayla ilerler.
  static Future<Map<String, String>?> _uygunHadisBul({
    required List<_HavuzKaynagi> kaynaklar,
    required int baslangicSira,
    int denemeSayisi = 3,
  }) async {
    // Havuzdaki numaralar önceden süzülmüş olduğu için ilk deneme normalde
    // başarılı olur; ek denemeler yalnızca geçici ağ hatalarına karşıdır.
    for (int i = 0; i < denemeSayisi; i++) {
      final konum = _havuzKonumu(kaynaklar, baslangicSira + i);
      if (konum == null) return null;
      final sonuc = await _hadisNoGetir(konum.kitap, konum.kisaAd, konum.no);
      if (sonuc != null && (sonuc['text'] ?? '').isNotEmpty) {
        return sonuc;
      }
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
    required bool duaMi,
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

    await _havuzuYukle();
    final kaynaklar =
        (duaMi ? _duaKaynaklari : _hadisKaynaklari) ?? const <_HavuzKaynagi>[];

    final agSonucu = kaynaklar.isEmpty
        ? null
        : await _uygunHadisBul(
            kaynaklar: kaynaklar,
            baslangicSira: _gunSayisi(tarih),
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
      duaMi: false,
      yerelListeAnahtari: 'hadiths',
      yerelOffset: 14,
    );
  }

  /// Günün duası (Buhârî, Müslim ve Tirmizî'nin dua/zikir bölümleri).
  static Future<Map<String, String>> gununDuasi(DateTime tarih) {
    return _icerikGetir(
      tur: 'dua',
      tarih: tarih,
      duaMi: true,
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

/// Bir hadis kitabının, günlük içerik havuzunda kullanılabilir hadis
/// numaraları. Metinler burada tutulmaz; her gün yalnızca seçilen numara
/// CDN'den çekilir.
class _HavuzKaynagi {
  /// CDN'deki edisyon adı (ör. "tur-bukhari").
  final String kitap;

  /// Kaynakta gösterilecek kısa ad (ör. "Buhârî").
  final String kisaAd;

  final List<int> nolar;

  const _HavuzKaynagi({
    required this.kitap,
    required this.kisaAd,
    required this.nolar,
  });
}
