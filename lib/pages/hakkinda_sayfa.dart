import 'package:flutter/material.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';

class HakkindaSayfa extends StatefulWidget {
  const HakkindaSayfa({super.key});

  @override
  State<HakkindaSayfa> createState() => _HakkindaSayfaState();
}

class _HakkindaSayfaState extends State<HakkindaSayfa> {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onTemaChanged);
    _languageService.addListener(_onTemaChanged);
  }

  @override
  void dispose() {
    _temaService.removeListener(_onTemaChanged);
    _languageService.removeListener(_onTemaChanged);
    super.dispose();
  }

  void _onTemaChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: renkler.vurgu,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _languageService['about'] ?? 'Hakkında',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      renkler.vurgu,
                      renkler.vurgu.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // İçerik
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Uygulama Logosu ve Adı
                  _uygulamaBilgisi(renkler),
                  const SizedBox(height: 24),

                  // Açıklama
                  _baslikVeMetin(
                    _languageService['what_is_huzur_vakti'] ?? 'Huzur Vakti Nedir?',
                    _languageService['about_desc'] ?? 'Huzur Vakti, namaz vakitlerini takip etmenizi sağlayan bir uygulamadır.',
                    renkler,
                  ),
                  const SizedBox(height: 24),

                  // Özellikler
                  _ozelliklerBolumu(renkler),
                  const SizedBox(height: 24),

                  // Önemli Bilgiler
                  _onemliNotlar(renkler),
                  const SizedBox(height: 24),

                  // İletişim
                  _iletisimBolumu(renkler),
                  const SizedBox(height: 24),

                  // Versiyon ve Telif
                  _altBilgi(renkler),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uygulamaBilgisi(TemaRenkleri renkler) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            renkler.vurgu.withValues(alpha: 0.2),
            renkler.vurgu.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renkler.vurgu.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: renkler.vurgu,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _languageService['app_name'] ?? 'Huzur Vakti',
            style: TextStyle(
              color: renkler.yaziPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _languageService['prayer_times_assistant'] ??
                'Namaz Vakitleri ve İbadet Asistanı',
            style: TextStyle(color: renkler.yaziSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${_languageService['version'] ?? 'Versiyon'} 2.2.0',
            style: TextStyle(
              color: renkler.yaziSecondary.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _baslikVeMetin(String baslik, String metin, TemaRenkleri renkler) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: TextStyle(
            color: renkler.yaziPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          metin,
          style: TextStyle(
            color: renkler.yaziSecondary,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _ozelliklerBolumu(TemaRenkleri renkler) {
    final ozellikler = [
      // 🔔 BİLDİRİM VE ALARM
      {
        'ikon': Icons.alarm,
        'renk': Colors.red,
        'baslik': _languageService['feature_smart_alarm'] ?? 'Akıllı Alarm Sistemi',
        'aciklama': _languageService['feature_smart_alarm_desc'] ?? '14 günlük zamanlama, ses/kilit tuşu ile durdurma, sessiz modda sadece titreşim, kilit ekranında bildirim',
      },
      {
        'ikon': Icons.notifications_active,
        'renk': Colors.orange,
        'baslik': _languageService['feature_custom_notifications'] ?? 'Özelleştirilebilir Bildirimler',
        'aciklama': _languageService['feature_custom_notifications_desc'] ?? 'Her vakit için ayrı ses seçimi, erken hatırlatma (1-60 dk önce), özel ses dosyası yükleme desteği',
      },
      {
        'ikon': Icons.do_not_disturb_on,
        'renk': Colors.purple,
        'baslik': _languageService['feature_auto_silent'] ?? 'Otomatik Sessiz Mod',
        'aciklama': _languageService['feature_auto_silent_desc'] ?? 'Namaz vakitlerinde telefonu otomatik sessize alır (Cuma 60dk, diğer günler 30dk)',
      },
      
      // 📍 KONUM VE VAKİT
      {
        'ikon': Icons.location_city,
        'renk': Colors.blue,
        'baslik': _languageService['feature_multiple_locations'] ?? 'Çoklu Konum Desteği',
        'aciklama': _languageService['feature_multiple_locations_desc'] ?? 'Birden fazla konum ekleyin ve aralarında kolayca geçiş yapın',
      },
      {
        'ikon': Icons.location_on,
        'renk': Colors.teal,
        'baslik': _languageService['feature_location_based'] ?? 'GPS ile Otomatik Konum',
        'aciklama': _languageService['feature_location_based_desc'] ?? 'Konumunuzu otomatik tespit eder, Diyanet İşleri Başkanlığı verileriyle en doğru vakitleri sunar',
      },
      {
        'ikon': Icons.calendar_month,
        'renk': Colors.green,
        'baslik': _languageService['feature_imsakiye'] ?? 'İmsakiye',
        'aciklama': _languageService['feature_imsakiye_desc'] ?? 'Aylık vakit tablosu, yenile butonu ile anlık güncelleme',
      },
      
      // 📱 WİDGET
      {
        'ikon': Icons.widgets,
        'renk': Colors.pink,
        'baslik': _languageService['feature_widgets'] ?? '8 Farklı Widget',
        'aciklama': _languageService['feature_widgets_desc'] ?? 'Klasik, Mini, Glassmorphism, Neon, Cosmic, Timeline, Zen, Origami - uygulama kapalıyken bile çalışır',
      },
      {
        'ikon': Icons.lock_open,
        'renk': Colors.indigo,
        'baslik': _languageService['feature_auto_widget_update'] ?? 'Otomatik Widget Güncelleme',
        'aciklama': _languageService['feature_auto_widget_update_desc'] ?? 'Ekran kilidi açıldığında ve her dakika otomatik güncellenir',
      },
      
      // 📖 İBADET REHBERİ
      {
        'ikon': Icons.menu_book,
        'renk': Colors.deepOrange,
        'baslik': _languageService['feature_prayer_duas'] ?? 'Namazda Okunan Dualar',
        'aciklama': _languageService['feature_prayer_duas_desc'] ?? 'Sübhaneke, Fatiha, Tahiyyat, Salavat ve tüm namaz duaları Arapça metin ve okunuşlarıyla',
      },
      {
        'ikon': Icons.checklist,
        'renk': Colors.brown,
        'baslik': _languageService['feature_farz'] ?? '32 ve 54 Farz',
        'aciklama': _languageService['feature_farz_desc'] ?? 'İslam\'ın tüm farzları detaylı açıklamalarıyla',
      },
      {
        'ikon': Icons.book,
        'renk': Colors.amber,
        'baslik': _languageService['feature_quran'] ?? 'Kur\'an-ı Kerim',
        'aciklama': _languageService['feature_quran_desc'] ?? '114 sure, Arapça metin, okunuş ve meal',
      },
      {
        'ikon': Icons.library_books,
        'renk': Colors.teal,
        'baslik': _languageService['feature_forty_hadiths'] ?? '40 Hadis-i Şerif',
        'aciklama': _languageService['feature_forty_hadiths_desc'] ?? 'Peygamber Efendimiz (S.A.V)\'in hadislerinden seçilmiş 40 hadis koleksiyonu',
      },
      {
        'ikon': Icons.star,
        'renk': Colors.yellow,
        'baslik': _languageService['feature_esmaul_husna'] ?? 'Esmaül Hüsna',
        'aciklama': _languageService['feature_esmaul_husna_desc'] ?? 'Allah\'ın 99 güzel ismi, anlamları ve günün esması özelliği',
      },
      {
        'ikon': Icons.brightness_3,
        'renk': Colors.deepPurple,
        'baslik': _languageService['feature_special_days'] ?? 'Özel Gün ve Geceler',
        'aciklama': _languageService['feature_special_days_desc'] ?? 'Kandil geceleri, bayramlar, mübarek günler hakkında detaylı bilgi ve hatırlatmalar',
      },
      
      // 📿 ZİKİR
      {
        'ikon': Icons.blur_circular,
        'renk': Colors.cyan,
        'baslik': _languageService['feature_dhikr_counter'] ?? 'Zikir Matik',
        'aciklama': _languageService['feature_dhikr_counter_desc'] ?? 'Dijital tesbih, sayacı ile zikirlerinizi takip edin, titreşim geri bildirimi',
      },
      {
        'ikon': Icons.add_circle,
        'renk': Colors.lightBlue,
        'baslik': _languageService['feature_custom_dhikr'] ?? 'Özel Zikir Ekleme',
        'aciklama': _languageService['feature_custom_dhikr_desc'] ?? 'Kendi zikirlerinizi ekleyin, düzenleyin ve silin',
      },
      
      // 🧭 KIBLE VE CAMİ
      {
        'ikon': Icons.explore,
        'renk': Colors.green,
        'baslik': _languageService['feature_qibla'] ?? 'Kıble Pusulası',
        'aciklama': _languageService['feature_qibla_desc'] ?? 'Manyetik pusula ile Kıble yönünü kolayca bulun',
      },
      {
        'ikon': Icons.mosque,
        'renk': Colors.lightGreen,
        'baslik': _languageService['feature_nearby_mosques'] ?? 'Yakındaki Camiler',
        'aciklama': _languageService['feature_nearby_mosques_desc'] ?? 'OpenStreetMap ile 2km yarıçapta camileri görüntüleyin',
      },
      
      // 🌐 DİL VE TEMA
      {
        'ikon': Icons.language,
        'renk': Colors.blueGrey,
        'baslik': _languageService['feature_languages'] ?? '6 Dil Desteği',
        'aciklama': _languageService['feature_languages_desc'] ?? 'Türkçe, İngilizce, Almanca, Fransızca, Arapça ve Farsça',
      },
      {
        'ikon': Icons.palette,
        'renk': Colors.pinkAccent,
        'baslik': _languageService['feature_themes'] ?? '13 Premium Tema',
        'aciklama': _languageService['feature_themes_desc'] ?? 'Her sayaç için özel tema veya kendi renk seçiminiz',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _languageService['features'] ?? 'Özellikler',
          style: TextStyle(
            color: renkler.yaziPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...ozellikler.map(
          (ozellik) => _ozellikKarti(
            renkler,
            ozellik['ikon'] as IconData,
            ozellik['renk'] as Color,
            ozellik['baslik'] as String,
            ozellik['aciklama'] as String,
          ),
        ),
      ],
    );
  }

  Widget _ozellikKarti(
    TemaRenkleri renkler,
    IconData ikon,
    Color renk,
    String baslik,
    String aciklama,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renkler.ayirac.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, color: renk, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: TextStyle(
                    color: renkler.yaziPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aciklama,
                  style: TextStyle(
                    color: renkler.yaziSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _onemliNotlar(TemaRenkleri renkler) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[700], size: 24),
              const SizedBox(width: 12),
              Text(
                _languageService['important_info'] ?? 'Önemli Bilgiler',
                style: TextStyle(
                  color: renkler.yaziPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _notSatiri(
            '• ${_languageService['diyanet_data_note'] ?? 'Vakit hesaplamaları Diyanet İşleri Başkanlığı verilerine göre yapılmaktadır.'}',
            renkler,
          ),
          _notSatiri(
            '• ${_languageService['battery_optimization_note'] ?? 'Bildirimlerin düzgün çalışması için pil optimizasyonu izinlerini ayarlamanız önerilir.'}',
            renkler,
          ),
          _notSatiri(
            '• ${_languageService['location_permission_note'] ?? 'Konum izni verilmediğinde manuel şehir seçimi yapmanız gerekmektedir.'}',
            renkler,
          ),
          _notSatiri(
            '• ${_languageService['internet_note'] ?? 'İnternet bağlantısı sadece ilk kurulumda ve konum güncellemelerinde gereklidir.'}',
            renkler,
          ),
        ],
      ),
    );
  }

  Widget _notSatiri(String metin, TemaRenkleri renkler) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        metin,
        style: TextStyle(
          color: renkler.yaziSecondary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _iletisimBolumu(TemaRenkleri renkler) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _languageService['contact_support'] ?? 'İletişim ve Destek',
            style: TextStyle(
              color: renkler.yaziPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _iletisimSatiri(
            Icons.email,
            _languageService['email'] ?? 'E-posta',
            ' ',
            renkler,
          ),
          _iletisimSatiri(
            Icons.web,
            _languageService['web'] ?? 'Web',
            ' ',
            renkler,
          ),
          _iletisimSatiri(
            Icons.bug_report,
            _languageService['bug_report'] ?? 'Hata Bildirimi',
            ' ',
            renkler,
          ),
        ],
      ),
    );
  }

  Widget _iletisimSatiri(
    IconData ikon,
    String baslik,
    String deger,
    TemaRenkleri renkler,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(ikon, color: renkler.vurgu, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: TextStyle(color: renkler.yaziSecondary, fontSize: 12),
                ),
                Text(
                  deger,
                  style: TextStyle(color: renkler.yaziPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _altBilgi(TemaRenkleri renkler) {
    return Column(
      children: [
        Divider(color: renkler.ayirac),
        const SizedBox(height: 16),

        // Play Store düğmesi
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () {
              // Play Store linki (şimdilik devre dışı)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _languageService['coming_soon_playstore'] ??
                        'Yakında Play Store\'da!',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.shop, size: 20),
            label: Text(
              _languageService['rate_on_playstore'] ??
                  'Play Store\'da Değerlendir',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),
        Text(
          '© 2026 ${_languageService['app_name'] ?? 'Huzur Vakti'}',
          style: TextStyle(
            color: renkler.yaziSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _languageService['all_rights_reserved'] ?? 'Tüm hakları saklıdır.',
          style: TextStyle(
            color: renkler.yaziSecondary.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _languageService['for_allah'] ??
              'Allah\'ın (C.C) rızası için hazırlanmıştır.',
          style: TextStyle(
            color: renkler.vurgu,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _languageService['developer_name'] ??
              'Geliştirici: Selahattin Kocabay',
          style: TextStyle(
            color: renkler.yaziSecondary.withValues(alpha: 0.6),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
