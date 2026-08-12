import 'package:flutter/material.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';
import '../services/gunluk_hadis_dua_service.dart';
import '../services/kuran_veri_service.dart';

class GununIcerigiWidget extends StatefulWidget {
  const GununIcerigiWidget({super.key});

  @override
  State<GununIcerigiWidget> createState() => _GununIcerigiWidgetState();
}

class _GununIcerigiWidgetState extends State<GununIcerigiWidget> {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _midnightTimer;

  // Her gün canlı çekilen hadis/dua (fawazahmed0/hadith-api, Buhârî Türkçe).
  Map<String, String>? _canliHadis;
  Map<String, String>? _canliDua;

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onTemaChanged);
    _languageService.addListener(_onTemaChanged);
    _scheduleMidnightRefresh();
    _canliIcerigiYukle();
  }

  Future<void> _canliIcerigiYukle() async {
    final now = DateTime.now();

    // Kur'an verisi arka planda yükleniyor olabilir; hazır olunca günün
    // ayetini yeniden çizdir (yüklüyse anında döner).
    unawaited(
      KuranVeriService.yukle().then((_) {
        if (mounted) setState(() {});
      }),
    );

    final results = await Future.wait([
      GunlukHadisDuaService.gununHadisi(now),
      GunlukHadisDuaService.gununDuasi(now),
    ]);
    if (!mounted) return;
    setState(() {
      if ((results[0]['text'] ?? '').isNotEmpty) _canliHadis = results[0];
      if ((results[1]['text'] ?? '').isNotEmpty) _canliDua = results[1];
    });
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _midnightTimer = Timer(duration, () {
      if (mounted) setState(() {});
      _canliIcerigiYukle();
      _scheduleMidnightRefresh();
    });
  }

  void _onTemaChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _pageController.dispose();
    _temaService.removeListener(_onTemaChanged);
    _languageService.removeListener(_onTemaChanged);
    super.dispose();
  }

  List<Map<String, String>> _getPrayers() {
    final prayersList = _languageService['prayers'];
    if (prayersList is List) {
      return prayersList.map<Map<String, String>>((item) {
        if (item is Map) {
          return {
            'text': item['text']?.toString() ?? '',
            'source': item['source']?.toString() ?? '',
          };
        }
        return {'text': '', 'source': ''};
      }).toList();
    }
    return [];
  }

  List<Map<String, String>> _getHadiths() {
    final hadithsList = _languageService['hadiths'];
    if (hadithsList is List) {
      return hadithsList.map<Map<String, String>>((item) {
        if (item is Map) {
          return {
            'text': item['text']?.toString() ?? '',
            'source': item['source']?.toString() ?? '',
          };
        }
        return {'text': '', 'source': ''};
      }).toList();
    }
    return [];
  }

  int _getMonthlyRotatingIndex({
    required DateTime date,
    required int length,
    required int contentOffset,
  }) {
    if (length <= 0) return 0;

    // Move the sequence base every month so consecutive months start differently.
    final monthKey = date.year * 12 + date.month;
    final monthOffset = (monthKey * 17 + contentOffset) % length;
    final dayOffset = date.day - 1;

    return (monthOffset + dayOffset) % length;
  }

  Map<String, String> _getGununAyeti() {
    // Bildirimlerle aynı kaynaktan: gömülü tam Kur'an'ın Türkçe meali
    // (Elmalılı Hamdi Yazır). Kur'an verisi yoksa yerel havuza düşer.
    return GunlukHadisDuaService.gununAyeti(DateTime.now());
  }

  Map<String, String> _getGununDuasi() {
    // Her gün canlı çekilen dua (Buhârî, "Dualar" bölümü) hazırsa onu göster.
    if (_canliDua != null) return _canliDua!;

    // Yedek: canlı içerik henüz yüklenmemişse/başarısızsa yerel havuzu kullan.
    final prayers = _getPrayers();
    if (prayers.isEmpty) return {'text': '', 'source': ''};
    final now = DateTime.now();
    final index = _getMonthlyRotatingIndex(
      date: now,
      length: prayers.length,
      contentOffset: 7,
    );
    return prayers[index];
  }

  Map<String, String> _getGununHadisi() {
    // Her gün canlı çekilen hadis (Sahih-i Buhârî, Türkçe) hazırsa onu göster.
    if (_canliHadis != null) return _canliHadis!;

    // Yedek: canlı içerik henüz yüklenmemişse/başarısızsa yerel havuzu kullan.
    final hadiths = _getHadiths();
    if (hadiths.isEmpty) return {'text': '', 'source': ''};
    final now = DateTime.now();
    final index = _getMonthlyRotatingIndex(
      date: now,
      length: hadiths.length,
      contentOffset: 14,
    );
    return hadiths[index];
  }

  /// Kartın içeriğini sistemin paylaşım penceresiyle paylaşır.
  Future<void> _paylas({
    required BuildContext butonContext,
    required String baslik,
    required String icerik,
    required String kaynak,
  }) async {
    if (icerik.trim().isEmpty) return;

    final imza = (_languageService['shared_via'] ?? '').toString();
    final metin = StringBuffer()
      ..writeln(baslik)
      ..writeln()
      ..writeln('"${icerik.trim()}"');
    if (kaynak.trim().isNotEmpty) {
      metin
        ..writeln()
        ..writeln('— ${kaynak.trim()}');
    }
    if (imza.isNotEmpty) {
      metin
        ..writeln()
        ..writeln(imza);
    }

    // iPad'de paylaşım penceresinin butondan açılması için konum bilgisi.
    final kutu = butonContext.findRenderObject() as RenderBox?;
    final konum = (kutu != null && kutu.hasSize)
        ? kutu.localToGlobal(Offset.zero) & kutu.size
        : null;

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: metin.toString().trim(),
          subject: baslik,
          sharePositionOrigin: konum,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      final hata = (_languageService['share_failed'] ?? '').toString();
      if (hata.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hata)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;
    final gununAyeti = _getGununAyeti();
    final gununDuasi = _getGununDuasi();
    final gununHadisi = _getGununHadisi();

    return Column(
      children: [
        // Header and page indicator.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (_languageService['todays_content'] ?? '').toUpperCase(),
                style: TextStyle(
                  color: renkler.yaziSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              // Page indicator.
              Row(
                children: [
                  _buildPageIndicator(0, renkler),
                  const SizedBox(width: 6),
                  _buildPageIndicator(1, renkler),
                  const SizedBox(width: 6),
                  _buildPageIndicator(2, renkler),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Scrollable content.
        SizedBox(
          height: 180,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              _buildIcerikKart(
                baslik: (_languageService['todays_verse'] ?? '').toUpperCase(),
                icerik: gununAyeti['text'] ?? '',
                kaynak: gununAyeti['source'] ?? '',
                ikon: Icons.menu_book_rounded,
                renkler: renkler,
              ),
              _buildIcerikKart(
                baslik: (_languageService['todays_hadith'] ?? '').toUpperCase(),
                icerik: gununHadisi['text'] ?? '',
                kaynak: gununHadisi['source'] ?? '',
                ikon: Icons.star_rounded,
                renkler: renkler,
              ),
              _buildIcerikKart(
                baslik: (_languageService['todays_dua'] ?? '').toUpperCase(),
                icerik: gununDuasi['text'] ?? '',
                kaynak: gununDuasi['source'] ?? '',
                ikon: Icons.favorite_rounded,
                renkler: renkler,
              ),
            ],
          ),
        ),

        // Swipe hint.
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe,
                color: renkler.yaziSecondary.withValues(alpha: 0.5),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                _languageService['swipe_for_more'] ?? '',
                style: TextStyle(
                  color: renkler.yaziSecondary.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int index, TemaRenkleri renkler) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? renkler.vurgu
            : renkler.yaziSecondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Kartta kayan metnin tamamını okunabilir bir pencerede gösterir.
  /// Uzun ayet/hadis/duaların kayma bitmeden okunabilmesi için.
  Future<void> _tamMetniGoster({
    required String baslik,
    required String icerik,
    required String kaynak,
    required IconData ikon,
    required TemaRenkleri renkler,
  }) async {
    if (icerik.trim().isEmpty) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) {
        final ekranYuksekligi = MediaQuery.of(dialogContext).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: ekranYuksekligi * 0.8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  renkler.kartArkaPlan,
                  renkler.kartArkaPlan.withValues(alpha: 0.92),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: renkler.vurgu.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık satırı.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: renkler.vurgu.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(ikon, color: renkler.vurgu, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          baslik,
                          style: TextStyle(
                            color: renkler.vurgu,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: renkler.yaziSecondary,
                          size: 22,
                        ),
                        tooltip: _languageService['close'] ?? 'Kapat',
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),

                // Metnin tamamı - elle kaydırılabilir.
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(
                      '"${icerik.trim()}"',
                      style: TextStyle(
                        color: renkler.yaziPrimary,
                        fontSize: 16,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

                // Kaynak ve paylaş.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      if (kaynak.trim().isNotEmpty)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: renkler.vurgu.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '— $kaynak',
                              style: TextStyle(
                                color: renkler.yaziSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Builder(
                        builder: (butonContext) => Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _paylas(
                              butonContext: butonContext,
                              baslik: baslik,
                              icerik: icerik,
                              kaynak: kaynak,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: renkler.vurgu.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.share_rounded,
                                color: renkler.vurgu,
                                size: 18,
                              ),
                            ),
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
      },
    );
  }

  Widget _buildIcerikKart({
    required String baslik,
    required String icerik,
    required String kaynak,
    required IconData ikon,
    required TemaRenkleri renkler,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            renkler.kartArkaPlan,
            renkler.kartArkaPlan.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: renkler.vurgu.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: renkler.vurgu.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ikon, color: renkler.vurgu, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  baslik,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: renkler.vurgu,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Paylaş butonu.
              Builder(
                builder: (butonContext) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _paylas(
                      butonContext: butonContext,
                      baslik: baslik,
                      icerik: icerik,
                      kaynak: kaynak,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Tooltip(
                      message: (_languageService['share'] ?? '').toString(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: renkler.vurgu.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.share_rounded,
                          color: renkler.vurgu,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content. Metne dokunulunca tamamı popup'ta gösterilir.
          Expanded(
            child: GestureDetector(
              onTap: () => _tamMetniGoster(
                baslik: baslik,
                icerik: icerik,
                kaynak: kaynak,
                ikon: ikon,
                renkler: renkler,
              ),
              behavior: HitTestBehavior.opaque,
              child: _AutoScrollingText(
                text: '"$icerik"',
                style: TextStyle(
                  color: renkler.yaziPrimary,
                  fontSize: 15,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Source.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: renkler.vurgu.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '— $kaynak',
                  style: TextStyle(
                    color: renkler.yaziSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uzun metinleri otomatik olarak alttan yukarı kayan şekilde gösteren widget.
class _AutoScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _AutoScrollingText({required this.text, required this.style});

  @override
  State<_AutoScrollingText> createState() => _AutoScrollingTextState();
}

class _AutoScrollingTextState extends State<_AutoScrollingText> {
  final ScrollController _scrollController = ScrollController();

  /// Kaydırma hızı (saniyede piksel) - okumaya yetişilebilir bir tempo.
  static const double _hizPikselSaniye = 16;

  /// Uçlara gelindiğinde ve başlangıçta verilen bekleme süreleri.
  static const double _ucBeklemeSaniye = 3;
  static const double _baslangicBeklemeSaniye = 2;

  static const Duration _tickAraligi = Duration(milliseconds: 32);

  Timer? _ticker;
  bool _basiliTutuluyor = false;
  double _kalanBekleme = _baslangicBeklemeSaniye;
  int _yon = 1; // 1: aşağı, -1: yukarı

  @override
  void initState() {
    super.initState();
    _tickerBaslat();
  }

  @override
  void didUpdateWidget(covariant _AutoScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      // İçerik değişti: başa dön ve kaydırmayı yeniden başlat.
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      _yon = 1;
      _kalanBekleme = _baslangicBeklemeSaniye;
      _tickerBaslat();
    }
  }

  void _tickerBaslat() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_tickAraligi, (_) => _tick());
  }

  void _tick() {
    if (!mounted || !_scrollController.hasClients) return;

    // Kullanıcı parmağını basılı tutuyorsa kaydırmayı beklet.
    if (_basiliTutuluyor) return;

    final dt = _tickAraligi.inMilliseconds / 1000;

    if (_kalanBekleme > 0) {
      _kalanBekleme -= dt;
      return;
    }

    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return; // Metin sığıyor, kaydırmaya gerek yok.

    final yeniOffset = _scrollController.offset + (_yon * _hizPikselSaniye * dt);

    if (yeniOffset >= max) {
      _scrollController.jumpTo(max);
      _yon = -1;
      _kalanBekleme = _ucBeklemeSaniye;
    } else if (yeniOffset <= 0) {
      _scrollController.jumpTo(0);
      _yon = 1;
      _kalanBekleme = _ucBeklemeSaniye;
    } else {
      _scrollController.jumpTo(yeniOffset);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parmak basılıyken kaydırmayı duraklat, kaldırınca devam ettir.
    return Listener(
      onPointerDown: (_) => _basiliTutuluyor = true,
      onPointerUp: (_) => _basiliTutuluyor = false,
      onPointerCancel: (_) => _basiliTutuluyor = false,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Text(widget.text, style: widget.style),
      ),
    );
  }
}
