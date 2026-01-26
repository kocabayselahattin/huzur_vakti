import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';

class ElifBaSayfa extends StatefulWidget {
  const ElifBaSayfa({super.key});

  @override
  State<ElifBaSayfa> createState() => _ElifBaSayfaState();
}

class _ElifBaSayfaState extends State<ElifBaSayfa>
    with SingleTickerProviderStateMixin {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();
  final FlutterTts _flutterTts = FlutterTts();
  late TabController _tabController;
  int _selectedLetterIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _configureTts();
  }

  Future<void> _configureTts() async {
    // Arapça TTS - tecvit kurallarına yakın okuma için
    // NOT: TTS tam tecvit kurallarına uymaz ama Arapça telaffuz sağlar
    await _flutterTts.setLanguage("ar-SA"); // Arapça (Suudi Arabistan)
    await _flutterTts.setSpeechRate(0.4); // Yavaş okuma (öğrenme için)
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // iOS için
    await _flutterTts.setSharedInstance(true);
    
    // Tamamlanma callback
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text(
          _languageService['elif_ba_title'] ?? 'ELİF-BA ÖĞREN',
          style: TextStyle(
            letterSpacing: 2,
            fontSize: 14,
            color: renkler.yaziPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: renkler.yaziPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: renkler.vurgu,
          labelColor: renkler.vurgu,
          unselectedLabelColor: renkler.yaziSecondary,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          tabs: [
            Tab(text: _languageService['arabic_letters'] ?? 'Arapça Harfler'),
            Tab(text: _languageService['tajweed_rules'] ?? 'Tecvit Kuralları'),
            Tab(text: _languageService['practice_mode'] ?? 'Pratik'),
          ],
        ),
      ),
      body: Container(
        decoration: renkler.arkaPlanGradient != null
            ? BoxDecoration(gradient: renkler.arkaPlanGradient)
            : null,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildHarflerTab(renkler),
            _buildTecvitTab(renkler),
            _buildPratikTab(renkler),
          ],
        ),
      ),
    );
  }

  Widget _buildHarflerTab(TemaRenkleri renkler) {
    return Row(
      children: [
        // Sol taraf - Harf listesi
        Container(
          width: 100,
          color: renkler.kartArkaPlan.withOpacity(0.5),
          child: ListView.builder(
            itemCount: _arapHarfler.length,
            itemBuilder: (context, index) {
              final harf = _arapHarfler[index];
              final isSelected = index == _selectedLetterIndex;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedLetterIndex = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? renkler.vurgu.withOpacity(0.2)
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: isSelected ? renkler.vurgu : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      harf['harf']!,
                      style: TextStyle(
                        fontSize: 28,
                        color: isSelected ? renkler.vurgu : renkler.yaziPrimary,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Sağ taraf - Harf detayları
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildHarfDetay(_arapHarfler[_selectedLetterIndex], renkler),
          ),
        ),
      ],
    );
  }

  Widget _buildHarfDetay(Map<String, String> harf, TemaRenkleri renkler) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Büyük harf gösterimi
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: renkler.kartArkaPlan,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: renkler.vurgu.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                harf['harf']!,
                style: TextStyle(
                  fontSize: 120,
                  color: renkler.vurgu,
                  fontFamily: 'Amiri',
                ),
              ),
              const SizedBox(height: 16),
              // Ses çalma butonu
              ElevatedButton.icon(
                onPressed: () => _playLetterSound(harf['harf']!),
                icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
                label: Text(_languageService['listen'] ?? 'Dinle (Arapça TTS)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: renkler.vurgu,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Bilgilendirme notu
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: renkler.vurgu.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: renkler.vurgu.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: renkler.vurgu,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Arapça TTS kullanılıyor. Tam tecvit kurallarına uymayabilir.',
                  style: TextStyle(
                    color: renkler.yaziSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Okunuş
        _buildInfoCard(
          title: _languageService['pronunciation'] ?? 'Okunuş',
          content: harf['okunus']!,
          renkler: renkler,
        ),
        const SizedBox(height: 16),
        
        // Örnek kelimeler
        _buildInfoCard(
          title: _languageService['example'] ?? 'Örnek Kelimeler',
          content: harf['ornek']!,
          renkler: renkler,
        ),
        const SizedBox(height: 16),
        
        // Açıklama
        if (harf['aciklama'] != null && harf['aciklama']!.isNotEmpty)
          _buildInfoCard(
            title: 'Açıklama',
            content: harf['aciklama']!,
            renkler: renkler,
          ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required TemaRenkleri renkler,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: renkler.vurgu.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: renkler.vurgu,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: renkler.yaziPrimary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTecvitTab(TemaRenkleri renkler) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tecvitKurallari.length,
      itemBuilder: (context, index) {
        final kural = _tecvitKurallari[index];
        return _buildTecvitKarti(kural, renkler);
      },
    );
  }

  Widget _buildTecvitKarti(Map<String, String> kural, TemaRenkleri renkler) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: renkler.vurgu.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          title: Text(
            kural['baslik']!,
            style: TextStyle(
              color: renkler.vurgu,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              kural['ornek']!,
              style: TextStyle(
                color: renkler.yaziPrimary,
                fontSize: 20,
                fontFamily: 'Amiri',
              ),
            ),
          ),
          children: [
            Text(
              kural['aciklama']!,
              style: TextStyle(
                color: renkler.yaziPrimary,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPratikTab(TemaRenkleri renkler) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 100,
              color: renkler.vurgu.withOpacity(0.5),
            ),
            const SizedBox(height: 32),
            Text(
              _languageService['test_yourself'] ?? 'Kendinizi Test Edin',
              style: TextStyle(
                color: renkler.yaziPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Öğrendiğiniz harfleri ve tecvit kurallarını test edin',
              style: TextStyle(
                color: renkler.yaziSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _startTest(context),
              icon: const Icon(Icons.play_arrow),
              label: Text(_languageService['start_test'] ?? 'Teste Başla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: renkler.vurgu,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playLetterSound(String harf) async {
    if (_isPlaying) {
      // Eğer zaten çalıyorsa durdur
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    setState(() {
      _isPlaying = true;
    });

    try {
      // Arapça TTS ile harfi oku (3 kez tekrar - öğrenme için)
      for (int i = 0; i < 3; i++) {
        await _flutterTts.speak(harf);
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 800));
        }
      }
    } catch (e) {
      debugPrint('Ses çalma hatası: $e');
      setState(() {
        _isPlaying = false;
      });
      
      // Hata durumunda kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ses çalınamadı. Lütfen cihazınızın ses ayarlarını kontrol edin.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isPlaying = false;
    });
  }

  void _startTest(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ElifBaTestSayfa(),
      ),
    );
  }

  // Arapça harfler verisi
  final List<Map<String, String>> _arapHarfler = [
    {
      'harf': 'ا',
      'okunus': 'Elif',
      'ornek': 'أَنَا (ene) - ben\nإِسْلَام (İslam)',
      'aciklama': 'Sessiz bir harftir. Üstündeki harekeyle okunur.',
    },
    {
      'harf': 'ب',
      'okunus': 'Be',
      'ornek': 'بَيْت (beyt) - ev\nكِتَاب (kitab) - kitap',
      'aciklama': 'Dudak harfidir. Alt tarafında bir nokta vardır.',
    },
    {
      'harf': 'ت',
      'okunus': 'Te',
      'ornek': 'تُفَّاح (tüffah) - elma\nمَكْتَب (mekteb) - masa',
      'aciklama': 'Diş harfidir. Üstünde iki nokta vardır.',
    },
    {
      'harf': 'ث',
      'okunus': 'Se',
      'ornek': 'ثَلَاثَة (selase) - üç\nثَوْب (sevb) - elbise',
      'aciklama': 'İngilizce "th" harfi gibi okunur. Üstünde üç nokta vardır.',
    },
    {
      'harf': 'ج',
      'okunus': 'Cim',
      'ornek': 'جَمِيل (cemil) - güzel\nمَسْجِد (mescid) - cami',
      'aciklama': 'Boğaz harfidir. Ortasında bir nokta vardır.',
    },
    {
      'harf': 'ح',
      'okunus': 'Ha',
      'ornek': 'حَلِيب (halip) - süt\nصَحِيح (sahih) - doğru',
      'aciklama': 'Boğazdan çıkan özel bir "h" harfidir.',
    },
    {
      'harf': 'خ',
      'okunus': 'Hı',
      'ornek': 'خُبْز (hubz) - ekmek\nتَارِيخ (tarih) - tarih',
      'aciklama': 'Boğazdan gelen kalın "h" harfidir. Üstünde bir nokta vardır.',
    },
    {
      'harf': 'د',
      'okunus': 'Dal',
      'ornek': 'دَرْس (ders) - ders\nبَلَد (beled) - ülke',
      'aciklama': 'Diş harfidir. Noktası yoktur.',
    },
    {
      'harf': 'ذ',
      'okunus': 'Zel',
      'ornek': 'ذَهَب (zehebe) - altın\nأُسْتَاذ (üstad) - hoca',
      'aciklama': '"Th" sesi gibi okunur. Üstünde bir nokta vardır.',
    },
    {
      'harf': 'ر',
      'okunus': 'Re',
      'ornek': 'رَجُل (racül) - adam\nنُور (nur) - ışık',
      'aciklama': 'Dil harfidir. Hafif titreşimle okunur.',
    },
    {
      'harf': 'ز',
      'okunus': 'Ze',
      'ornek': 'زَمَان (zeman) - zaman\nرُوز (ruz) - gün',
      'aciklama': 'Dil harfidir. Üstünde bir nokta vardır.',
    },
    {
      'harf': 'س',
      'okunus': 'Sin',
      'ornek': 'سَلَام (selam) - selam\nدِرَاسَة (dirase) - çalışma',
      'aciklama': 'Diş harfidir. Üç diş şeklindedir.',
    },
    {
      'harf': 'ش',
      'okunus': 'Şın',
      'ornek': 'شُكْرًا (şükran) - teşekkürler\nعَيْش (ayş) - yaşam',
      'aciklama': 'Diş harfidir. Üstünde üç nokta vardır.',
    },
    {
      'harf': 'ص',
      'okunus': 'Sad',
      'ornek': 'صَبَاح (sabah) - sabah\nشَخْص (şahs) - kişi',
      'aciklama': 'Kalın "s" harfidir. Damak yukarı kalkarak okunur.',
    },
    {
      'harf': 'ض',
      'okunus': 'Dad',
      'ornek': 'ضَوْء (dav) - ışık\nأَرْض (ard) - yer',
      'aciklama': 'Kalın "d" harfidir. Arapçaya özgü bir sestir.',
    },
    {
      'harf': 'ط',
      'okunus': 'Tı',
      'ornek': 'طَالِب (talib) - öğrenci\nخَطّ (hat) - hat',
      'aciklama': 'Kalın "t" harfidir.',
    },
    {
      'harf': 'ظ',
      'okunus': 'Zı',
      'ornek': 'ظُلْم (zulm) - zulüm\nحَافِظ (hafız) - koruyucu',
      'aciklama': 'Kalın "z" harfidir.',
    },
    {
      'harf': 'ع',
      'okunus': 'Ayın',
      'ornek': 'عِلْم (ilm) - ilim\nجَامِع (cami) - toplayan',
      'aciklama': 'Boğazdan gelen özel bir harftir. Türkçede karşılığı yoktur.',
    },
    {
      'harf': 'غ',
      'okunus': 'Gayın',
      'ornek': 'غُرْفَة (gurfe) - oda\nبَلَاغ (belag) - tebliğ',
      'aciklama': 'Boğazdan gelen "ğ" harfidir.',
    },
    {
      'harf': 'ف',
      'okunus': 'Fe',
      'ornek': 'فَوْز (fevz) - başarı\nخَوْف (havf) - korku',
      'aciklama': 'Dudak harfidir. Üstünde bir nokta vardır.',
    },
    {
      'harf': 'ق',
      'okunus': 'Kaf',
      'ornek': 'قُرْآن (Kur\'an)\nصَدَقَة (sadaka) - sadaka',
      'aciklama': 'Boğazdan çıkan kalın "k" harfidir.',
    },
    {
      'harf': 'ك',
      'okunus': 'Kef',
      'ornek': 'كَلِمَة (kelime) - kelime\nمَلِك (melik) - kral',
      'aciklama': 'Damak harfidir. Normal "k" sesi gibidir.',
    },
    {
      'harf': 'ل',
      'okunus': 'Lam',
      'ornek': 'لَيْلَة (leyle) - gece\nجَمِيل (cemil) - güzel',
      'aciklama': 'Dil harfidir. Açık "l" sesi gibidir.',
    },
    {
      'harf': 'م',
      'okunus': 'Mim',
      'ornek': 'مَاء (ma) - su\nإِسْلَام (İslam)',
      'aciklama': 'Dudak harfidir. İki dudak birleşerek okunur.',
    },
    {
      'harf': 'ن',
      'okunus': 'Nun',
      'ornek': 'نُور (nur) - ışık\nإِيمَان (iman) - iman',
      'aciklama': 'Burun harfidir. Burndan gelen sesle okunur.',
    },
    {
      'harf': 'ه',
      'okunus': 'He',
      'ornek': 'هُوَ (huve) - o\nاللّٰه (Allah)',
      'aciklama': 'Boğaz harfidir. Hafif nefes sesi gibidir.',
    },
    {
      'harf': 'و',
      'okunus': 'Vav',
      'ornek': 'وَرْد (verd) - gül\nنُور (nur) - ışık',
      'aciklama': 'Dudak harfidir. Med harfidir.',
    },
    {
      'harf': 'ي',
      'okunus': 'Ya',
      'ornek': 'يَوْم (yevm) - gün\nجَمِيل (cemil) - güzel',
      'aciklama': 'Damak harfidir. Med harfidir.',
    },
  ];

  // Tecvit kuralları
  final List<Map<String, String>> _tecvitKurallari = [
    {
      'baslik': 'İstiaze ve Besmele',
      'ornek': 'أَعُوذُ بِاللّٰهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
      'aciklama':
          'Kur\'an okumaya başlarken önce istiaze (euzü) ve besmele çekilir. İstiaze: "Kovulmuş şeytandan Allah\'a sığınırım" anlamındadır.',
    },
    {
      'baslik': 'Med (Uzatma)',
      'ornek': 'آمَنُوا - قَالُوا - يَقُولُونَ',
      'aciklama':
          'Med harfleri (elif, vav, ya) iki, dört veya altı hareke uzatılır. Tabii med iki hareke uzatılır.',
    },
    {
      'baslik': 'İdğam (Gizleme)',
      'ornek': 'مِنْ رَبِّهِمْ - مِنْ لَدُنَّا',
      'aciklama':
          'Nunun sakini veya tenvin ile bazı harfler karşılaşınca gizlenerek okunum. İdğam harfleri: ي ر م ل و ن',
    },
    {
      'baslik': 'İhfa (Saklanma)',
      'ornek': 'مِنْ شَرِّ - مِنْ قَبْلُ',
      'aciklama':
          'Nunun sakini veya tenvin, 15 harf ile karşılaşınca burundan gizlenerek okunur.',
    },
    {
      'baslik': 'İklab (Çevirme)',
      'ornek': 'مِنْ بَعْدِ - عَلِيمٌ بِمَا',
      'aciklama':
          'Nunun sakini veya tenvin, be (ب) harfi ile karşılaşınca mim (م) gibi okunur.',
    },
    {
      'baslik': 'İzhâr (Açıklama)',
      'ornek': 'مِنْ عِلْمٍ - مِنْ أَحَدٍ',
      'aciklama':
          'Nunun sakini veya tenvin, 6 boğaz harfi (أ ه ع ح غ خ) ile karşılaşınca açık okunur.',
    },
    {
      'baslik': 'Kalkale',
      'ornek': 'قَدْ سَمِعَ - أَحَطتُ',
      'aciklama':
          'Beş harf (ق ط ب ج د) sakin olunca sıçratılarak okunur. Kalkale harfleri: قطب جد',
    },
    {
      'baslik': 'Lâm-ı Şemsi ve Kameri',
      'ornek': 'الشَّمْسُ - الْقَمَرُ',
      'aciklama':
          'Şemsi lâm: 14 harf ile karşılaşınca gizlenir ve şedde okunur. Kameri lâm: 14 harf ile karşılaşınca açık okunur.',
    },
    {
      'baslik': 'Mim Sakini',
      'ornek': 'هُمْ مِنْ - عَلَيْهِمْ وَلَا',
      'aciklama':
          'Mim sakini mim ile karşılaşınca idğam şedde yapılır. Be ile karşılaşınca ihfa edilir. Diğer harflerle izhar yapılır.',
    },
    {
      'baslik': 'Ra Harfinin Okunuşu',
      'ornek': 'رَبِّ - بِرَبِّكَ',
      'aciklama':
          'Ra harfi bazen kalın (ر) bazen ince (ر̮) okunur. Üstünde ve ötre varsa kalın, esre varsa ince okunur.',
    },
  ];
}

// Test Sayfası
class ElifBaTestSayfa extends StatefulWidget {
  const ElifBaTestSayfa({super.key});

  @override
  State<ElifBaTestSayfa> createState() => _ElifBaTestSayfaState();
}

class _ElifBaTestSayfaState extends State<ElifBaTestSayfa> {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();
  
  int _currentQuestion = 0;
  int _score = 0;
  List<String?> _userAnswers = [];
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _userAnswers = List.filled(_testSorulari.length, null);
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    if (_showResult) {
      return _buildResultScreen(renkler);
    }

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text(
          '${_languageService['test_yourself'] ?? 'Test'} ${_currentQuestion + 1}/${_testSorulari.length}',
          style: TextStyle(fontSize: 14, color: renkler.yaziPrimary),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: renkler.yaziPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: renkler.arkaPlanGradient != null
            ? BoxDecoration(gradient: renkler.arkaPlanGradient)
            : null,
        child: Column(
          children: [
            // İlerleme çubuğu
            LinearProgressIndicator(
              value: (_currentQuestion + 1) / _testSorulari.length,
              backgroundColor: renkler.yaziSecondary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(renkler.vurgu),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildQuestion(_testSorulari[_currentQuestion], renkler),
              ),
            ),
            // İleri/Geri butonları
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentQuestion > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestion--;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: BorderSide(color: renkler.vurgu),
                        ),
                        child: Text(_languageService['previous'] ?? 'Önceki'),
                      ),
                    ),
                  if (_currentQuestion > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _userAnswers[_currentQuestion] != null
                          ? () {
                              if (_currentQuestion < _testSorulari.length - 1) {
                                setState(() {
                                  _currentQuestion++;
                                });
                              } else {
                                _finishTest();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: renkler.vurgu,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Text(
                        _currentQuestion < _testSorulari.length - 1
                            ? _languageService['next'] ?? 'Sonraki'
                            : 'Bitir',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(Map<String, dynamic> soru, TemaRenkleri renkler) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Soru
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: renkler.kartArkaPlan,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: renkler.vurgu.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                soru['soru'],
                style: TextStyle(
                  color: renkler.yaziPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (soru['harf'] != null) ...[
                const SizedBox(height: 20),
                Text(
                  soru['harf'],
                  style: TextStyle(
                    fontSize: 80,
                    color: renkler.vurgu,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Şıklar
        ...List.generate(
          (soru['secenekler'] as List<String>).length,
          (index) {
            final secenek = soru['secenekler'][index];
            final isSelected = _userAnswers[_currentQuestion] == secenek;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _userAnswers[_currentQuestion] = secenek;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? renkler.vurgu.withOpacity(0.2)
                        : renkler.kartArkaPlan,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? renkler.vurgu : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? renkler.vurgu
                              : renkler.vurgu.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : renkler.yaziPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          secenek,
                          style: TextStyle(
                            color: renkler.yaziPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: renkler.vurgu),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _finishTest() {
    _score = 0;
    for (int i = 0; i < _testSorulari.length; i++) {
      if (_userAnswers[i] == _testSorulari[i]['dogruCevap']) {
        _score++;
      }
    }
    setState(() {
      _showResult = true;
    });
  }

  Widget _buildResultScreen(TemaRenkleri renkler) {
    final percentage = (_score / _testSorulari.length * 100).round();
    
    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      body: Container(
        decoration: renkler.arkaPlanGradient != null
            ? BoxDecoration(gradient: renkler.arkaPlanGradient)
            : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  percentage >= 70 ? Icons.celebration : Icons.emoji_events_outlined,
                  size: 100,
                  color: renkler.vurgu,
                ),
                const SizedBox(height: 32),
                Text(
                  _languageService['congratulations'] ?? 'Tebrikler!',
                  style: TextStyle(
                    color: renkler.yaziPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _languageService['test_completed'] ?? 'Testi tamamladınız',
                  style: TextStyle(
                    color: renkler.yaziSecondary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: renkler.kartArkaPlan,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: renkler.vurgu.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_languageService['score'] ?? 'Puan'}:',
                        style: TextStyle(
                          color: renkler.yaziSecondary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_score / ${_testSorulari.length}',
                        style: TextStyle(
                          color: renkler.vurgu,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '%$percentage',
                        style: TextStyle(
                          color: renkler.yaziPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentQuestion = 0;
                            _score = 0;
                            _userAnswers = List.filled(_testSorulari.length, null);
                            _showResult = false;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(_languageService['try_again'] ?? 'Tekrar Dene'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          side: BorderSide(color: renkler.vurgu),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.home),
                        label: const Text('Ana Sayfa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: renkler.vurgu,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Test soruları
  final List<Map<String, dynamic>> _testSorulari = [
    {
      'soru': 'Bu harf nasıl okunur?',
      'harf': 'ب',
      'secenekler': ['Be', 'Te', 'Se', 'Ne'],
      'dogruCevap': 'Be',
    },
    {
      'soru': 'Med harfleri hangileridir?',
      'secenekler': ['ا و ي', 'ب ت ث', 'ل م ن', 'ق ك ل'],
      'dogruCevap': 'ا و ي',
    },
    {
      'soru': 'Kalkale harfleri hangileridir?',
      'secenekler': ['قطب جد', 'هويلا', 'يرملون', 'أ ه ع'],
      'dogruCevap': 'قطب جد',
    },
    {
      'soru': 'Bu harf nasıl okunur?',
      'harf': 'ع',
      'secenekler': ['Ayın', 'Gayın', 'He', 'Ha'],
      'dogruCevap': 'Ayın',
    },
    {
      'soru': 'İdğam harfleri hangileridir?',
      'secenekler': ['يرملون', 'قطب جد', 'أ ه ع', 'ص ض ط'],
      'dogruCevap': 'يرملون',
    },
    {
      'soru': 'Bu harf nasıl okunur?',
      'harf': 'ق',
      'secenekler': ['Kaf', 'Kef', 'Cim', 'Gayın'],
      'dogruCevap': 'Kaf',
    },
    {
      'soru': 'Boğaz harfleri kaç tanedir?',
      'secenekler': ['6', '4', '8', '10'],
      'dogruCevap': '6',
    },
    {
      'soru': 'Tabii med kaç hareke uzatılır?',
      'secenekler': ['2', '4', '6', '1'],
      'dogruCevap': '2',
    },
  ];
}
