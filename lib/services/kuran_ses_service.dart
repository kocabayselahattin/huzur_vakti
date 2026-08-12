import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'kuran_veri_service.dart';

/// Kur'an ayetlerinin sesli okunuşunu (Mishary Alafasy, aynı okuyucu metinde
/// kullanılan "ar.alafasy" ile eşleşir) sure bazında isteğe bağlı indirir ve
/// çalar. Hiçbir ses dosyası uygulamayla birlikte gelmez — kullanıcı bir
/// sureyi indirmediği sürece hiç veri çekilmez.
class KuranSesService {
  static const String _cdnBase =
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy';

  static Directory? _kokDizin;

  static Future<Directory> _sesKlasoru() async {
    if (_kokDizin != null) return _kokDizin!;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/kuran_sesleri');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _kokDizin = dir;
    return dir;
  }

  /// Surenin başından itibaren global (Kur'an geneli) ayet numarasını
  /// hesaplar (1-6236 arası) — CDN ayetleri bu numarayla adresliyor.
  static int globalAyetNo(int sureNo, int ayetNo) {
    int toplam = 0;
    for (int s = 1; s < sureNo; s++) {
      toplam += KuranVeriService.sureAyetleri(s).length;
    }
    return toplam + ayetNo;
  }

  static Future<File> _dosyaYolu(int sureNo, int ayetNo) async {
    final dir = await _sesKlasoru();
    return File('${dir.path}/${sureNo}_$ayetNo.mp3');
  }

  static Future<bool> ayetIndirilmisMi(int sureNo, int ayetNo) async {
    final dosya = await _dosyaYolu(sureNo, ayetNo);
    return dosya.exists();
  }

  /// Bir ayetin çalınabilir kaynağını döndürür: yerelde indirilmişse dosya
  /// yolu, değilse doğrudan CDN URL'i (akış/streaming).
  static Future<({String kaynak, bool yerel})> calmaKaynagi(
    int sureNo,
    int ayetNo,
  ) async {
    final dosya = await _dosyaYolu(sureNo, ayetNo);
    if (await dosya.exists()) {
      return (kaynak: dosya.path, yerel: true);
    }
    final globalNo = globalAyetNo(sureNo, ayetNo);
    return (kaynak: '$_cdnBase/$globalNo.mp3', yerel: false);
  }

  static Future<bool> sureTamIndirilmisMi(int sureNo) async {
    final ayetSayisi = KuranVeriService.sureAyetleri(sureNo).length;
    if (ayetSayisi == 0) return false;
    for (int i = 1; i <= ayetSayisi; i++) {
      if (!await ayetIndirilmisMi(sureNo, i)) return false;
    }
    return true;
  }

  /// Sureyi ayet ayet indirir. [ilerleme] her tamamlanan ayette çağrılır.
  /// Zaten indirilmiş ayetler tekrar indirilmez (kesintiden devam edebilir).
  static Future<void> sureyiIndir(
    int sureNo, {
    required void Function(int tamamlanan, int toplam) ilerleme,
    int esZamanliIstek = 4,
  }) async {
    final ayetSayisi = KuranVeriService.sureAyetleri(sureNo).length;
    if (ayetSayisi == 0) return;

    final baslangicGlobal = globalAyetNo(sureNo, 1);
    int tamamlanan = 0;

    Future<void> birAyetIndir(int ayetNo) async {
      final dosya = await _dosyaYolu(sureNo, ayetNo);
      if (!await dosya.exists()) {
        final globalNo = baslangicGlobal + ayetNo - 1;
        try {
          final response = await http
              .get(Uri.parse('$_cdnBase/$globalNo.mp3'))
              .timeout(const Duration(seconds: 20));
          if (response.statusCode == 200) {
            await dosya.writeAsBytes(response.bodyBytes);
          }
        } catch (_) {
          // Bir ayet indirilemezse indirmeyi durdurma; kullanıcı tekrar
          // deneyebilir, o ayet çalınırken akıştan (streaming) oynatılır.
        }
      }
      tamamlanan++;
      ilerleme(tamamlanan, ayetSayisi);
    }

    final kuyruk = List.generate(ayetSayisi, (i) => i + 1);
    while (kuyruk.isNotEmpty) {
      final parti = kuyruk.take(esZamanliIstek).toList();
      kuyruk.removeRange(0, parti.length);
      await Future.wait(parti.map(birAyetIndir));
    }
  }

  static Future<void> sureyiSil(int sureNo) async {
    final ayetSayisi = KuranVeriService.sureAyetleri(sureNo).length;
    for (int i = 1; i <= ayetSayisi; i++) {
      final dosya = await _dosyaYolu(sureNo, i);
      if (await dosya.exists()) {
        await dosya.delete();
      }
    }
  }
}
