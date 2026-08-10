import 'package:flutter/material.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';

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

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onTemaChanged);
    _languageService.addListener(_onTemaChanged);
    _scheduleMidnightRefresh();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);
    _midnightTimer = Timer(duration, () {
      if (mounted) setState(() {});
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

  List<Map<String, String>> _getVerses() {
    final versesList = _languageService['verses'];
    if (versesList is List) {
      return versesList.map<Map<String, String>>((item) {
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
    final verses = _getVerses();
    if (verses.isEmpty) return {'text': '', 'source': ''};
    final now = DateTime.now();
    final index = _getMonthlyRotatingIndex(
      date: now,
      length: verses.length,
      contentOffset: 0,
    );
    return verses[index];
  }

  Map<String, String> _getGununDuasi() {
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

          // Content.
          Expanded(
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
  bool _isScrolling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  @override
  void didUpdateWidget(covariant _AutoScrollingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _isScrolling = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  Future<void> _startAutoScroll() async {
    if (_isScrolling) return;
    _isScrolling = true;

    // İlk bekleme
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || !_scrollController.hasClients) {
      _isScrolling = false;
      return;
    }

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      _isScrolling = false;
      return; // Kaydırmaya gerek yok, metin sığıyor
    }

    while (mounted && _scrollController.hasClients) {
      try {
        final max = _scrollController.position.maxScrollExtent;
        if (max <= 0) break;

        // Aşağı kaydır
        final duration = Duration(
          milliseconds: (max * 40).toInt().clamp(2000, 15000),
        );
        await _scrollController.animateTo(
          max,
          duration: duration,
          curve: Curves.linear,
        );

        if (!mounted || !_scrollController.hasClients) break;
        await Future.delayed(const Duration(seconds: 3));
        if (!mounted || !_scrollController.hasClients) break;

        // Yukarı kaydır
        await _scrollController.animateTo(
          0,
          duration: duration,
          curve: Curves.linear,
        );

        if (!mounted || !_scrollController.hasClients) break;
        await Future.delayed(const Duration(seconds: 3));
      } catch (_) {
        break;
      }
    }
    _isScrolling = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style),
    );
  }
}
