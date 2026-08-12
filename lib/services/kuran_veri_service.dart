import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;

/// Cihazda yerel olarak gömülü tam Kur'an-ı Kerim verisini (Elmalılı Hamdi
/// Yazır meali) yönetir. İnternet gerektirmeden Kur'an sayfasını ve günün
/// ayeti içeriğini besler.
class KuranVeriService {
  static Map<String, dynamic>? _veri;
  static List<_FlatAyet>? _tumAyetlerSirali;

  /// Besmele-i şerif. Ayet gösterilen her yerde (günün ayeti kartı, paylaşım
  /// görseli, düz metin paylaşımı) metnin başına konur.
  static const String besmele = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

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

  static Future<void>? _yuklemeFuture;

  static bool get yuklendiMi => _veri != null;

  /// Yerel Kur'an verisini bir kez yükler ve bellekte tutar.
  ///
  /// ~3 MB'lık JSON'un ayrıştırılması ayrı bir isolate'te (compute) yapılır;
  /// aksi halde açılışta arayüz donar ve uygulama beyaz ekranda bekler.
  /// Eşzamanlı çağrılar aynı yüklemeyi paylaşır, veri iki kez ayrıştırılmaz.
  static Future<void> yukle() {
    if (_veri != null) return Future.value();
    return _yuklemeFuture ??= _yukleVeAyristir();
  }

  static Future<void> _yukleVeAyristir() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/kuran_meal.json');
      _veri = await compute(_jsonAyristir, jsonStr);
    } catch (_) {
      // Yükleme başarısızsa çağıranlar yerel yedek içeriğe düşer.
      _yuklemeFuture = null;
    }
  }

  /// compute() ile ayrı isolate'te çalışır; üst düzey/static olmak zorundadır.
  static Map<String, dynamic> _jsonAyristir(String jsonStr) =>
      json.decode(jsonStr) as Map<String, dynamic>;

  /// Belirtilen sureye ait ayetleri döndürür.
  /// Her öğe: {'no': int, 'arapca': String, 'okunus': String, 'meal': String}
  static List<Map<String, dynamic>> sureAyetleri(int sureNo) {
    final veri = _veri;
    if (veri == null) return [];
    final liste = veri[sureNo.toString()];
    if (liste is! List) return [];
    return liste.cast<Map<String, dynamic>>();
  }

  /// Günün ayeti havuzunu oluşturur. Tek başına gösterildiğinde anlamlı
  /// olmayacak kadar kısa mealler (ör. huruf-u mukattaa: "Elif, lâm, mîm.")
  /// havuza hiç alınmaz — böylece her gün farklı ve anlamlı bir ayet gelir.
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
          final meal = a['meal']?.toString() ?? '';
          if (meal.trim().length < _minMealUzunlugu) continue;
          sonuc.add(
            _FlatAyet(
              sureNo: sureNo,
              ayetNo: a['no'] is int
                  ? a['no'] as int
                  : int.tryParse(a['no']?.toString() ?? '') ?? 0,
              meal: meal,
              arapca: a['arapca']?.toString() ?? '',
            ),
          );
        }
      }
    }
    _tumAyetlerSirali = sonuc;
  }

  /// Tek başına gösterildiğinde anlamlı olmayacak kadar kısa mealler
  /// (ör. huruf-u mukattaa: "Elif, lâm, mîm.") için alt sınır.
  static const int _minMealUzunlugu = 30;

  /// Günün ayeti sayacının başlangıcı. Sıranın nereden başladığını belirleyen
  /// keyfi bir sabittir; değiştirilirse sıra tümüyle kayar.
  static final DateTime _ayetReferansTarihi = DateTime(2024, 1, 1);

  /// Günün ayetini, Kur'an'ın tamamına yayılmış tekrarsız bir sırayla döndürür.
  ///
  /// Ayetler mushaf sırasıyla değil karışık gelir; böylece her gün farklı bir
  /// sureden ayet çıkar. Buna rağmen sıra rastgele değildir: seçim yalnızca
  /// tarihe bağlıdır, dolayısıyla kart, bildirim ve ana ekran widget'ı hep aynı
  /// ayeti gösterir ve aynı gün her cihazda aynı ayet görünür.
  ///
  /// Çok kısa mealler (huruf-u mukattaa gibi) havuza hiç alınmaz.
  static Map<String, String> gununAyeti(DateTime tarih) {
    _siraliListeyiOlustur();
    final liste = _tumAyetlerSirali;
    if (liste == null || liste.isEmpty) return {'text': '', 'source': ''};

    final bugun = DateTime(tarih.year, tarih.month, tarih.day);
    final gunSayisi = bugun.difference(_ayetReferansTarihi).inDays;
    final index = _karisikIndex(gunSayisi, liste.length);
    final secilen = liste[index];

    final sureAdi = secilen.sureNo >= 1 && secilen.sureNo <= sureAdlari.length
        ? sureAdlari[secilen.sureNo - 1]
        : '';

    return {
      'text': secilen.meal,
      'source': '$sureAdi, ${secilen.ayetNo}',
      // Paylaşım kartı Arapça metni de basabilsin diye taşınır; metin
      // gösteren tüketiciler yalnızca 'text' ve 'source' okur.
      'arabic': secilen.arapca,
    };
  }

  /// Gün sayısını, havuzun tamamını tekrarsız dolaşan karışık bir sıraya çevirir.
  ///
  /// Her gün [_adim] kadar ileri atlanır. Adım, havuz uzunluğuyla aralarında
  /// asal seçildiği için bu atlayış tüm havuzu ziyaret etmeden başa dönmez:
  /// ayetler karışık gelir ama havuz bitmeden hiçbiri ikinci kez çıkmaz.
  static int _karisikIndex(int gunSayisi, int uzunluk) {
    if (uzunluk <= 1) return 0;

    var adim = 7919; // Havuz uzunluğuna göre ayarlanan büyük asal.
    while (_obeb(adim, uzunluk) != 1) {
      adim++;
    }

    // Referans tarihten önceki günlerde çarpım negatif olabilir.
    final ham = (gunSayisi * adim) % uzunluk;
    return (ham + uzunluk) % uzunluk;
  }

  /// En büyük ortak bölen (Öklid).
  static int _obeb(int a, int b) {
    var x = a.abs();
    var y = b.abs();
    while (y != 0) {
      final kalan = x % y;
      x = y;
      y = kalan;
    }
    return x;
  }
}

class _FlatAyet {
  final int sureNo;
  final int ayetNo;
  final String meal;
  final String arapca;

  _FlatAyet({
    required this.sureNo,
    required this.ayetNo,
    required this.meal,
    required this.arapca,
  });
}
