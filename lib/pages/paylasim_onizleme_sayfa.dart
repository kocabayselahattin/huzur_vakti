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

  void _mesajGoster(String mesaj) {
    if (!mounted || mesaj.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  Future<void> _gorselPaylas(BuildContext butonContext) async {
    if (_paylasiliyor) return;
    setState(() => _paylasiliyor = true);

    // Görselin metin karşılığı da eklenir: görseli açamayan uygulamalarda
    // (veya kopyalarken) içerik yine okunabilir kalsın.
    final basarili = await PaylasimKartiService.gorselPaylas(
      kartAnahtari: _kartAnahtari,
      metin: widget.icerik.duzMetin(_ceviri('shared_via', '')),
      konu: widget.icerik.baslik,
      konum: PaylasimKartiService.konumBul(butonContext),
    );

    if (!mounted) return;
    setState(() => _paylasiliyor = false);
    if (!basarili) {
      _mesajGoster(_ceviri('share_image_failed', _ceviri('share_failed', '')));
    }
  }

  Future<void> _metinPaylas(BuildContext butonContext) async {
    if (_paylasiliyor) return;
    setState(() => _paylasiliyor = true);

    final basarili = await PaylasimKartiService.metinPaylas(
      metin: widget.icerik.duzMetin(_ceviri('shared_via', '')),
      konu: widget.icerik.baslik,
      konum: PaylasimKartiService.konumBul(butonContext),
    );

    if (!mounted) return;
    setState(() => _paylasiliyor = false);
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
                            imza: _imza,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _ceviri('card_style', 'Kart stili').toUpperCase(),
            style: TextStyle(
              color: renkler.yaziSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 62, child: _stilSeridi(renkler)),

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
