import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/konum_service.dart';
import '../services/diyanet_api_service.dart';
import '../services/language_service.dart';
import 'il_ilce_sec_sayfa.dart';

class ImsakiyeSayfa extends StatefulWidget {
  const ImsakiyeSayfa({super.key});

  @override
  State<ImsakiyeSayfa> createState() => _ImsakiyeSayfaState();
}

class _ImsakiyeSayfaState extends State<ImsakiyeSayfa> {
  final LanguageService _languageService = LanguageService();
  final PageController _pageController = PageController(initialPage: 12);
  final Set<String> _autoScrolledMonths = {};
  int _currentPage = 12;
  int _refreshNonce = 0;
  bool _konumYukleniyor = true;
  
  String? secilenIl;
  String? secilenIlce;
  String? secilenIlceId;

  static const int _aySayisi = 25;
  static const int _ayBaslangicOfseti = -12;

  @override
  void initState() {
    super.initState();
    _konumBilgileriniYukle();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getLocale() {
    final lang = _languageService.currentLanguage;
    switch (lang) {
      case 'tr':
        return 'tr_TR';
      case 'en':
        return 'en_US';
      case 'de':
        return 'de_DE';
      case 'fr':
        return 'fr_FR';
      case 'ar':
        return 'ar_SA';
      case 'fa':
        return 'fa_IR';
      default:
        return 'tr_TR';
    }
  }

  Future<void> _konumBilgileriniYukle() async {
    final il = await KonumService.getIl();
    final ilce = await KonumService.getIlce();
    final ilceId = await KonumService.getIlceId();
    
    if (!mounted) return;
    setState(() {
      secilenIl = il;
      secilenIlce = ilce;
      secilenIlceId = ilceId;
      _konumYukleniyor = false;
    });
  }

  DateTime? _parseMiladi(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateFormat('dd.MM.yyyy', _getLocale()).parse(value);
    } catch (_) {
      try {
        return DateFormat('dd.MM.yyyy').parse(value);
      } catch (_) {
        return null;
      }
    }
  }
  
