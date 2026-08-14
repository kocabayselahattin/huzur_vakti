import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_service.dart';
import 'kuran_veri_service.dart';
import 'language_service.dart';
import 'ozel_gunler_service.dart';

enum HatimPlanTuru { serbest, ramazan }

/// Kullanıcının okuma planlarından biri. Birden fazla plan aynı anda aktif
/// olabilir (ör. Ramazan'da hem senelik serbest hatmine hem Ramazan hatmine
/// paralel devam etmek); ilerleme ve hatırlatma saati her plana özeldir.
class HatimPlani {
  final String id;
  final String ad;
  final HatimPlanTuru turu;
  final DateTime baslangicTarihi;
  final int toplamGun;

  /// Şu ana kadar okunan son ayet. [mevcutAyetNo] 0 ise plan henüz
  /// başlamamış demektir (hiç ilerleme kaydedilmemiş).
  final int mevcutSureNo;
  final int mevcutAyetNo;

  final bool hatirlaticiAcik;
  final String hatirlaticiSaati; // "HH:mm"

  const HatimPlani({
    required this.id,
    required this.ad,
    required this.turu,
    required this.baslangicTarihi,
    required this.toplamGun,
    this.mevcutSureNo = 1,
    this.mevcutAyetNo = 0,
    this.hatirlaticiAcik = true,
    this.hatirlaticiSaati = '21:00',
  });

  HatimPlani kopyala({
    String? ad,
    int? mevcutSureNo,
    int? mevcutAyetNo,
    bool? hatirlaticiAcik,
    String? hatirlaticiSaati,
  }) => HatimPlani(
    id: id,
    ad: ad ?? this.ad,
    turu: turu,
    baslangicTarihi: baslangicTarihi,
    toplamGun: toplamGun,
    mevcutSureNo: mevcutSureNo ?? this.mevcutSureNo,
    mevcutAyetNo: mevcutAyetNo ?? this.mevcutAyetNo,
    hatirlaticiAcik: hatirlaticiAcik ?? this.hatirlaticiAcik,
    hatirlaticiSaati: hatirlaticiSaati ?? this.hatirlaticiSaati,
  );

  int get tamamlananAyetSayisi => mevcutAyetNo == 0
      ? 0
      : KuranVeriService.globalAyetNo(mevcutSureNo, mevcutAyetNo);

  double get ilerlemeOrani =>
      (tamamlananAyetSayisi / KuranVeriService.toplamAyetSayisi).clamp(
        0.0,
        1.0,
      );

  bool get tamamlandiMi =>
      tamamlananAyetSayisi >= KuranVeriService.toplamAyetSayisi;

  /// Planın kaçıncı gününde olduğumuz (0-based). Plan süresinin dışına
  /// taşarsa son güne sabitlenir, henüz başlamadıysa negatif olabilir.
  int gunIndex([DateTime? simdi]) {
    final bugun = _saatsiz(simdi ?? DateTime.now());
    final baslangic = _saatsiz(baslangicTarihi);
    return bugun.difference(baslangic).inDays;
  }

  static DateTime _saatsiz(DateTime t) => DateTime(t.year, t.month, t.day);

  Map<String, dynamic> toJson() => {
    'id': id,
    'ad': ad,
    'turu': turu.name,
    'baslangicTarihi': baslangicTarihi.toIso8601String(),
    'toplamGun': toplamGun,
    'mevcutSureNo': mevcutSureNo,
    'mevcutAyetNo': mevcutAyetNo,
    'hatirlaticiAcik': hatirlaticiAcik,
    'hatirlaticiSaati': hatirlaticiSaati,
  };

  factory HatimPlani.fromJson(Map<String, dynamic> j) {
    final turu = HatimPlanTuru.values.firstWhere(
      (t) => t.name == j['turu'],
      orElse: () => HatimPlanTuru.serbest,
    );
    return HatimPlani(
      id:
          j['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      ad:
          j['ad'] as String? ??
          (turu == HatimPlanTuru.ramazan ? 'Ramazan Hatmim' : 'Hatmim'),
      turu: turu,
      baslangicTarihi: DateTime.parse(j['baslangicTarihi'] as String),
      toplamGun: j['toplamGun'] as int,
      mevcutSureNo: j['mevcutSureNo'] as int? ?? 1,
      mevcutAyetNo: j['mevcutAyetNo'] as int? ?? 0,
      hatirlaticiAcik: j['hatirlaticiAcik'] as bool? ?? true,
      hatirlaticiSaati: j['hatirlaticiSaati'] as String? ?? '21:00',
    );
  }
}

/// Bir günün okuma hedefi: ulaşılması gereken sayfa (serbest plan) ya da
/// cüz (Ramazan planı), hedefin bittiği ayetle birlikte.
class HatimGunlukHedef {
  final int gunNo;
  final String etiket;
  final int hedefSureNo;
  final int hedefAyetNo;

