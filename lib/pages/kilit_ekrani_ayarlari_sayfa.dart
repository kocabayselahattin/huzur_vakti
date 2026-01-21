import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';
import '../services/konum_service.dart';
import '../services/diyanet_api_service.dart';
import '../services/home_widget_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class KilitEkraniAyarlariSayfa extends StatefulWidget {
  const KilitEkraniAyarlariSayfa({super.key});

  @override
  State<KilitEkraniAyarlariSayfa> createState() =>
      _KilitEkraniAyarlariSayfaState();
}

class _KilitEkraniAyarlariSayfaState extends State<KilitEkraniAyarlariSayfa> {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Native servis için method channel
  static const _lockScreenChannel = MethodChannel('huzur_vakti/lockscreen');

  bool _kilitEkraniBildirimiAktif = false;
  bool _ecirBariGoster = true;
  int _secilenStilIndex = 0;
  bool _yukleniyor = true;

  // Stil seçenekleri
  final List<Map<String, dynamic>> _stilSecenekleri = [
    {
      'isim': 'Kompakt',
      'key': 'compact',
      'aciklama': 'Sonraki vakit ve geri sayım',
      'icon': Icons.view_compact,
    },
    {
      'isim': 'Detaylı',
      'key': 'detailed',
      'aciklama': 'Tüm vakitler ve tarih',
      'icon': Icons.view_list,
    },
    {
      'isim': 'Minimal',
      'key': 'minimal',
      'aciklama': 'Sadece sonraki vakit',
      'icon': Icons.minimize,
    },
    {
      'isim': 'Tam Vakit',
      'key': 'full',
      'aciklama': '6 vakit saati ile',
      'icon': Icons.calendar_view_day,
    },
  ];

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onChanged);
    _languageService.addListener(_onChanged);
    _ayarlariYukle();
  }

  @override
  void dispose() {
    _temaService.removeListener(_onChanged);
    _languageService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _kilitEkraniBildirimiAktif =
          prefs.getBool('kilit_ekrani_bildirimi_aktif') ?? false;
      _ecirBariGoster = prefs.getBool('kilit_ekrani_ecir_bari') ?? true;
      final stilKey = prefs.getString('kilit_ekrani_stili') ?? 'compact';
      _secilenStilIndex = _stilSecenekleri.indexWhere(
        (s) => s['key'] == stilKey,
      );
      if (_secilenStilIndex < 0) _secilenStilIndex = 0;
      _yukleniyor = false;
    });

    // Aktifse bildirimi güncelle
    if (_kilitEkraniBildirimiAktif) {
      _bildirimiGuncelle();
    }
  }

  Future<void> _ayarlariKayDet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      'kilit_ekrani_bildirimi_aktif',
      _kilitEkraniBildirimiAktif,
    );
    await prefs.setBool('kilit_ekrani_ecir_bari', _ecirBariGoster);
    await prefs.setString(
      'kilit_ekrani_stili',
      _stilSecenekleri[_secilenStilIndex]['key'],
    );

    if (_kilitEkraniBildirimiAktif) {
      await _bildirimiGuncelle();
    } else {
      await _bildirimiKapat();
    }
  }

  Future<void> _bildirimiGuncelle() async {
    try {
      // Önce widget verilerini güncelle (native servis bunları kullanacak)
      await HomeWidgetService.updateAllWidgets();
      
      // Native kilit ekranı servisini başlat
      await _lockScreenChannel.invokeMethod('startLockScreenService');
      
      debugPrint('✅ Kilit ekranı bildirimi servisi başlatıldı');
    } catch (e) {
      debugPrint('❌ Kilit ekranı bildirimi hatası: $e');
      _uyariGoster('Kilit ekranı bildirimi başlatılamadı');
    }
  }

  Future<void> _bildirimiKapat() async {
    try {
      // Native servisi durdur
      await _lockScreenChannel.invokeMethod('stopLockScreenService');
      // Eski bildirimi de kapat (varsa)
      await _notificationsPlugin.cancel(9999);
      debugPrint('✅ Kilit ekranı bildirimi kapatıldı');
    } catch (e) {
      debugPrint('❌ Kilit ekranı bildirimi kapatma hatası: $e');
    }
  }

  String _olustrBaslik(String stilKey, String? il, String? ilce) {
    final konum = il != null && ilce != null ? '$il / $ilce' : (il ?? 'Konum');
    switch (stilKey) {
      case 'minimal':
        return _languageService['next_prayer'] ?? 'Sonraki Vakit';
      case 'detailed':
      case 'full':
        return '📍 $konum';
      default:
        return '🕌 ${_languageService['app_name'] ?? 'Huzur Vakti'}';
    }
  }

  String _olusturIcerik(String stilKey, Map<String, dynamic> vakitler) {
    final imsak = vakitler['Imsak'] ?? '-';
    final gunes = vakitler['Gunes'] ?? '-';
    final ogle = vakitler['Ogle'] ?? '-';
    final ikindi = vakitler['Ikindi'] ?? '-';
    final aksam = vakitler['Aksam'] ?? '-';
    final yatsi = vakitler['Yatsi'] ?? '-';

    // Sonraki vakti hesapla
    final now = DateTime.now();
    final vakitMap = {
      _languageService['imsak'] ?? 'İmsak': imsak,
      _languageService['gunes'] ?? 'Güneş': gunes,
      _languageService['ogle'] ?? 'Öğle': ogle,
      _languageService['ikindi'] ?? 'İkindi': ikindi,
      _languageService['aksam'] ?? 'Akşam': aksam,
      _languageService['yatsi'] ?? 'Yatsı': yatsi,
    };

    String sonrakiVakit = '';
    String sonrakiSaat = '';

    for (final entry in vakitMap.entries) {
      final parts = entry.value.split(':');
      if (parts.length == 2) {
        final saat = int.tryParse(parts[0]) ?? 0;
        final dakika = int.tryParse(parts[1]) ?? 0;
        final vakitZamani = DateTime(
          now.year,
          now.month,
          now.day,
          saat,
          dakika,
        );
        if (vakitZamani.isAfter(now)) {
          sonrakiVakit = entry.key;
          sonrakiSaat = entry.value;
          break;
        }
      }
    }

    if (sonrakiVakit.isEmpty) {
      sonrakiVakit = _languageService['imsak'] ?? 'İmsak';
      sonrakiSaat = imsak;
    }

    final kalanSure = _hesaplaKalanSure(sonrakiSaat);

    switch (stilKey) {
      case 'minimal':
        return '$sonrakiVakit: $sonrakiSaat ($kalanSure ${_languageService['remaining'] ?? 'kaldı'})';
      case 'compact':
        return '⏰ $sonrakiVakit $sonrakiSaat\n⏳ $kalanSure ${_languageService['remaining'] ?? 'kaldı'}';
      case 'detailed':
        return '⏰ $sonrakiVakit: $sonrakiSaat ($kalanSure)\n'
            '🌅 ${_languageService['imsak'] ?? 'İmsak'}: $imsak  ☀️ ${_languageService['gunes'] ?? 'Güneş'}: $gunes\n'
            '🌤️ ${_languageService['ogle'] ?? 'Öğle'}: $ogle  🌇 ${_languageService['ikindi'] ?? 'İkindi'}: $ikindi\n'
            '🌆 ${_languageService['aksam'] ?? 'Akşam'}: $aksam  🌙 ${_languageService['yatsi'] ?? 'Yatsı'}: $yatsi';
      case 'full':
        return '⏰ Sonraki: $sonrakiVakit $sonrakiSaat ($kalanSure)\n'
            '${_languageService['imsak'] ?? 'İmsak'}: $imsak | ${_languageService['gunes'] ?? 'Güneş'}: $gunes | ${_languageService['ogle'] ?? 'Öğle'}: $ogle\n'
            '${_languageService['ikindi'] ?? 'İkindi'}: $ikindi | ${_languageService['aksam'] ?? 'Akşam'}: $aksam | ${_languageService['yatsi'] ?? 'Yatsı'}: $yatsi';
      default:
        return '$sonrakiVakit: $sonrakiSaat ($kalanSure)';
    }
  }

  String _hesaplaKalanSure(String hedefSaat) {
    final parts = hedefSaat.split(':');
    if (parts.length != 2) return '-';

    final now = DateTime.now();
    final hedef = DateTime(
      now.year,
      now.month,
      now.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts[1]) ?? 0,
    );

    var fark = hedef.difference(now);
    if (fark.isNegative) {
      // Yarına
      fark = hedef.add(const Duration(days: 1)).difference(now);
    }

    final saat = fark.inHours;
    final dakika = fark.inMinutes % 60;

    if (saat > 0) {
      return '$saat ${_languageService['hour_short'] ?? 'sa'} $dakika ${_languageService['minute_short'] ?? 'dk'}';
    }
    return '$dakika ${_languageService['minute_short'] ?? 'dk'}';
  }

  void _uyariGoster(String mesaj) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    if (_yukleniyor) {
      return Scaffold(
        backgroundColor: renkler.arkaPlan,
        appBar: AppBar(
          title: Text(
            _languageService['lock_screen_widget'] ?? 'Kilit Ekranı Widget',
            style: TextStyle(color: renkler.yaziPrimary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: renkler.yaziPrimary),
        ),
        body: Center(child: CircularProgressIndicator(color: renkler.vurgu)),
      );
    }

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text(
          _languageService['lock_screen_widget'] ?? 'Kilit Ekranı Widget',
          style: TextStyle(color: renkler.yaziPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Açıklama kartı
          _bilgiKarti(renkler),
          const SizedBox(height: 20),

          // Ana anahtar
          _anaAyarKarti(renkler),
          const SizedBox(height: 20),

          // Önizleme (hemen ana ayarın altında)
          if (_kilitEkraniBildirimiAktif) ...[
            _onizlemeKarti(renkler),
            const SizedBox(height: 20),

            // Stil seçimi
            _stilSecimKarti(renkler),
          ],
        ],
      ),
    );
  }

  Widget _bilgiKarti(TemaRenkleri renkler) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renkler.vurgu.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renkler.vurgu.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: renkler.vurgu, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _languageService['lock_screen_widget_info'] ??
                  'Kilit ekranında sürekli olarak namaz vakitlerini gösteren bir bildirim oluşturur. Telefonunuzu açmadan vakitleri görebilirsiniz.',
              style: TextStyle(color: renkler.yaziPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _anaAyarKarti(TemaRenkleri renkler) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kilitEkraniBildirimiAktif
                  ? renkler.vurgu.withValues(alpha: 0.15)
                  : renkler.arkaPlan,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lock_clock,
              color: _kilitEkraniBildirimiAktif
                  ? renkler.vurgu
                  : renkler.yaziSecondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _languageService['lock_screen_notification'] ??
                      'Kilit Ekranı Bildirimi',
                  style: TextStyle(
                    color: renkler.yaziPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _kilitEkraniBildirimiAktif
                      ? (_languageService['active'] ?? 'Aktif')
                      : (_languageService['inactive'] ?? 'Kapalı'),
                  style: TextStyle(
                    color: _kilitEkraniBildirimiAktif
                        ? renkler.vurgu
                        : renkler.yaziSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _kilitEkraniBildirimiAktif,
            onChanged: (value) {
              setState(() {
                _kilitEkraniBildirimiAktif = value;
              });
              _ayarlariKayDet();
            },
            activeColor: renkler.vurgu,
          ),
        ],
      ),
    );
  }

  Widget _stilSecimKarti(TemaRenkleri renkler) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _languageService['notification_style'] ?? 'Bildirim Stili',
            style: TextStyle(
              color: renkler.yaziPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_stilSecenekleri.length, (index) {
            final stil = _stilSecenekleri[index];
            final secili = index == _secilenStilIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _secilenStilIndex = index;
                });
                _ayarlariKayDet();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: secili
                      ? renkler.vurgu.withValues(alpha: 0.15)
                      : renkler.arkaPlan,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: secili
                        ? renkler.vurgu
                        : renkler.ayirac.withValues(alpha: 0.3),
                    width: secili ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      stil['icon'] as IconData,
                      color: secili ? renkler.vurgu : renkler.yaziSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stil['isim'] as String,
                            style: TextStyle(
                              color: renkler.yaziPrimary,
                              fontWeight: secili
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          Text(
                            stil['aciklama'] as String,
                            style: TextStyle(
                              color: renkler.yaziSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (secili) Icon(Icons.check_circle, color: renkler.vurgu),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _ecirBariKarti(TemaRenkleri renkler) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: renkler.vurgu),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _languageService['reward_bar'] ?? 'Ecir Barı',
                  style: TextStyle(
                    color: renkler.yaziPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _languageService['reward_bar_desc'] ??
                      'Detaylı bildirim içeriği göster',
                  style: TextStyle(color: renkler.yaziSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: _ecirBariGoster,
            onChanged: (value) {
              setState(() {
                _ecirBariGoster = value;
              });
              _ayarlariKayDet();
            },
            activeColor: renkler.vurgu,
          ),
        ],
      ),
    );
  }

  Widget _buildEcirBar(double progress, TemaRenkleri renkler) {
    Color calculateColor(double progress) {
      if (progress > 0.5) {
        return Color.lerp(Colors.green, Colors.yellow, 1 - progress)!;
      } else {
        return Color.lerp(Colors.yellow, Colors.red, 1 - progress)!;
      }
    }

    return Container(
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        gradient: LinearGradient(
          colors: [calculateColor(progress), calculateColor(progress * 0.8)],
        ),
      ),
    );
  }

  Widget _onizlemeKarti(TemaRenkleri renkler) {
    final stilKey = _stilSecenekleri[_secilenStilIndex]['key'] as String;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _languageService['preview'] ?? 'Önizleme',
            style: TextStyle(
              color: renkler.yaziPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Stil bazlı önizleme
          _buildStilOnizleme(stilKey),
        ],
      ),
    );
  }

  Widget _buildStilOnizleme(String stilKey) {
    switch (stilKey) {
      case 'compact':
        return _buildCompactOnizleme();
      case 'detailed':
        return _buildDetailedOnizleme();
      case 'minimal':
        return _buildMinimalOnizleme();
      case 'full':
        return _buildFullOnizleme();
      default:
        return _buildCompactOnizleme();
    }
  }

  // Kompakt Stil Önizleme
  Widget _buildCompactOnizleme() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst: Başlık satırı
          Row(
            children: [
              Image.asset('assets/icon/app_icon.png', width: 18, height: 18),
              const SizedBox(width: 6),
              const Text(
                'Huzur Vakti',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                'İstanbul',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Sol: Vakit bilgisi
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sonraki Vakit',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                  ),
                  const Text(
                    'İKİNDİ',
                    style: TextStyle(color: Color(0xFFFF7043), fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Text('15:52', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
              const Spacer(),
              // Sağ: Geri sayım kutusu
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2F4F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3D4266)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Kalan Süre',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9),
                    ),
                    const Text(
                      '2s 34dk',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Detaylı Stil Önizleme
  Widget _buildDetailedOnizleme() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır
          Row(
            children: [
              Image.asset('assets/icon/app_icon.png', width: 18, height: 18),
              const SizedBox(width: 6),
              const Text('Huzur Vakti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              Text('İstanbul', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          // Geri sayım
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('İKİNDİ', style: TextStyle(color: Color(0xFFFF7043), fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Text('vaktine', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                      ],
                    ),
                    const Text('2 saat 34 dakika', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              const Text('15:52', style: TextStyle(color: Color(0xFFFF7043), fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF3D4266),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.6,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF7043), Color(0xFFFF5722)]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Tüm vakitler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _vakitMini('İmsak', '05:30', false),
              _vakitMini('Güneş', '07:00', false),
              _vakitMini('Öğle', '12:30', false),
              _vakitMini('İkindi', '15:30', true),
              _vakitMini('Akşam', '18:00', false),
              _vakitMini('Yatsı', '19:30', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vakitMini(String isim, String saat, bool aktif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: aktif 
          ? BoxDecoration(color: const Color(0xFFFF7043), borderRadius: BorderRadius.circular(4))
          : null,
      child: Column(
        children: [
          Text(isim, style: TextStyle(color: aktif ? Colors.black : Colors.white.withOpacity(0.5), fontSize: 8)),
          Text(saat, style: TextStyle(color: aktif ? Colors.black : Colors.white, fontSize: 10, fontWeight: aktif ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // Minimal Stil Önizleme
  Widget _buildMinimalOnizleme() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset('assets/icon/app_icon.png', width: 16, height: 16),
                    const SizedBox(width: 6),
                    const Text('İKİNDİ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    const Text('15:52', style: TextStyle(color: Color(0xFFFF7043), fontSize: 13)),
                  ],
                ),
                Text('İstanbul', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              ],
            ),
          ),
          const Text(
            '2:34',
            style: TextStyle(color: Color(0xFFFF7043), fontWeight: FontWeight.bold, fontSize: 26),
          ),
        ],
      ),
    );
  }

  // Tam Vakit Stil Önizleme
  Widget _buildFullOnizleme() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst satır
          Row(
            children: [
              Image.asset('assets/icon/app_icon.png', width: 18, height: 18),
              const SizedBox(width: 6),
              const Text('Huzur Vakti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              const Text('28 Recep 1447', style: TextStyle(color: Color(0xFFFF7043), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('📍 İstanbul', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
              const Spacer(),
              Text('21 Ocak 2026', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          // Geri sayım kutusu
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2F4F),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3D4266)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sonraki Vakit', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                      Row(
                        children: [
                          const Text('İKİNDİ', style: TextStyle(color: Color(0xFFFF7043), fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(width: 12),
                          const Text('15:52', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Kalan', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
                    const Text('2:34:21', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, fontFamily: 'monospace')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Grid vakitler
          Row(
            children: [
              Expanded(child: _vakitSatir('🌙', 'İmsak', '05:30', false)),
              Expanded(child: _vakitSatir('🌤️', 'İkindi', '15:30', true)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _vakitSatir('🌅', 'Güneş', '07:00', false)),
              Expanded(child: _vakitSatir('🌆', 'Akşam', '18:00', false)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _vakitSatir('☀️', 'Öğle', '12:30', false)),
              Expanded(child: _vakitSatir('🌙', 'Yatsı', '19:30', false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vakitSatir(String emoji, String isim, String saat, bool aktif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: aktif 
          ? BoxDecoration(color: const Color(0xFFFF7043), borderRadius: BorderRadius.circular(6))
          : null,
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(isim, style: TextStyle(color: aktif ? Colors.black : Colors.white.withOpacity(0.6), fontSize: 10)),
          const Spacer(),
          Text(saat, style: TextStyle(color: aktif ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  DateTime _getNextPrayerTime() {
    // Logic to calculate the next prayer time dynamically
    final now = DateTime.now();
    final prayerTimes = [
      DateTime(now.year, now.month, now.day, 5, 30), // Example times
      DateTime(now.year, now.month, now.day, 12, 30),
      DateTime(now.year, now.month, now.day, 15, 30),
      DateTime(now.year, now.month, now.day, 18, 0),
      DateTime(now.year, now.month, now.day, 19, 30),
    ];

    for (final time in prayerTimes) {
      if (time.isAfter(now)) {
        return time;
      }
    }

    // If no future prayer times, return the first prayer time of the next day
    return prayerTimes.first.add(const Duration(days: 1));
  }
}
