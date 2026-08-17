import 'package:flutter/material.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';
import '../services/vibration_service.dart';
import '../services/kuran_veri_service.dart';
import '../widgets/zikir_sayac_cemberi.dart';

/// Namaz sonrası rehberli tesbihat: önce Ayetel Kürsi, ardından 33
/// Sübhanallah, 33 Elhamdülillah, 33 Allahüekber. Sayaç dairesi zikirmatikle
/// aynı paylaşılan bileşeni ([ZikirSayacCemberi]) kullanır; yalnızca
/// sayma/geçiş akışı buraya özeldir (sabit hedef + otomatik bir sonraki
/// aşamaya geçme).
class TesbihatSayfa extends StatefulWidget {
  const TesbihatSayfa({super.key});

  @override
  State<TesbihatSayfa> createState() => _TesbihatSayfaState();
}

class _TesbihatSayfaState extends State<TesbihatSayfa> {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();

  static const int _hedef = 33;
  static const int _ayetelKursiAsamasi = 0;
  static const int _ilkZikirAsamasi = 1;

  int get _tamamlandiAsamasi => _ilkZikirAsamasi + _asamalar.length;

  int _asamaIndex = _ayetelKursiAsamasi;
  int _sayac = 0;
  bool _geciriliyor = false;

  Map<String, dynamic>? _ayetelKursi;
  bool _ayetYukleniyor = true;

  List<Map<String, String>> get _asamalar => [
    {
      'isim': _languageService['subhanallah'] ?? 'Sübhanallah',
      'anlam':
          _languageService['subhanallah_meaning'] ??
          'Allah her türlü eksiklikten uzaktır',
    },
    {
      'isim': _languageService['alhamdulillah'] ?? 'Elhamdülillah',
      'anlam': _languageService['alhamdulillah_meaning'] ?? 'Hamd Allah\'a mahsustur',
    },
    {
      'isim': _languageService['allahu_akbar'] ?? 'Allahü Ekber',
      'anlam': _languageService['allahu_akbar_meaning'] ?? 'Allah en büyüktür',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ayetelKursiyiYukle();
  }

  Future<void> _ayetelKursiyiYukle() async {
    if (!KuranVeriService.yuklendiMi) {
      await KuranVeriService.yukle();
    }
    if (!mounted) return;
    final ayetler = KuranVeriService.sureAyetleri(2);
    setState(() {
      _ayetelKursi = ayetler.length >= 255 ? ayetler[254] : null;
      _ayetYukleniyor = false;
    });
  }

  String _ceviri(String anahtar, String yedek) {
    final deger = _languageService[anahtar];
    if (deger is String && deger.trim().isNotEmpty) return deger;
    return yedek;
  }

  void _ayetelKursidenDevamEt() {
    setState(() => _asamaIndex = _ilkZikirAsamasi);
  }

  Future<void> _sayacArttir() async {
    if (_geciriliyor) return;
    final tamamlandi = _sayac + 1 >= _hedef;

    setState(() => _sayac++);

    if (tamamlandi) {
      _geciriliyor = true;
      await VibrationService.vibratePattern([0, 250, 150, 250, 150, 400]);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _asamaIndex++;
        _sayac = 0;
        _geciriliyor = false;
      });
    } else {
      await VibrationService.light();
    }
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text(
          _ceviri('tesbihat', 'Namaz Tesbihatı'),
          style: TextStyle(color: renkler.yaziPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
      ),
      body: Container(
        decoration: renkler.arkaPlanGradient != null
            ? BoxDecoration(gradient: renkler.arkaPlanGradient)
            : null,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              if (_asamaIndex < _tamamlandiAsamasi) _asamaNoktalari(renkler),
              const SizedBox(height: 8),
              Expanded(child: _asamaGovdesi(renkler)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _asamaGovdesi(TemaRenkleri renkler) {
    if (_asamaIndex == _ayetelKursiAsamasi) {
      return _ayetelKursiEkrani(renkler);
    }
    if (_asamaIndex >= _tamamlandiAsamasi) {
      return _tamamlandiEkrani(renkler);
    }
    return _sayacEkrani(renkler);
  }

  Widget _asamaNoktalari(TemaRenkleri renkler) {
    final toplam = 1 + _asamalar.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(toplam, (index) {
        final aktif = index == _asamaIndex;
        final tamamlandi = index < _asamaIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: aktif ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: tamamlandi || aktif
                ? renkler.vurgu
                : renkler.yaziSecondary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _sayacEkrani(TemaRenkleri renkler) {
    final asama = _asamalar[_asamaIndex - _ilkZikirAsamasi];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            asama['anlam'] ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(color: renkler.yaziSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: Center(
            child: ZikirSayacCemberi(
              sayac: _sayac,
              hedef: _hedef,
              zikirMetni: asama['isim'] ?? '',
              onTap: _sayacArttir,
              arkaPlanRengi: renkler.arkaPlan,
              oncekiArkaPlanRengi: renkler.kartArkaPlan,
              vurguRengi: renkler.vurgu,
              yaziSecondaryRengi: renkler.yaziSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${_asamaIndex - _ilkZikirAsamasi + 1}/${_asamalar.length}',
            style: TextStyle(
              color: renkler.yaziSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _ayetelKursiEkrani(TemaRenkleri renkler) {
    if (_ayetYukleniyor) {
      return Center(child: CircularProgressIndicator(color: renkler.vurgu));
    }
    final ayet = _ayetelKursi;
    if (ayet == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _ceviri('ayetel_kursi_load_error', 'Ayetel Kürsi yüklenemedi'),
                textAlign: TextAlign.center,
                style: TextStyle(color: renkler.yaziSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _ayetelKursidenDevamEt,
                child: Text(_ceviri('continue', 'Devam Et')),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              _ceviri('ayetel_kursi', 'Ayetel Kürsi'),
              style: TextStyle(
                color: renkler.vurgu,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: renkler.kartArkaPlan,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: renkler.vurgu.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (ayet['arapca'] ?? '').toString(),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: renkler.yaziPrimary,
                    fontSize: 22,
                    fontFamily: 'Amiri',
                    height: 1.9,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  (ayet['okunus'] ?? '').toString(),
                  style: TextStyle(
                    color: renkler.yaziSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  (ayet['meal'] ?? '').toString(),
                  style: TextStyle(
                    color: renkler.yaziPrimary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _ayetelKursidenDevamEt,
              style: ElevatedButton.styleFrom(
                backgroundColor: renkler.vurgu,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(_ceviri('continue', 'Devam Et')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tamamlandiEkrani(TemaRenkleri renkler) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: renkler.vurgu, size: 64),
            const SizedBox(height: 16),
            Text(
              _ceviri('tesbihat_complete', 'Tesbihatın tamamlandı'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: renkler.yaziPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: renkler.vurgu,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(_ceviri('finish', 'Tamamla')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
