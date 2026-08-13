import 'package:flutter/material.dart';

import '../services/language_service.dart';
import '../services/paylasim_karti_service.dart';
import '../services/tema_service.dart';
import '../widgets/paylasim_karti.dart';

/// Ayet / hadis / dua içeriğini paylaşmadan önce gösterilen önizleme.
///
/// Kullanıcı kart stilini seçer, isterse görseli isterse düz metni paylaşır.
class PaylasimOnizlemeSayfa extends StatefulWidget {
  final PaylasimIcerigi icerik;

  const PaylasimOnizlemeSayfa({super.key, required this.icerik});

  /// Önizlemeyi açmak için kısayol. İçerik boşsa hiçbir şey yapmaz.
  static Future<void> ac(BuildContext context, PaylasimIcerigi icerik) {
    if (icerik.metin.trim().isEmpty) return Future.value();
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaylasimOnizlemeSayfa(icerik: icerik),
      ),
    );
  }

  @override
  State<PaylasimOnizlemeSayfa> createState() => _PaylasimOnizlemeSayfaState();
}

class _PaylasimOnizlemeSayfaState extends State<PaylasimOnizlemeSayfa> {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();
  final GlobalKey _kartAnahtari = GlobalKey();

  late List<PaylasimKartiStili> _stiller;
  int _seciliStil = 0;
  PaylasimKartiDuzeni _seciliDuzen = PaylasimKartiDuzeni.klasik;
  PaylasimKartiOrani _seciliOran = PaylasimKartiOrani.serbest;
  bool _arapcaGoster = true;
  bool _paylasiliyor = false;

  bool get _arapcaVar => (widget.icerik.arapca ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _stilleriHazirla();
    _temaService.addListener(_onDegisti);
    _languageService.addListener(_onDegisti);
  }

  @override
  void dispose() {
    _temaService.removeListener(_onDegisti);
    _languageService.removeListener(_onDegisti);
    super.dispose();
  }

  void _onDegisti() {
    if (!mounted) return;
    setState(_stilleriHazirla);
  }

  /// İlk stil her zaman kullanıcının aktif temasından türetilir.
  void _stilleriHazirla() {
    _stiller = [
      PaylasimKartiStili.temadan(_temaService.renkler),
      ...PaylasimKartiStili.sabitStiller,
    ];
    if (_seciliStil >= _stiller.length) _seciliStil = 0;
  }

  String _ceviri(String anahtar, String yedek) {
    final deger = _languageService[anahtar];
    if (deger is String && deger.trim().isNotEmpty) return deger;
    return yedek;
  }

  String get _imza => _ceviri('app_name', 'Huzura Davet');

  /// İmzanın altında görünen tanıtım satırı; kartı görenler uygulamanın ne
  /// olduğunu anlasın diye eklenir.
  String get _tanitim => _ceviri('share_tagline', 'Namaz Vakti Uygulaması');