  const HatimGunlukHedef({
    required this.gunNo,
    required this.etiket,
    required this.hedefSureNo,
    required this.hedefAyetNo,
  });
}

// 30 cüzün bittiği [sureNo, ayetNo]. kuran_sayfa.dart'taki _cuzler
// listesiyle aynı, iyi bilinen 30 cüz sınırları (bağımsız küçük bir kopya;
// UI tarafındaki Cuz modeliyle karıştırılmasın diye burada tutulur).
const List<List<int>> _cuzSonlari = [
  [2, 141],
  [2, 252],
  [3, 92],
  [4, 23],
  [4, 147],
  [5, 81],
  [6, 110],
  [7, 87],
  [8, 40],
  [9, 92],
  [11, 5],
  [12, 52],
  [14, 52],
  [16, 128],
  [18, 74],
  [20, 135],
  [22, 78],
  [25, 20],
  [27, 55],
  [29, 45],
  [33, 30],
  [36, 27],
  [43, 89],
  [45, 37],
  [51, 30],
  [57, 29],
  [66, 12],
  [77, 50],
  [85, 22],
  [114, 6],
];

/// Hatim/okuma planları: oluşturma, ilerleme takibi ve günlük hatırlatma.
///
/// Birden fazla plan aynı anda var olabilir (bkz. [HatimPlani]). Kalıcılık
/// SharedPreferences üzerinde tek bir JSON liste olarak tutulur. Hatırlatma,
/// uygulamadaki diğer günlük bildirimlerle aynı şekilde AlarmManager'a tek
/// seferlik alarmlar olarak kaydedilir; sonsuz tekrar olmadığından pencere
/// periyodik olarak yeniden doldurulur (bkz. DailyContentNotificationService).
/// Her planın kendi alarm ID aralığı [_planAlarmBaseId] ile plan id'sinden
/// türetilir, böylece planların hatırlatmaları birbirini ezmez.
class HatimPlanService {
  static const String _planlarKey = 'hatim_planlari';
  static const String _eskiTekilPlanKey = 'hatim_plani'; // önceki sürüm
  static const int _hatirlaticiPencereGun = 14;

  static List<HatimPlani>? _planlar;

  static Future<List<HatimPlani>> tumPlanlar() async {
    if (_planlar != null) return _planlar!;
    await _yukle();
    return _planlar!;
  }

  static Future<HatimPlani?> planGetir(String id) async {
    final planlar = await tumPlanlar();
    for (final p in planlar) {
      if (p.id == id) return p;
    }
    return null;
  }

  static Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    final list = <HatimPlani>[];

    final jsonStr = prefs.getString(_planlarKey);
    if (jsonStr != null) {
      try {
        final decoded = jsonDecode(jsonStr) as List;
        for (final item in decoded) {
          try {
            list.add(HatimPlani.fromJson(item as Map<String, dynamic>));
          } catch (_) {
            // Bozuk bir kayıt varsa yalnızca o atlanır.
          }
        }
      } catch (_) {
        // Tüm liste bozuksa boş başlanır.
      }
    } else {
      // Eski (tek plan) formatından göç.
      final eskiJson = prefs.getString(_eskiTekilPlanKey);
      if (eskiJson != null) {
        try {
          list.add(
            HatimPlani.fromJson(jsonDecode(eskiJson) as Map<String, dynamic>),
          );
        } catch (_) {}
        await prefs.remove(_eskiTekilPlanKey);
      }
    }

    _planlar = list;
  }

