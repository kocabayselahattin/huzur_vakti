import 'package:flutter/material.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';

class TemaAyarlariSayfa extends StatefulWidget {
  const TemaAyarlariSayfa({super.key});

  @override
  State<TemaAyarlariSayfa> createState() => _TemaAyarlariSayfaState();
}

class _TemaAyarlariSayfaState extends State<TemaAyarlariSayfa>
    with SingleTickerProviderStateMixin {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();
  late TabController _tabController;

  // Selected colors for the custom theme
  Color _ozelArkaPlan = const Color(0xFF1B2741);
  Color _ozelKartArkaPlan = const Color(0xFF2B3151);
  Color _ozelVurgu = const Color(0xFF00BCD4);
  Color _ozelVurguSecondary = const Color(0xFF26C6DA);
  Color _ozelYaziPrimary = Colors.white;
  Color _ozelYaziSecondary = const Color(0xFFB0BEC5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final mevcut = _temaService.renkler;
    _ozelArkaPlan = mevcut.arkaPlan;
    _ozelKartArkaPlan = mevcut.kartArkaPlan;
    _ozelVurgu = mevcut.vurgu;
    _ozelVurguSecondary = mevcut.vurguSecondary;
    _ozelYaziPrimary = mevcut.yaziPrimary;
    _ozelYaziSecondary = mevcut.yaziSecondary;
    _temaService.addListener(_onTemaChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _temaService.removeListener(_onTemaChanged);
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
      appBar: AppBar(
        title: Text(
          _languageService['theme_settings'] ?? '',
          style: TextStyle(color: renkler.yaziPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: renkler.vurgu,
          labelColor: renkler.vurgu,
          unselectedLabelColor: renkler.yaziSecondary,
          tabs: [
            Tab(
              text: _languageService['preset_themes'] ?? '',
              icon: const Icon(Icons.palette),
            ),
            Tab(
              text: _languageService['custom_theme'] ?? '',
              icon: const Icon(Icons.color_lens),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHazirTemalar(renkler), _buildOzelTema(renkler)],
      ),
    );
  }

  Widget _buildHazirTemalar(TemaRenkleri renkler) {
    final temaList =
        AppTema.values.where((tema) => tema != AppTema.ozel).toList();

    return Column(
      children: [
        _buildFontSecimi(renkler),
        if (!_temaService.sayacTemasiKullan)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Material(
              color: renkler.vurgu.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _temaService.sayacTemasiKullanAyarla(true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.restore, color: renkler.vurgu),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _languageService['reset_to_counter_theme'] ?? '',
                          style: TextStyle(
                            color: renkler.vurgu,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: renkler.yaziSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: temaList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildOnizleme(renkler);
              }
              final tema = temaList[index - 1];
              final temaRenkleri = TemaService.temalar[tema]!;
              final secili = !_temaService.sayacTemasiKullan &&
                  _temaService.mevcutTema == tema;
              return _buildTemaKarti(tema, temaRenkleri, secili);
            },
          ),
        ),
      ],
    );
  }

    Widget _buildOnizleme(TemaRenkleri renkler) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: renkler.kartArkaPlan,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: renkler.vurgu.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(renkler.ikon, color: renkler.vurgu, size: 28),
                const SizedBox(width: 12),
                Text(
                  _languageService[renkler.isim] ?? renkler.isim,
                  style: TextStyle(
                    color: renkler.yaziPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _languageService[renkler.aciklama] ?? renkler.aciklama,
              style: TextStyle(color: renkler.yaziSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: renkler.vurgu.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.wb_sunny, color: renkler.vurgu, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _languageService['gunes'] ?? '',
                      style: TextStyle(
                        color: renkler.vurgu,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '07:45',
                    style: TextStyle(
                      color: renkler.vurgu,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget _buildTemaKarti(AppTema tema, TemaRenkleri temaRenkleri, bool secili) {
      return GestureDetector(
        onTap: () => _temaService.temayiDegistir(tema),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: temaRenkleri.arkaPlanGradient,
            color:
                temaRenkleri.arkaPlanGradient == null ? temaRenkleri.arkaPlan : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: secili ? temaRenkleri.vurgu : temaRenkleri.ayirac,
              width: secili ? 2 : 1,
            ),
            boxShadow: secili
                ? [
                    BoxShadow(
                      color: temaRenkleri.vurgu.withOpacity(0.25),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: temaRenkleri.kartArkaPlan,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  temaRenkleri.ikon,
                  color: temaRenkleri.vurgu,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _languageService[temaRenkleri.isim] ?? temaRenkleri.isim,
                      style: TextStyle(
                        color: temaRenkleri.yaziPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _languageService[temaRenkleri.aciklama] ??
                          temaRenkleri.aciklama,
                      style: TextStyle(
                        color: temaRenkleri.yaziSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: [
                  _renkDairesi(temaRenkleri.vurgu, 14),
                  const SizedBox(width: 3),
                  _renkDairesi(temaRenkleri.vurguSecondary, 14),
                ],
              ),
              const SizedBox(width: 10),
              if (secili)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: temaRenkleri.vurgu,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: temaRenkleri.arkaPlan,
                    size: 16,
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: temaRenkleri.ayirac, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    Widget _buildOzelTema(TemaRenkleri renkler) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFontSecimi(renkler),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _ozelKartArkaPlan,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _ozelVurgu.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    _languageService['custom_theme_preview'] ?? '',
                    style: TextStyle(
                      color: _ozelVurgu,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _ozelVurgu.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: _ozelVurgu),
                        const SizedBox(width: 12),
                        Text(
                          _languageService['sample_time'] ?? '',
                          style: TextStyle(
                            color: _ozelYaziPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '12:00',
                          style: TextStyle(color: _ozelYaziSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _languageService['preset_palettes'] ?? '',
              style: TextStyle(
                color: renkler.yaziPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: TemaService.hazirPaletler.length,
                itemBuilder: (context, index) {
                  final palet = TemaService.hazirPaletler[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _ozelArkaPlan = palet['arkaPlan'] as Color;
                        _ozelKartArkaPlan =
                            Color.lerp(_ozelArkaPlan, Colors.white, 0.08)!;
                        _ozelVurgu = palet['vurgu'] as Color;
                        _ozelVurguSecondary =
                            Color.lerp(_ozelVurgu, Colors.white, 0.3)!;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: palet['arkaPlan'] as Color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _ozelArkaPlan == palet['arkaPlan']
                              ? (palet['vurgu'] as Color)
                              : (palet['vurgu'] as Color).withOpacity(0.5),
                          width: _ozelArkaPlan == palet['arkaPlan'] ? 3 : 2,
                        ),
                        boxShadow: _ozelArkaPlan == palet['arkaPlan']
                            ? [
                                BoxShadow(
                                  color: (palet['vurgu'] as Color)
                                      .withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: palet['vurgu'] as Color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (palet['vurgu'] as Color)
                                      .withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              _languageService[palet['isim'] as String] ??
                                  (palet['isim'] as String),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _languageService['customize_colors'] ?? '',
              style: TextStyle(
                color: renkler.yaziPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRenkSecici(
              _languageService['background'] ?? '',
              _ozelArkaPlan,
              (color) {
                setState(() {
                  _ozelArkaPlan = color;
                  _ozelKartArkaPlan = Color.lerp(color, Colors.white, 0.08)!;
                });
              },
            ),
            _buildRenkSecici(
              _languageService['accent_color'] ?? '',
              _ozelVurgu,
              (color) {
                setState(() {
                  _ozelVurgu = color;
                  _ozelVurguSecondary = Color.lerp(color, Colors.white, 0.3)!;
                });
              },
            ),
            _buildRenkSecici(
              _languageService['text_color'] ?? '',
              _ozelYaziPrimary,
              (color) {
                setState(() {
                  _ozelYaziPrimary = color;
                });
              },
            ),
            _buildRenkSecici(
              _languageService['text_secondary'] ?? '',
              _ozelYaziSecondary,
              (color) {
                setState(() {
                  _ozelYaziSecondary = color;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _temaService.ozelTemayiKaydet(
                    arkaPlan: _ozelArkaPlan,
                    kartArkaPlan: _ozelKartArkaPlan,
                    vurgu: _ozelVurgu,
                    vurguSecondary: _ozelVurguSecondary,
                    yaziPrimary: _ozelYaziPrimary,
                    yaziSecondary: _ozelYaziSecondary,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _languageService['custom_theme_saved'] ?? '',
                        ),
                        backgroundColor: _ozelVurgu,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save),
                label: Text(_languageService['save_custom_theme'] ?? ''),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ozelVurgu,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

  Widget _buildRenkSecici(
    String label,
    Color mevcutRenk,
    Function(Color) onChanged,
  ) {
    final renkler = _temaService.renkler;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(color: renkler.yaziPrimary, fontSize: 14),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showColorPicker(mevcutRenk, onChanged),
            child: Container(
              width: 45,
              height: 32,
              decoration: BoxDecoration(
                color: mevcutRenk,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSecimi(TemaRenkleri renkler) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(_languageService['font_family'] ?? '', style: TextStyle(color: renkler.yaziPrimary)),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _temaService.fontFamily,
              dropdownColor: renkler.kartArkaPlan,
              style: TextStyle(color: renkler.yaziPrimary),
              items: TemaService.fontFamilies
                  .map(
                    (font) => DropdownMenuItem(value: font, child: Text(font)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _temaService.fontuDegistir(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  int _kanal8den10a(int kanal8) {
    return ((kanal8 / 255) * 1023).round().clamp(0, 1023);
  }

  int _kanal10dan8e(int kanal10) {
    return ((kanal10.clamp(0, 1023) / 1023) * 255).round().clamp(0, 255);
  }

  Color _renk10BitOlustur(int r10, int g10, int b10) {
    return Color.fromARGB(
      255,
      _kanal10dan8e(r10),
      _kanal10dan8e(g10),
      _kanal10dan8e(b10),
    );
  }

  Color _renk10BiteHizala(Color renk) {
    return _renk10BitOlustur(
      _kanal8den10a(renk.red),
      _kanal8den10a(renk.green),
      _kanal8den10a(renk.blue),
    );
  }

  String _renkHex(Color renk) {
    return '#${renk.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorSelected) {
    final List<Color> hizliRenkler = [
      const Color(0xFFB05FA5),
      const Color(0xFF5450A6),
      const Color(0xFF2D58A6),
      const Color(0xFF66C2D0),
      const Color(0xFF65BC2A),
      const Color(0xFFE3E230),
      const Color(0xFFF29B1D),
      const Color(0xFFF12711),
    ].map(_renk10BiteHizala).toList();

    final baslangicRenk = _renk10BiteHizala(currentColor);
    final baslangicHsv = HSVColor.fromColor(baslangicRenk);
    final baslangicHue10 =
        ((baslangicHsv.hue / 360) * 1023).round().clamp(0, 1023);

    showModalBottomSheet(
      context: context,
      backgroundColor: _temaService.renkler.kartArkaPlan,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.72,
          expand: false,
          builder: (context, scrollController) {
            int hue10 = baslangicHue10;
            double saturation = baslangicHsv.saturation.clamp(0.35, 1.0);
            double value = baslangicHsv.value.clamp(0.35, 1.0);
            Color seciliRenk = baslangicRenk;

            return StatefulBuilder(
              builder: (context, setSheetState) {
                final hueColors = List<Color>.generate(
                  8,
                  (index) => HSVColor.fromAHSV(
                    1,
                    index * (360 / 7),
                    0.85,
                    0.95,
                  ).toColor(),
                );

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      _languageService['select_color'] ?? '',
                      style: TextStyle(
                        color: _temaService.renkler.yaziPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _renkHex(seciliRenk),
                      style: TextStyle(
                        color: _temaService.renkler.yaziSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 76,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _temaService.renkler.arkaPlan.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: hizliRenkler.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final color = hizliRenkler[index];
                                final isSelected =
                                    seciliRenk.value == color.value;
                                return GestureDetector(
                                  onTap: () {
                                    final hsv = HSVColor.fromColor(color);
                                    setSheetState(() {
                                      seciliRenk = color;
                                      hue10 = ((hsv.hue / 360) * 1023)
                                          .round()
                                          .clamp(0, 1023);
                                      saturation = hsv.saturation;
                                      value = hsv.value;
                                    });
                                    onColorSelected(seciliRenk);
                                  },
                                  child: Container(
                                    width: 36,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white24,
                                        width: isSelected ? 2.5 : 1,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 44,
                            decoration: BoxDecoration(
                              color: seciliRenk,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hueColors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 26,
                          activeTrackColor: Colors.transparent,
                          inactiveTrackColor: Colors.transparent,
                          thumbColor: Colors.white,
                          overlayColor: Colors.white24,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                          ),
                        ),
                        child: Slider(
                          value: hue10.toDouble(),
                          min: 0,
                          max: 1023,
                          divisions: 1023,
                          onChanged: (value10) {
                            setSheetState(() {
                              hue10 = value10.round();
                              seciliRenk = _renk10BiteHizala(
                                HSVColor.fromAHSV(
                                  1,
                                  (hue10 / 1023) * 360,
                                  saturation,
                                  value,
                                ).toColor(),
                              );
                            });
                            onColorSelected(seciliRenk);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hue 10-bit: $hue10',
                      style: TextStyle(
                        color: _temaService.renkler.yaziSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: Text(_languageService['close'] ?? 'Kapat'),
                        style: TextButton.styleFrom(
                          foregroundColor: _temaService.renkler.vurgu,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _renkDairesi(Color renk, double boyut) {
    return Container(
      width: boyut,
      height: boyut,
      decoration: BoxDecoration(
        color: renk,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }
}