  void _mesajGoster(String mesaj) {
    if (!mounted || mesaj.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  Future<void> _gorselPaylas(BuildContext butonContext) async {
    if (_paylasiliyor) return;
    setState(() => _paylasiliyor = true);

    // Görselin yanına içeriğin tamamı değil, yalnızca iki satırlık tanıtım ve
    // mağaza bağlantısı eklenir: WhatsApp bunu kartın alt yazısı olarak
    // gösteriyor, dolayısıyla ayet ikinci kez yazılmış olmuyor.
    // Beklenmedik bir hata çıksa bile düğme "yükleniyor"da kilitli kalmamalı.
    var basarili = false;
    try {
      basarili = await PaylasimKartiService.gorselPaylas(
        kartAnahtari: _kartAnahtari,
        metin: widget.icerik.kisaTanitim(_imza, _tanitim),
        konu: widget.icerik.baslik,
        konum: PaylasimKartiService.konumBul(butonContext),
      );
    } finally {
      if (mounted) setState(() => _paylasiliyor = false);
    }

    if (!mounted) return;
    if (!basarili) {
      _mesajGoster(_ceviri('share_image_failed', _ceviri('share_failed', '')));
    }
  }

  Future<void> _metinPaylas(BuildContext butonContext) async {
    if (_paylasiliyor) return;
    setState(() => _paylasiliyor = true);

    var basarili = false;
    try {
      basarili = await PaylasimKartiService.metinPaylas(
        metin: widget.icerik.duzMetin(_ceviri('shared_via', '')),
        konu: widget.icerik.baslik,
        konum: PaylasimKartiService.konumBul(butonContext),
      );
    } finally {
      if (mounted) setState(() => _paylasiliyor = false);
    }

    if (!mounted) return;
    if (!basarili) _mesajGoster(_ceviri('share_failed', ''));
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
        title: Text(
          _ceviri('share', 'Paylaş'),
          style: TextStyle(
            color: renkler.yaziPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: renkler.arkaPlan,
          gradient: renkler.arkaPlanGradient,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Önizleme: kart doğal boyutunda çizilir, ekrana sığacak
              // şekilde ölçeklenir. Yakalama kartın kendi boyutundan yapılır.
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: RepaintBoundary(
                          key: _kartAnahtari,
                          child: PaylasimKarti(
                            icerik: widget.icerik,
                            stil: _stiller[_seciliStil],
                            duzen: _seciliDuzen,
                            oran: _seciliOran,
                            imza: _imza,
                            tanitim: _tanitim,
                            arapcaGoster: _arapcaGoster,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              _altPanel(renkler),
            ],
          ),
        ),
      ),
    );
  }

  Widget _altPanel(TemaRenkleri renkler) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: renkler.vurgu.withValues(alpha: 0.2)),
        ),
      ),
      // Seçiciler alt alta uzun bir liste oluşturduğu için küçük ekranlarda
      // panelin kendisi kaydırılır; paylaş butonları hep erişilebilir kalır.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bolumBasligi(_ceviri('card_layout', 'Tasarım'), renkler),
              const SizedBox(height: 10),
              SizedBox(height: 66, child: _duzenSeridi(renkler)),
              const SizedBox(height: 14),
              _bolumBasligi(_ceviri('card_style', 'Kart stili'), renkler),
              const SizedBox(height: 10),
              SizedBox(height: 62, child: _stilSeridi(renkler)),
              const SizedBox(height: 14),
              _bolumBasligi(_ceviri('card_ratio', 'Oran'), renkler),
              const SizedBox(height: 10),
              SizedBox(height: 40, child: _oranSeridi(renkler)),

              // Arapça metin yalnızca içerikte varsa açılıp kapatılabilir.
              if (_arapcaVar)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _arapcaGoster,
                    activeThumbColor: renkler.vurgu,
                    title: Text(
                      _ceviri('show_arabic', 'Arapça metni göster'),
                      style: TextStyle(
                        color: renkler.yaziPrimary,
                        fontSize: 14,
                      ),
                    ),
                    onChanged: (deger) => setState(() => _arapcaGoster = deger),
                  ),
                ),

              const SizedBox(height: 12),
              _paylasButonlari(renkler),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bolumBasligi(String metin, TemaRenkleri renkler) {
    return Text(
      metin.toUpperCase(),
      style: TextStyle(
        color: renkler.yaziSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
      ),
    );
  }

  /// Kartın yerleşim tasarımını seçen şerit.
  Widget _duzenSeridi(TemaRenkleri renkler) {
    const duzenler = PaylasimKartiDuzeni.values;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: duzenler.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final duzen = duzenler[index];
        final secili = duzen == _seciliDuzen;
        return GestureDetector(
          onTap: () => setState(() => _seciliDuzen = duzen),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: secili
                  ? renkler.vurgu.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: secili
                    ? renkler.vurgu
                    : renkler.yaziSecondary.withValues(alpha: 0.3),
                width: secili ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  duzen.ikon,
                  size: 20,
                  color: secili ? renkler.vurgu : renkler.yaziSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  _ceviri(duzen.isimAnahtari, duzen.yedekIsim),
                  style: TextStyle(
                    color: secili ? renkler.vurgu : renkler.yaziSecondary,
                    fontSize: 10,
                    fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Görselin en–boy oranını seçen şerit. "Durum" seçeneği, WhatsApp/Instagram
  /// durumunda kartın tam ekran görünmesi için 9:16 üretir.
  Widget _oranSeridi(TemaRenkleri renkler) {
    const oranlar = PaylasimKartiOrani.values;
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: oranlar.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final oran = oranlar[index];
        final secili = oran == _seciliOran;
        return GestureDetector(
          onTap: () => setState(() => _seciliOran = oran),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: secili
                  ? renkler.vurgu.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: secili
                    ? renkler.vurgu
                    : renkler.yaziSecondary.withValues(alpha: 0.3),
                width: secili ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  oran.ikon,
                  size: 15,
                  color: secili ? renkler.vurgu : renkler.yaziSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _ceviri(oran.isimAnahtari, oran.yedekIsim),
                  style: TextStyle(
                    color: secili ? renkler.vurgu : renkler.yaziSecondary,
                    fontSize: 11.5,
                    fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stilSeridi(TemaRenkleri renkler) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _stiller.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final stil = _stiller[index];
        final secili = index == _seciliStil;
        return GestureDetector(
          onTap: () => setState(() => _seciliStil = index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: stil.arkaPlan,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: secili
                        ? renkler.vurgu
                        : renkler.yaziSecondary.withValues(alpha: 0.3),
                    width: secili ? 2.5 : 1,
                  ),
                ),
                child: secili
                    ? Icon(Icons.check, size: 18, color: stil.vurgu)
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                _ceviri(stil.isimAnahtari, stil.yedekIsim),
                style: TextStyle(
                  color: secili ? renkler.vurgu : renkler.yaziSecondary,
                  fontSize: 10,
                  fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _paylasButonlari(TemaRenkleri renkler) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Builder(
            builder: (butonContext) => ElevatedButton.icon(
              onPressed: _paylasiliyor
                  ? null
                  : () => _gorselPaylas(butonContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: renkler.vurgu,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _paylasiliyor
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.image_rounded, size: 18),
              label: Text(
                _ceviri('share_as_image', 'Görsel olarak paylaş'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Builder(
            builder: (butonContext) => OutlinedButton.icon(
              onPressed: _paylasiliyor
                  ? null
                  : () => _metinPaylas(butonContext),
              style: OutlinedButton.styleFrom(
                foregroundColor: renkler.yaziPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: renkler.vurgu.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.text_fields_rounded, size: 18),
              label: Text(
                _ceviri('share_as_text', 'Metin olarak'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