  void _scrollToBugun(ScrollController controller, int bugunIndex) {
    if (bugunIndex < 0 || !controller.hasClients) return;
    
    // Each row is about 80px tall (including margin).
    const itemHeight = 88.0;
    final targetOffset = bugunIndex * itemHeight;
    
    // Center the target row on screen.
    final screenHeight = MediaQuery.of(context).size.height;
    final centeredOffset = targetOffset - (screenHeight / 2) + (itemHeight / 2);
    
    controller.animateTo(
      centeredOffset.clamp(0.0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
  
  /// Refresh the calendar by clearing cache and fetching fresh data.
  Future<void> _yenile() async {
    // Notify the user.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_languageService['refreshing'] ?? 'Refreshing...'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.orange,
      ),
    );
    
    // Fetch fresh data after cache clear.
    DiyanetApiService.clearCache();
    if (mounted) {
      setState(() {
        _refreshNonce++;
        _autoScrolledMonths.clear();
      });
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _languageService['refresh_success'] ?? 'Calendar updated!',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2741),
      appBar: AppBar(
        title: Text(
          _languageService['imsakiye_title'] ?? 'Prayer Calendar',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Refresh button.
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: _languageService['refresh'] ?? 'Refresh',
            onPressed: _yenile,
          ),
        ],
      ),
      body: _konumYukleniyor
          ? const Center(child: CircularProgressIndicator())
          : secilenIl == null || secilenIlce == null
              ? _konumSeciliDegil()
              : Column(
                  children: [
                    _ayBasligi(),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _aySayisi,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          final ayTarih = _getAyTarihi(index);
                          return FutureBuilder<List<Map<String, dynamic>>>(
                            key: ValueKey(
                              'ay_${ayTarih.year}_${ayTarih.month}_$_refreshNonce',
                            ),
                            future: DiyanetApiService.getAylikVakitler(
                              secilenIlceId!,
                              ayTarih.year,
                              ayTarih.month,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final ayVakitler = snapshot.data ?? [];
                              if (ayVakitler.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 60,
                                        color: Colors.white38,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _languageService['no_data_found'] ??
                                            'No data found',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return _aylikListe(ayTarih, ayVakitler);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _ayBasligi() {
    final ayTarih = _getAyTarihi(_currentPage);
    final ayYazi = DateFormat('MMMM yyyy', _getLocale()).format(ayTarih);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: _languageService['previous'] ?? 'Previous',
                icon: Icon(
                  Icons.chevron_left,
                  color: _currentPage > 0
                      ? Colors.cyanAccent
                      : Colors.white24,
                ),
                onPressed: _currentPage > 0
                    ? () => _goToPage(_currentPage - 1)
                    : null,
              ),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _aySeciciAc,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: Colors.cyanAccent.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ayYazi,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: _languageService['next'] ?? 'Next',
                icon: Icon(
                  Icons.chevron_right,
                  color: _currentPage < _aySayisi - 1
                      ? Colors.cyanAccent
                      : Colors.white24,
                ),
                onPressed: _currentPage < _aySayisi - 1
                    ? () => _goToPage(_currentPage + 1)
                    : null,
              ),
            ],
          ),
          Text(
            _languageService['swipe_for_more'] ?? 'Swipe to change month',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _aySeciciAc() async {
    final now = DateTime.now();
    final ilkTarih = DateTime(now.year, now.month + _ayBaslangicOfseti, 1);
    final sonTarih = DateTime(now.year, now.month + _ayBaslangicOfseti + _aySayisi - 1, 1);
    final seciliTarih = _getAyTarihi(_currentPage);

    final picked = await showDatePicker(
      context: context,
      initialDate: seciliTarih,
      firstDate: ilkTarih,
      lastDate: DateTime(sonTarih.year, sonTarih.month + 1, 0),
      helpText: _languageService['select_month'] ?? 'Ay sec',
      cancelText: _languageService['cancel'] ?? 'Cancel',
      confirmText: _languageService['ok'] ?? 'OK',
    );

    if (picked == null) return;

    final hedef = DateTime(picked.year, picked.month, 1);
    final diffAy = (hedef.year - now.year) * 12 + (hedef.month - now.month);
    final hedefIndex = diffAy - _ayBaslangicOfseti;
    if (hedefIndex >= 0 && hedefIndex < _aySayisi) {
      _goToPage(hedefIndex);
    }
  }

  void _goToPage(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    setState(() {
      _currentPage = index;
    });
  }

  DateTime _getAyTarihi(int index) {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _ayBaslangicOfseti + index, 1);
  }

  Widget _aylikListe(DateTime ayTarih, List<Map<String, dynamic>> ayVakitler) {
    final controller = ScrollController();
    final todayTileKey = GlobalKey();
    final now = DateTime.now();
    final ayAnahtar = '${ayTarih.year}-${ayTarih.month}';

    int bugunIndex = -1;
    if (ayTarih.year == now.year && ayTarih.month == now.month) {
      for (int i = 0; i < ayVakitler.length; i++) {
        final tarih = ayVakitler[i]['MiladiTarihKisa'] ?? '';
        final dt = _parseMiladi(tarih);
        if (dt != null &&
            dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day) {
          bugunIndex = i;
          break;
        }
      }
    }

    if (bugunIndex >= 0 && !_autoScrolledMonths.contains(ayAnahtar)) {
      _autoScrolledMonths.add(ayAnahtar);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = todayTileKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: ayVakitler.length,
      itemBuilder: (context, index) {
        final vakit = ayVakitler[index];
        final tarih = vakit['MiladiTarihKisa'] ?? '';
        final isBugun = index == bugunIndex;
        return _imsakiyeSatiri(
          vakit,
          key: isBugun ? todayTileKey : ValueKey(tarih),
        );
      },
    );
  }

  Widget _konumSeciliDegil() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 80, color: Colors.white38),
          const SizedBox(height: 20),
          Text(
            _languageService['location_not_selected'] ??
              'Location Not Selected',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _languageService['select_city_first'] ??
              'Select a city/district to view prayer times',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IlIlceSecSayfa()),
              );
              if (result == true) {
                _konumBilgileriniYukle();
              }
            },
            icon: const Icon(Icons.location_city),
            label: Text(
              _languageService['select_city_district'] ??
                  'Select City/District',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imsakiyeSatiri(dynamic vakit, {Key? key}) {
    final tarih = vakit['MiladiTarihKisa'] ?? '';
    final hicriTarih = vakit['HicriTarihUzun'] ?? '';
    
    // Debug: log the first day for verification.
    if (tarih.isNotEmpty) {
      // Log the first day for debug (day 1 only).
      final parts = tarih.split('.');
      if (parts.length == 3 && parts[0] == '01') {
        debugPrint('Imsakiye row: $tarih');
      }
    }

    DateTime? tarihObj;
    bool bugun = false;
    try {
      if (tarih.isNotEmpty) {
        final parts = tarih.split('.');
        if (parts.length == 3) {
          final yilParca = parts[2].trim();
          final ayParca = parts[1].trim();
          final gunParca = parts[0].trim();
          final yil = yilParca.length == 2
              ? 2000 + int.parse(yilParca)
              : int.parse(yilParca);
          tarihObj = DateTime(
            yil, // Year
            int.parse(ayParca), // Month
            int.parse(gunParca), // Day
          );
          final simdi = DateTime.now();
          bugun =
              tarihObj.year == simdi.year &&
              tarihObj.month == simdi.month &&
              tarihObj.day == simdi.day;
        }
      }
    } catch (e) {
      // Date parse error.
    }

    final gunAdi = tarihObj != null
        ? DateFormat('EEEE', _getLocale()).format(tarihObj)
        : '';

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bugun
            ? Colors.cyanAccent.withOpacity(0.15)
            : const Color(0xFF2B3151),
        borderRadius: BorderRadius.circular(12),
        border: bugun ? Border.all(color: Colors.cyanAccent, width: 2) : null,
      ),
      child: ExpansibleTile(
        tarih: tarih,
        gunAdi: gunAdi,
        hicriTarih: hicriTarih,
        bugun: bugun,
        imsak: vakit['Imsak'] ?? '-',
        gunes: vakit['Gunes'] ?? '-',
        ogle: vakit['Ogle'] ?? '-',
        ikindi: vakit['Ikindi'] ?? '-',
        aksam: vakit['Aksam'] ?? '-',
        yatsi: vakit['Yatsi'] ?? '-',
      ),
    );
  }
}