  static Future<void> _kaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _planlarKey,
      jsonEncode(_planlar!.map((p) => p.toJson()).toList()),
    );
  }

  static String _yeniId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// Serbest plan oluşturur. [bitisTarihi] veya [gunlukSayfaHedefi]'nden en
  /// az biri verilmelidir; verilmeyen otomatik hesaplanır.
  static Future<HatimPlani> serbestPlanOlustur({
    required String ad,
    DateTime? baslangicTarihi,
    DateTime? bitisTarihi,
    int? gunlukSayfaHedefi,
    bool hatirlaticiAcik = true,
    String hatirlaticiSaati = '21:00',
  }) async {
    final baslangic = HatimPlani._saatsiz(baslangicTarihi ?? DateTime.now());

    int toplamGun;
    if (bitisTarihi != null) {
      toplamGun =
          HatimPlani._saatsiz(bitisTarihi).difference(baslangic).inDays + 1;
    } else if (gunlukSayfaHedefi != null && gunlukSayfaHedefi > 0) {
      toplamGun = (KuranVeriService.toplamSayfaSayisi / gunlukSayfaHedefi)
          .ceil();
    } else {
      toplamGun = 30;
    }
    if (toplamGun < 1) toplamGun = 1;

    final plan = HatimPlani(
      id: _yeniId(),
      ad: ad.trim().isEmpty ? 'Hatmim' : ad.trim(),
      turu: HatimPlanTuru.serbest,
      baslangicTarihi: baslangic,
      toplamGun: toplamGun,
      hatirlaticiAcik: hatirlaticiAcik,
      hatirlaticiSaati: hatirlaticiSaati,
    );
    await _planiEkle(plan);
    return plan;
  }

  /// Ramazan planı: sabit 30 gün, günde 1 cüz. Başlangıç verilmezse
  /// Ramazan'ın (Diyanet ile senkronize) tahmini başlangıcı kullanılır.
  static Future<HatimPlani> ramazanPlaniOlustur({
    required String ad,
    DateTime? baslangicTarihi,
    bool hatirlaticiAcik = true,
    String hatirlaticiSaati = '21:00',
  }) async {
    final baslangic = HatimPlani._saatsiz(
      baslangicTarihi ?? ramazanBaslangicTahmini() ?? DateTime.now(),
    );
    final plan = HatimPlani(
      id: _yeniId(),
      ad: ad.trim().isEmpty ? 'Ramazan Hatmim' : ad.trim(),
      turu: HatimPlanTuru.ramazan,
      baslangicTarihi: baslangic,
      toplamGun: 30,
      hatirlaticiAcik: hatirlaticiAcik,
      hatirlaticiSaati: hatirlaticiSaati,
    );
    await _planiEkle(plan);
    return plan;
  }

  static DateTime? ramazanBaslangicTahmini() {
    try {
      final yaklasanlar = OzelGunlerService.yaklasanOzelGunler();
      for (final m in yaklasanlar) {
        final ozelGun = m['ozelGun'];
        if (ozelGun != null && ozelGun.adKey == 'ramadan_start') {
          return m['tarih'] as DateTime;
        }
      }
    } catch (_) {
      // Hesaplanamazsa çağıran bugünü varsayılan alır.
    }
    return null;
  }

  static Future<void> _planiEkle(HatimPlani plan) async {
    final planlar = await tumPlanlar();
    _planlar = [...planlar, plan];
    await _kaydet();
    await _planinHatirlaticisiniZamanla(plan);
  }

  /// Planı adı/hatırlatma ayarı gibi alanlarıyla günceller.
  static Future<void> planiGuncelle(HatimPlani guncelPlan) async {
    final planlar = await tumPlanlar();
    _planlar = [
      for (final p in planlar) p.id == guncelPlan.id ? guncelPlan : p,
    ];
    await _kaydet();
  }

  /// Planı siler ve hatırlatmalarını iptal eder.
  static Future<void> planiSil(String id) async {
    final planlar = await tumPlanlar();
    _planlar = planlar.where((p) => p.id != id).toList();
    await _kaydet();
    await _planinHatirlaticilariniIptalEt(id);
  }

  /// Kullanıcı belirli bir plandan bir ayete kadar okuduğunda çağrılır (bkz.
  /// kuran_sayfa.dart "kaldığın yer" kaydı). Yalnızca ileriye gider; plan
  /// bulunamazsa hiçbir şey yapmaz.
  static Future<void> ilerlemeGuncelle(
    String hatimPlanId,
    int sureNo,
    int ayetNo,
  ) async {
    final plan = await planGetir(hatimPlanId);
    if (plan == null) return;

    final yeniGlobal = KuranVeriService.globalAyetNo(sureNo, ayetNo);
    final mevcutGlobal = plan.mevcutAyetNo == 0
        ? 0
        : KuranVeriService.globalAyetNo(plan.mevcutSureNo, plan.mevcutAyetNo);
    if (yeniGlobal <= mevcutGlobal) return;

    await planiGuncelle(
      plan.kopyala(mevcutSureNo: sureNo, mevcutAyetNo: ayetNo),
    );
  }

  /// Verilen tarihte (varsayılan: bugün) ulaşılması gereken hedef.
  static HatimGunlukHedef gunlukHedef(HatimPlani plan, [DateTime? tarih]) {
    final gunIndex = plan.gunIndex(tarih).clamp(0, plan.toplamGun - 1);

    if (plan.turu == HatimPlanTuru.ramazan) {
      final cuzNo = (gunIndex + 1).clamp(1, _cuzSonlari.length);
      final sonAyet = _cuzSonlari[cuzNo - 1];
      return HatimGunlukHedef(
        gunNo: gunIndex + 1,
        etiket: '$cuzNo. Cüz',
        hedefSureNo: sonAyet[0],
        hedefAyetNo: sonAyet[1],
      );
    }

    final toplamSayfa = KuranVeriService.toplamSayfaSayisi;
    final hedefSayfa = (((gunIndex + 1) * toplamSayfa) / plan.toplamGun)
        .ceil()
        .clamp(1, toplamSayfa);

    final List<int> hedefSureAyet;
    if (hedefSayfa >= toplamSayfa) {
      hedefSureAyet = const [114, 6];
    } else {
      final sonrakiBaslangic = KuranVeriService.sayfaBaslangici(hedefSayfa + 1);
      hedefSureAyet = _birOncekiAyet(sonrakiBaslangic[0], sonrakiBaslangic[1]);
    }

    return HatimGunlukHedef(
      gunNo: gunIndex + 1,
      etiket: '$hedefSayfa. Sayfa',
      hedefSureNo: hedefSureAyet[0],
      hedefAyetNo: hedefSureAyet[1],
    );
  }

  static List<int> _birOncekiAyet(int sureNo, int ayetNo) {
    if (ayetNo > 1) return [sureNo, ayetNo - 1];
    if (sureNo > 1) {
      final oncekiSure = sureNo - 1;
      return [oncekiSure, KuranVeriService.ayetSayilari[oncekiSure - 1]];
    }
    return const [1, 1];
  }

  // ---------------- Hatırlatma bildirimi ----------------

  /// Bir planın hatırlatma açık/kapalı ve saat ayarını değiştirir.
  static Future<void> planHatirlaticisiniAyarla(
    String planId, {
    bool? acik,
    String? saat,
  }) async {
    final plan = await planGetir(planId);
    if (plan == null) return;

    final guncel = plan.kopyala(hatirlaticiAcik: acik, hatirlaticiSaati: saat);
    await planiGuncelle(guncel);
    await _planinHatirlaticisiniZamanla(guncel);
  }

  /// Plan id'sinden çakışma ihtimali düşük, deterministik bir alarm ID
  /// aralığı türetir. Pencere [_hatirlaticiPencereGun] olduğundan aralıklar
  /// arasında en az bu kadar boşluk bırakılır.
  static int _planAlarmBaseId(String planId) =>
      5000 + (planId.hashCode.abs() % 400) * 20;

  /// Bir planın hatırlatmalarını [_hatirlaticiPencereGun] gün ötesine kadar
  /// yeniden zamanlar. Plan oluşturma/güncelleme sırasında otomatik çağrılır.
  static Future<void> _planinHatirlaticisiniZamanla(HatimPlani plan) async {
    await _planinHatirlaticilariniIptalEt(plan.id);
    if (!plan.hatirlaticiAcik) return;

    final saatParcalari = plan.hatirlaticiSaati.split(':');
    final saat = saatParcalari.isNotEmpty
        ? int.tryParse(saatParcalari[0]) ?? 21
        : 21;
    final dakika = saatParcalari.length > 1
        ? int.tryParse(saatParcalari[1]) ?? 0
        : 0;

    final languageService = LanguageService();
    await languageService.load();
    final baslikOneki =
        languageService['hatim_reminder_title'] ?? 'Hatim Planı Hatırlatması';
    final govdeOneki =
        languageService['hatim_reminder_body'] ??
        'okuma sıran geldi, kaldığın yerden devam et!';

    final baseId = _planAlarmBaseId(plan.id);
    final simdi = DateTime.now();
    for (
      int gun = 0;
      gun < _hatirlaticiPencereGun && gun < plan.toplamGun;
      gun++
    ) {
      final hedefTarih = plan.baslangicTarihi.add(Duration(days: gun));
      final tetiklenmeZamani = DateTime(
        hedefTarih.year,
        hedefTarih.month,
        hedefTarih.day,
        saat,
        dakika,
      );
      if (!tetiklenmeZamani.isAfter(simdi)) continue;

      final hedef = gunlukHedef(plan, hedefTarih);

      await AlarmService.scheduleDailyContentAlarm(
        notificationId: baseId + gun,
        title: '${plan.ad} — $baslikOneki',
        body: '${hedef.etiket}: $govdeOneki',
        triggerAtMillis: tetiklenmeZamani.millisecondsSinceEpoch,
        soundFile: 'best',
      );
    }
  }

  static Future<void> _planinHatirlaticilariniIptalEt(String planId) async {
    final baseId = _planAlarmBaseId(planId);
    for (int gun = 0; gun < _hatirlaticiPencereGun; gun++) {
      await AlarmService.cancelDailyContentAlarm(baseId + gun);
    }
  }

  /// Uygulama açılışında tüm planların hatırlatma pencerelerini yeniden
  /// doldurur (AlarmManager'da sonsuz tekrar olmadığından gereklidir, bkz.
  /// DailyContentNotificationService).
  static Future<void> tumHatirlaticilariYenidenZamanla() async {
    final planlar = await tumPlanlar();
    for (final plan in planlar) {
      await _planinHatirlaticisiniZamanla(plan);
    }
  }
}