class ExpansibleTile extends StatefulWidget {
  final String tarih;
  final String gunAdi;
  final String hicriTarih;
  final bool bugun;
  final String imsak;
  final String gunes;
  final String ogle;
  final String ikindi;
  final String aksam;
  final String yatsi;

  const ExpansibleTile({
    super.key,
    required this.tarih,
    required this.gunAdi,
    required this.hicriTarih,
    required this.bugun,
    required this.imsak,
    required this.gunes,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
  });

  @override
  State<ExpansibleTile> createState() => _ExpansibleTileState();
}

class _ExpansibleTileState extends State<ExpansibleTile> {
  bool expanded = false;
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    expanded = widget.bugun;
  }

  @override
  void didUpdateWidget(covariant ExpansibleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.bugun && widget.bugun && !expanded) {
      setState(() {
        expanded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: () => setState(() => expanded = !expanded),
          leading: Icon(
            widget.bugun ? Icons.today : Icons.calendar_today,
            color: widget.bugun ? Colors.cyanAccent : Colors.white70,
          ),
          title: Text(
            '${widget.tarih} - ${widget.gunAdi}',
            style: TextStyle(
              color: widget.bugun ? Colors.cyanAccent : Colors.white,
              fontWeight: widget.bugun ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            widget.hicriTarih,
            style: TextStyle(
              color: widget.bugun
                  ? Colors.cyanAccent.withOpacity(0.7)
                  : Colors.white54,
              fontSize: 11,
            ),
          ),
          trailing: Icon(
            expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: widget.bugun ? Colors.cyanAccent : Colors.white70,
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                const Divider(color: Colors.white24),
                const SizedBox(height: 8),
                _vakitRow(
                  _languageService['imsak'] ?? 'Fajr',
                  widget.imsak,
                  Icons.nightlight_round,
                ),
                _vakitRow(
                  _languageService['gunes'] ?? 'Sunrise',
                  widget.gunes,
                  Icons.wb_sunny,
                ),
                _vakitRow(
                  _languageService['ogle'] ?? 'Dhuhr',
                  widget.ogle,
                  Icons.light_mode,
                ),
                _vakitRow(
                  _languageService['ikindi'] ?? 'Asr',
                  widget.ikindi,
                  Icons.brightness_6,
                ),
                _vakitRow(
                  _languageService['aksam'] ?? 'Maghrib',
                  widget.aksam,
                  Icons.wb_twilight,
                ),
                _vakitRow(
                  _languageService['yatsi'] ?? 'Isha',
                  widget.yatsi,
                  Icons.nights_stay,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _vakitRow(String ad, String saat, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.cyanAccent.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ad,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            saat,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
