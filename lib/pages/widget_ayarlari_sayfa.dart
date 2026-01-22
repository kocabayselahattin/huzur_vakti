import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/home_widget_service.dart';
import '../services/language_service.dart';
import '../services/widget_pin_service.dart';

/// Widget türleri ve varsayılan ayarları
class WidgetTuru {
  final String id;
  final IconData icon;
  final String varsayilanArkaPlanKey;
  final String varsayilanYaziRengiHex;
  final Color varsayilanRenk1;
  final Color varsayilanRenk2;
  final Color varsayilanYaziRengi;

  const WidgetTuru({
    required this.id,
    required this.icon,
    required this.varsayilanArkaPlanKey,
    required this.varsayilanYaziRengiHex,
    required this.varsayilanRenk1,
    required this.varsayilanRenk2,
    required this.varsayilanYaziRengi,
  });
}

class WidgetAyarlariSayfa extends StatefulWidget {
  const WidgetAyarlariSayfa({super.key});

  @override
  State<WidgetAyarlariSayfa> createState() => _WidgetAyarlariSayfaState();
}

class _WidgetAyarlariSayfaState extends State<WidgetAyarlariSayfa> with SingleTickerProviderStateMixin {
  final LanguageService _languageService = LanguageService();
  late TabController _tabController;
  
  // Her widget için ayrı ayarlar
  final Map<String, int> _secilenArkaPlanIndex = {};
  final Map<String, int> _secilenYaziRengiIndex = {};
  final Map<String, double> _seffaflik = {};
  final Map<String, bool> _seffafTema = {};

  // Widget türleri listesi (orijinal tasarımlara göre)
  static const List<WidgetTuru> _widgetTurleri = [
    WidgetTuru(
      id: 'klasik',
      icon: Icons.wb_sunny,
      varsayilanArkaPlanKey: 'orange',
      varsayilanYaziRengiHex: 'FFFFFF',
      varsayilanRenk1: Color(0xFFFF8C42),
      varsayilanRenk2: Color(0xFFCC5522),
      varsayilanYaziRengi: Colors.white,
    ),
    WidgetTuru(
      id: 'mini',
      icon: Icons.landscape,
      varsayilanArkaPlanKey: 'sunset',
      varsayilanYaziRengiHex: '664422',
      varsayilanRenk1: Color(0xFFFFE4B5),
      varsayilanRenk2: Color(0xFFFFD0A0),
      varsayilanYaziRengi: Color(0xFF664422),
    ),
    WidgetTuru(
      id: 'glass',
      icon: Icons.blur_on,
      varsayilanArkaPlanKey: 'semi_white',
      varsayilanYaziRengiHex: '000000',
      varsayilanRenk1: Color(0x88FFFFFF),
      varsayilanRenk2: Color(0x88FFFFFF),
      varsayilanYaziRengi: Colors.black,
    ),
    WidgetTuru(
      id: 'neon',
      icon: Icons.flash_on,
      varsayilanArkaPlanKey: 'dark',
      varsayilanYaziRengiHex: '00FF88',
      varsayilanRenk1: Color(0xFF1A3A5C),
      varsayilanRenk2: Color(0xFF051525),
      varsayilanYaziRengi: Color(0xFF00FF88),
    ),
    WidgetTuru(
      id: 'cosmic',
      icon: Icons.stars,
      varsayilanArkaPlanKey: 'purple',
      varsayilanYaziRengiHex: 'FFFFFF',
      varsayilanRenk1: Color(0xFF7B1FA2),
      varsayilanRenk2: Color(0xFF4A148C),
      varsayilanYaziRengi: Colors.white,
    ),
    WidgetTuru(
      id: 'timeline',
      icon: Icons.timeline,
      varsayilanArkaPlanKey: 'dark',
      varsayilanYaziRengiHex: 'FFFFFF',
      varsayilanRenk1: Color(0xFF1A3A5C),
      varsayilanRenk2: Color(0xFF051525),
      varsayilanYaziRengi: Colors.white,
    ),
    WidgetTuru(
      id: 'zen',
      icon: Icons.spa,
      varsayilanArkaPlanKey: 'light',
      varsayilanYaziRengiHex: '212121',
      varsayilanRenk1: Color(0xFFFFF8F0),
      varsayilanRenk2: Color(0xFFFFE8D8),
      varsayilanYaziRengi: Color(0xFF212121),
    ),
    WidgetTuru(
      id: 'origami',
      icon: Icons.auto_awesome,
      varsayilanArkaPlanKey: 'light',
      varsayilanYaziRengiHex: '2D3436',
      varsayilanRenk1: Color(0xFFFFF8F0),
      varsayilanRenk2: Color(0xFFFFE8D8),
      varsayilanYaziRengi: Color(0xFF2D3436),
    ),
  ];

  final List<Map<String, dynamic>> _arkaPlanSecenekleri = [
    {
      'isim': 'Turuncu Gradient',
      'renk1': Color(0xFFFF8C42),
      'renk2': Color(0xFFCC5522),
      'key': 'orange',
    },
    {
      'isim': 'Açık Krem',
      'renk1': Color(0xFFFFF8F0),
      'renk2': Color(0xFFFFE8D8),
      'key': 'light',
    },
    {
      'isim': 'Koyu Mavi',
      'renk1': Color(0xFF1A3A5C),
      'renk2': Color(0xFF051525),
      'key': 'dark',
    },
    {
      'isim': 'Gün Batımı',
      'renk1': Color(0xFFFFE4B5),
      'renk2': Color(0xFFFFD0A0),
      'key': 'sunset',
    },
    {
      'isim': 'Yeşil',
      'renk1': Color(0xFF2E7D32),
      'renk2': Color(0xFF1B5E20),
      'key': 'green',
    },
    {
      'isim': 'Mor',
      'renk1': Color(0xFF7B1FA2),
      'renk2': Color(0xFF4A148C),
      'key': 'purple',
    },
    {
      'isim': 'Kırmızı',
      'renk1': Color(0xFFD32F2F),
      'renk2': Color(0xFFB71C1C),
      'key': 'red',
    },
    {
      'isim': 'Mavi',
      'renk1': Color(0xFF1976D2),
      'renk2': Color(0xFF0D47A1),
      'key': 'blue',
    },
    {
      'isim': 'Turkuaz',
      'renk1': Color(0xFF00ACC1),
      'renk2': Color(0xFF006064),
      'key': 'teal',
    },
    {
      'isim': 'Pembe',
      'renk1': Color(0xFFE91E63),
      'renk2': Color(0xFFC2185B),
      'key': 'pink',
    },
    {
      'isim': 'Şeffaf',
      'renk1': Colors.transparent,
      'renk2': Colors.transparent,
      'key': 'transparent',
    },
    {
      'isim': 'Yarı Şeffaf Siyah',
      'renk1': Color(0x88000000),
      'renk2': Color(0x88000000),
      'key': 'semi_black',
    },
    {
      'isim': 'Yarı Şeffaf Beyaz',
      'renk1': Color(0x88FFFFFF),
      'renk2': Color(0x88FFFFFF),
      'key': 'semi_white',
    },
  ];

  final List<Map<String, dynamic>> _yaziRengiSecenekleri = [
    {'isim': 'Beyaz', 'renk': Colors.white, 'hex': 'FFFFFF'},
    {'isim': 'Siyah', 'renk': Colors.black, 'hex': '000000'},
    {'isim': 'Turuncu', 'renk': Color(0xFFFF8C42), 'hex': 'FF8C42'},
    {'isim': 'Altın', 'renk': Color(0xFFFFD700), 'hex': 'FFD700'},
    {'isim': 'Açık Mavi', 'renk': Color(0xFFAADDFF), 'hex': 'AADDFF'},
    {'isim': 'Yeşil', 'renk': Color(0xFF4CAF50), 'hex': '4CAF50'},
    {'isim': 'Kırmızı', 'renk': Color(0xFFF44336), 'hex': 'F44336'},
    {'isim': 'Sarı', 'renk': Color(0xFFFFEB3B), 'hex': 'FFEB3B'},
    {'isim': 'Pembe', 'renk': Color(0xFFE91E63), 'hex': 'E91E63'},
    {'isim': 'Mor', 'renk': Color(0xFF9C27B0), 'hex': '9C27B0'},
    {'isim': 'Cyan', 'renk': Color(0xFF00BCD4), 'hex': '00BCD4'},
    {'isim': 'Gri', 'renk': Color(0xFF9E9E9E), 'hex': '9E9E9E'},
    {'isim': 'Kahverengi', 'renk': Color(0xFF664422), 'hex': '664422'},
    {'isim': 'Neon Yeşil', 'renk': Color(0xFF00FF88), 'hex': '00FF88'},
    {'isim': 'Koyu Gri', 'renk': Color(0xFF212121), 'hex': '212121'},
    {'isim': 'Grafit', 'renk': Color(0xFF2D3436), 'hex': '2D3436'},
  ];

  bool _canPinWidgets = false;

  /// Widget id'sine göre yerelleştirilmiş isim döndür
  String _getWidgetIsim(String id) {
    final key = 'widget_$id';
    final fallbacks = {
      'klasik': 'Klasik Turuncu',
      'mini': 'Mini Sunset',
      'glass': 'Glassmorphism',
      'neon': 'Neon Glow',
      'cosmic': 'Cosmic',
      'timeline': 'Timeline',
      'zen': 'Zen',
      'origami': 'Origami',
    };
    return _languageService[key] ?? fallbacks[id] ?? id;
  }

  /// Widget id'sine göre yerelleştirilmiş açıklama döndür
  String _getWidgetAciklama(String id) {
    final key = 'widget_${id}_desc';
    final fallbacks = {
      'klasik': 'Sıcak turuncu tonları ile klasik tasarım',
      'mini': 'Gün batımı renkleriyle kompakt tasarım',
      'glass': 'Şeffaf cam efektli modern tasarım',
      'neon': 'Parlayan neon efektli modern tasarım',
      'cosmic': 'Kozmik mor tonları ile uzay teması',
      'timeline': 'Koyu temalı timeline tasarımı',
      'zen': 'Minimal ve huzurlu açık tasarım',
      'origami': 'Kağıt katlama estetiği ile zarif tasarım',
    };
    return _languageService[key] ?? fallbacks[id] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _widgetTurleri.length, vsync: this);
    _ayarlariYukle();
    _checkPinSupport();
  }

  Future<void> _checkPinSupport() async {
    final canPin = await WidgetPinService.canPinWidgets();
    if (mounted) {
      setState(() {
        _canPinWidgets = canPin;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _arkaPlanKeyToIndex(String key) {
    final index = _arkaPlanSecenekleri.indexWhere((e) => e['key'] == key);
    return index >= 0 ? index : 0;
  }

  int _yaziRengiHexToIndex(String hex) {
    final index = _yaziRengiSecenekleri.indexWhere((e) => e['hex'] == hex);
    return index >= 0 ? index : 0;
  }

  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      for (final widget in _widgetTurleri) {
        final id = widget.id;
        
        // Her widget için kaydedilmiş ayarları yükle, yoksa varsayılanı kullan
        final savedArkaPlanKey = prefs.getString('widget_${id}_arkaplan_key');
        final savedYaziRengiHex = prefs.getString('widget_${id}_yazi_rengi_hex');
        
        if (savedArkaPlanKey != null) {
          _secilenArkaPlanIndex[id] = _arkaPlanKeyToIndex(savedArkaPlanKey);
        } else {
          _secilenArkaPlanIndex[id] = _arkaPlanKeyToIndex(widget.varsayilanArkaPlanKey);
        }
        
        if (savedYaziRengiHex != null) {
          _secilenYaziRengiIndex[id] = _yaziRengiHexToIndex(savedYaziRengiHex);
        } else {
          _secilenYaziRengiIndex[id] = _yaziRengiHexToIndex(widget.varsayilanYaziRengiHex);
        }
        
        _seffaflik[id] = (prefs.getDouble('widget_${id}_seffaflik') ?? 1.0).clamp(0.3, 1.0);
        _seffafTema[id] = prefs.getBool('widget_${id}_seffaf_tema') ?? false;
      }
    });
  }

  Future<void> _widgetAyarlariniKaydet(String widgetId) async {
    final prefs = await SharedPreferences.getInstance();
    
    final arkaPlanIndex = _secilenArkaPlanIndex[widgetId] ?? 0;
    final yaziRengiIndex = _secilenYaziRengiIndex[widgetId] ?? 0;
    final seffaflik = _seffaflik[widgetId] ?? 1.0;
    final seffafTema = _seffafTema[widgetId] ?? false;
    
    final arkaPlan = _arkaPlanSecenekleri[arkaPlanIndex];
    final yaziRengi = _yaziRengiSecenekleri[yaziRengiIndex];
    
    // Widget'a özel ayarları kaydet
    await prefs.setString('widget_${widgetId}_arkaplan_key', arkaPlan['key']);
    await prefs.setString('widget_${widgetId}_yazi_rengi_hex', yaziRengi['hex']);
    await prefs.setDouble('widget_${widgetId}_seffaflik', seffaflik);
    await prefs.setBool('widget_${widgetId}_seffaf_tema', seffafTema);
    
    // Widget verilerini güncelle
    await HomeWidgetService.updateWidgetColorsForWidget(
      widgetId: widgetId,
      arkaPlanKey: arkaPlan['key'],
      yaziRengiHex: yaziRengi['hex'],
      seffaflik: seffafTema ? 0.0 : seffaflik,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getWidgetIsim(widgetId)} ${_languageService['settings_applied'] ?? 'ayarları kaydedildi'}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _widgetVarsayilanaGetir(String widgetId) async {
    final widget = _widgetTurleri.firstWhere((w) => w.id == widgetId);
    
    setState(() {
      _secilenArkaPlanIndex[widgetId] = _arkaPlanKeyToIndex(widget.varsayilanArkaPlanKey);
      _secilenYaziRengiIndex[widgetId] = _yaziRengiHexToIndex(widget.varsayilanYaziRengiHex);
      _seffaflik[widgetId] = 1.0;
      _seffafTema[widgetId] = false;
    });

    await _widgetAyarlariniKaydet(widgetId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getWidgetIsim(widget.id)} ${_languageService['reset_to_original'] ?? 'orijinal tasarımına döndürüldü'}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _tumWidgetlariVarsayilanaGetir() async {
    for (final widget in _widgetTurleri) {
      setState(() {
        _secilenArkaPlanIndex[widget.id] = _arkaPlanKeyToIndex(widget.varsayilanArkaPlanKey);
        _secilenYaziRengiIndex[widget.id] = _yaziRengiHexToIndex(widget.varsayilanYaziRengiHex);
        _seffaflik[widget.id] = 1.0;
        _seffafTema[widget.id] = false;
      });
      await _widgetAyarlariniKaydet(widget.id);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_languageService['all_widgets_reset'] ?? 'Tüm widget\'lar orijinal tasarımlarına döndürüldü'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// Widget'ı ekrana ekleme dialogu göster
  Future<void> _widgetEkranaEkleDialoguGoster(String widgetId) async {
    final widget = _widgetTurleri.firstWhere((w) => w.id == widgetId);
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_to_home_screen, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_getWidgetIsim(widget.id)} ${_languageService['add'] ?? 'Ekle'}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getWidgetIsim(widget.id)} ${_languageService['add_widget_question'] ?? 'widget\'ını ana ekranınıza eklemek istiyor musunuz?'}',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _languageService['widget_pin_warning'] ?? 
                      'Kabul ederseniz ana ekranınızdaki uygulama kısayollarının yeri değişebilir.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_languageService['cancel'] ?? 'İptal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.add, size: 18),
            label: Text(_languageService['add'] ?? 'Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      // Önce ayarları kaydet
      await _widgetAyarlariniKaydet(widgetId);
      
      // Widget'ı ekrana ekle
      final success = await WidgetPinService.pinWidget(widgetId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getWidgetIsim(widget.id)} ${_languageService['widget_pin_sent'] ?? 'ekleme isteği gönderildi'}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_languageService['widget_pin_not_supported'] ?? 
                'Bu cihaz widget eklemeyi desteklemiyor'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_languageService['widget_settings_title'] ?? 'Widget Ayarları'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _widgetTurleri.map((w) => Tab(
            icon: Icon(w.icon, size: 20),
            text: _getWidgetIsim(w.id).split(' ').first,
          )).toList(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'reset_all') {
                _tumWidgetlariVarsayilanaGetir();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset_all',
                child: Row(
                  children: [
                    const Icon(Icons.restore, size: 20),
                    const SizedBox(width: 8),
                    Text(_languageService['reset_all_widgets'] ?? 'Tümünü Varsayılana Dön'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _widgetTurleri.map((widget) => 
          _buildWidgetAyarlari(widget, isDark)
        ).toList(),
      ),
    );
  }

  Widget _buildWidgetAyarlari(WidgetTuru widget, bool isDark) {
    final id = widget.id;
    final arkaPlanIndex = _secilenArkaPlanIndex[id] ?? 0;
    final yaziRengiIndex = _secilenYaziRengiIndex[id] ?? 0;
    final seffaflik = _seffaflik[id] ?? 1.0;
    final seffafTema = _seffafTema[id] ?? false;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Widget Bilgisi
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.varsayilanRenk1, widget.varsayilanRenk2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: widget.varsayilanYaziRengi, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getWidgetIsim(widget.id),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getWidgetAciklama(widget.id),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Önizleme
        _buildOnizleme(id, isDark, arkaPlanIndex, yaziRengiIndex, seffaflik, seffafTema),
        const SizedBox(height: 24),

        // Şeffaf Tema Switch
        Card(
          child: SwitchListTile(
            title: Text(_languageService['transparent_theme'] ?? 'Şeffaf Tema'),
            subtitle: Text(_languageService['transparent_theme_description'] ?? 'Arka planı tamamen şeffaf yapar'),
            value: seffafTema,
            onChanged: (value) {
              setState(() {
                _seffafTema[id] = value;
                if (value) {
                  _secilenArkaPlanIndex[id] = 10; // Şeffaf seçeneği
                }
              });
            },
            secondary: Icon(Icons.opacity, color: Theme.of(context).colorScheme.primary),
          ),
        ),
        const SizedBox(height: 16),

        // Arka Plan Rengi Seçimi
        if (!seffafTema) ...[
          Text(
            _languageService['background_color'] ?? 'Arka Plan Rengi',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildArkaPlanSecimi(id, arkaPlanIndex),
          const SizedBox(height: 24),

          // Şeffaflık Ayarı
          Text(
            '${_languageService['opacity'] ?? 'Şeffaflık'}: ${(seffaflik * 100).toInt()}%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Slider(
            value: seffaflik.clamp(0.3, 1.0),
            min: 0.3,
            max: 1.0,
            divisions: 7,
            label: '${(seffaflik * 100).toInt()}%',
            onChanged: (value) {
              setState(() {
                _seffaflik[id] = value;
              });
            },
          ),
          const SizedBox(height: 24),
        ],

        // Yazı Rengi Seçimi
        Text(
          _languageService['text_color'] ?? 'Yazı Rengi',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildYaziRengiSecimi(id, yaziRengiIndex),
        const SizedBox(height: 32),

        // Bilgi
        Card(
          color: Color.fromRGBO(
            Theme.of(context).colorScheme.primaryContainer.red,
            Theme.of(context).colorScheme.primaryContainer.green,
            Theme.of(context).colorScheme.primaryContainer.blue,
            0.3,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _languageService['widget_specific_info'] ?? 
                    'Bu ayarlar sadece seçili widget\'a uygulanır. Widget\'ı kaldırıp tekrar ekleyin.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Varsayılana Dön Butonu
        OutlinedButton.icon(
          onPressed: () => _widgetVarsayilanaGetir(id),
          icon: const Icon(Icons.restore),
          label: Text('${_getWidgetIsim(widget.id)} ${_languageService['reset_to_default'] ?? 'Varsayılana Dön'}'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
          ),
        ),
        const SizedBox(height: 12),

        // Kaydet Butonu
        ElevatedButton.icon(
          onPressed: () => _widgetAyarlariniKaydet(id),
          icon: const Icon(Icons.save),
          label: Text(_languageService['save_settings'] ?? 'Ayarları Kaydet'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Ekrana Ekle Butonu (Android 8.0+ destekliyorsa)
        if (_canPinWidgets)
          ElevatedButton.icon(
            onPressed: () => _widgetEkranaEkleDialoguGoster(id),
            icon: const Icon(Icons.add_to_home_screen),
            label: Text(_languageService['add_to_home_screen'] ?? 'Ana Ekrana Ekle'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOnizleme(String widgetId, bool isDark, int arkaPlanIndex, int yaziRengiIndex, double seffaflik, bool seffafTema) {
    final arkaPlan = _arkaPlanSecenekleri[arkaPlanIndex];
    final yaziRengi = _yaziRengiSecenekleri[yaziRengiIndex]['renk'] as Color;
    final yaziRengiSecondary = Color.fromRGBO(yaziRengi.red, yaziRengi.green, yaziRengi.blue, 0.7);

    final Color renk1 = seffafTema
        ? Colors.transparent
        : Color.fromRGBO(
            (arkaPlan['renk1'] as Color).red,
            (arkaPlan['renk1'] as Color).green,
            (arkaPlan['renk1'] as Color).blue,
            seffaflik,
          );
    final Color renk2 = seffafTema
        ? Colors.transparent
        : Color.fromRGBO(
            (arkaPlan['renk2'] as Color).red,
            (arkaPlan['renk2'] as Color).green,
            (arkaPlan['renk2'] as Color).blue,
            seffaflik,
          );

    // Her widget türü için özel önizleme
    switch (widgetId) {
      case 'klasik':
        return _buildKlasikOnizleme(renk1, renk2, yaziRengi, yaziRengiSecondary, seffafTema, isDark);
      case 'mini':
        return _buildMiniOnizleme(renk1, renk2, yaziRengi, yaziRengiSecondary, seffafTema, isDark);
      case 'glass':
        return _buildGlassOnizleme(renk1, renk2, yaziRengi, yaziRengiSecondary, seffafTema, isDark);
      case 'neon':
        return _buildNeonOnizleme(renk1, renk2, yaziRengi, yaziRengiSecondary, seffafTema, isDark);
      case 'cosmic':
        return _buildCosmicOnizleme(renk1, renk2, yaziRengi, yaziRengiSecondary, seffafTema, isDark);
      case 'timeline':
        return _buildTimelineOnizleme(renk1, renk2, yaziRengi, yaziRengiSecondary, seffafTema, isDark);
      case 'zen':
        return _buildZenOnizleme(renk1, renk2, yaziRengi, yaziRengiSecondary, seffafTema, isDark);
      case 'origami':
        return _buildOrigamiOnizleme(renk1, renk2, yaziRengi, yaziRengiSecondary, seffafTema, isDark);
      default:
        return _buildKlasikOnizleme(renk1, renk2, yaziRengi, yaziRengiSecondary, seffafTema, isDark);
    }
  }

  // ==================== KLASİK TURUNCU WİDGET ====================
  Widget _buildKlasikOnizleme(Color renk1, Color renk2, Color yaziRengi, Color yaziRengiSecondary, bool seffafTema, bool isDark) {
    return _buildOnizlemeContainer(renk1, renk2, seffafTema, isDark, 160,
      Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst: Başlık ve sonraki vakit
            Row(
              children: [
                Text('NAMAZ', style: TextStyle(color: yaziRengi, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(' VAKTİ', style: TextStyle(color: yaziRengiSecondary, fontSize: 10)),
                const Spacer(),
                Text('İmsak Vaktine Kalan', style: TextStyle(color: yaziRengiSecondary, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 4),
            // Orta: Sayaç ve Tarih
            Row(
              children: [
                Text('07:25:12', style: TextStyle(color: yaziRengi, fontSize: 28, fontWeight: FontWeight.bold)),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('28 Recep 1447', style: TextStyle(color: yaziRengi, fontSize: 11)),
                    Text('İSTANBUL', style: TextStyle(color: yaziRengiSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // Alt: 6 vakit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _vakitKutusu('İmsak', '05:47', yaziRengi, yaziRengiSecondary, true),
                _vakitKutusu('Güneş', '07:22', yaziRengi, yaziRengiSecondary, false),
                _vakitKutusu('Öğle', '12:30', yaziRengi, yaziRengiSecondary, false),
                _vakitKutusu('İkindi', '15:14', yaziRengi, yaziRengiSecondary, false),
                _vakitKutusu('Akşam', '17:32', yaziRengi, yaziRengiSecondary, false),
                _vakitKutusu('Yatsı', '18:57', yaziRengi, yaziRengiSecondary, false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vakitKutusu(String isim, String saat, Color yaziRengi, Color yaziRengiSecondary, bool aktif) {
    return Column(
      children: [
        Text(isim, style: TextStyle(color: aktif ? yaziRengi : yaziRengiSecondary, fontSize: 8)),
        Text(saat, style: TextStyle(color: aktif ? yaziRengi : yaziRengiSecondary, fontSize: 10, fontWeight: aktif ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  // ==================== MİNİ SUNSET WİDGET ====================
  Widget _buildMiniOnizleme(Color renk1, Color renk2, Color yaziRengi, Color yaziRengiSecondary, bool seffafTema, bool isDark) {
    return _buildOnizlemeContainer(renk1, renk2, seffafTema, isDark, 120,
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst: Konum ve tarih
            Row(
              children: [
                Text('İstanbul, Küçükçekmece', style: TextStyle(color: yaziRengi, fontSize: 11, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('28 Recep • 17 Ocak', style: TextStyle(color: yaziRengiSecondary, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 8),
            // Orta: Geri sayım
            Row(
              children: [
                Text('18:39', style: TextStyle(color: yaziRengi, fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('Akşam Vaktine Kalan', style: TextStyle(color: yaziRengiSecondary, fontSize: 10)),
              ],
            ),
            const Spacer(),
            // Alt: Ecir barı
            Row(
              children: [
                Text('ECİR', style: TextStyle(color: const Color(0xFF00C853), fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: yaziRengiSecondary.withValues(alpha: 0.3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: const Color(0xFF00C853),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('60%', style: TextStyle(color: const Color(0xFF00C853), fontSize: 9)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== GLASSMORPHISM WİDGET ====================
  Widget _buildGlassOnizleme(Color renk1, Color renk2, Color yaziRengi, Color yaziRengiSecondary, bool seffafTema, bool isDark) {
    return _buildOnizlemeContainer(renk1, renk2, seffafTema, isDark, 140,
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Üst
            Text('Şu an Güneş vaktinde', style: TextStyle(color: yaziRengiSecondary, fontSize: 10)),
            Text('28 Recep 1447', style: TextStyle(color: yaziRengi, fontSize: 11)),
            Text('21 Ocak 2026', style: TextStyle(color: yaziRengiSecondary, fontSize: 10)),
            const Spacer(),
            // Orta
            Text("Öğle'ye", style: TextStyle(color: yaziRengi, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('02:30:45', style: TextStyle(color: yaziRengi, fontSize: 28, fontWeight: FontWeight.w200, letterSpacing: 2)),
            const Spacer(),
            // Alt: Progress
            Text('Vakit İlerlemesi', style: TextStyle(color: yaziRengiSecondary, fontSize: 8)),
            const SizedBox(height: 4),
            Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: yaziRengiSecondary.withValues(alpha: 0.3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: yaziRengi,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Konum
            Text('İstanbul', style: TextStyle(color: yaziRengiSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ==================== NEON GLOW WİDGET ====================
  Widget _buildNeonOnizleme(Color renk1, Color renk2, Color yaziRengi, Color yaziRengiSecondary, bool seffafTema, bool isDark) {
    final neonColor = yaziRengi;
    final pinkNeon = Color.lerp(yaziRengi, Colors.pink, 0.5) ?? Colors.pink;
    
    return _buildOnizlemeContainer(renk1, renk2, seffafTema, isDark, 150,
      Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Üst sol: Badge
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: neonColor.withValues(alpha: 0.5)),
                    ),
                    child: Text('Güneş', style: TextStyle(color: neonColor, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Spacer(),
                // Orta
                Text('ÖĞLE', style: TextStyle(color: pinkNeon, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, shadows: [Shadow(color: pinkNeon, blurRadius: 10)])),
                const SizedBox(height: 4),
                Text('02:30:45', style: TextStyle(color: neonColor, fontSize: 30, fontWeight: FontWeight.bold, fontFamily: 'monospace', shadows: [Shadow(color: neonColor, blurRadius: 15)])),
                const Spacer(),
                // Alt
                Row(
                  children: [
                    Text('⚡ VAKİT İLERLEMESİ', style: TextStyle(color: pinkNeon, fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: neonColor.withValues(alpha: 0.2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(colors: [neonColor, pinkNeon]),
                        boxShadow: [BoxShadow(color: neonColor, blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('İstanbul', style: TextStyle(color: yaziRengiSecondary, fontSize: 9)),
                    Text('28 Recep 1447', style: TextStyle(color: yaziRengiSecondary, fontSize: 9)),
                    Text('21 Ocak 2026', style: TextStyle(color: yaziRengiSecondary, fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== COSMIC WİDGET ====================
  Widget _buildCosmicOnizleme(Color renk1, Color renk2, Color yaziRengi, Color yaziRengiSecondary, bool seffafTema, bool isDark) {
    final purpleAccent = Color.lerp(yaziRengi, Colors.purple, 0.3) ?? Colors.purple;
    
    return _buildOnizlemeContainer(renk1, renk2, seffafTema, isDark, 150,
      Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Üst
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('İstanbul', style: TextStyle(color: purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('28 Recep 1447', style: TextStyle(color: yaziRengiSecondary, fontSize: 10)),
                    Text('21 Ocak 2026', style: TextStyle(color: yaziRengiSecondary.withValues(alpha: 0.5), fontSize: 9)),
                  ],
                ),
                const Spacer(),
                Text('✧', style: TextStyle(color: Colors.cyan, fontSize: 20)),
              ],
            ),
            const Spacer(),
            // Orta
            Text('✦ Güneş ✦', style: TextStyle(color: purpleAccent, fontSize: 10, letterSpacing: 2)),
            Text('02:30:45', style: TextStyle(color: yaziRengi, fontSize: 32, fontWeight: FontWeight.bold, shadows: [Shadow(color: purpleAccent, blurRadius: 20)])),
            Text("Öğle'ye kalan", style: TextStyle(color: yaziRengiSecondary, fontSize: 10)),
            const Spacer(),
            // Alt
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: [Colors.purple.withValues(alpha: 0.3), Colors.cyan.withValues(alpha: 0.3)]),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(colors: [Colors.purple, Colors.cyan]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TIMELINE WİDGET ====================
  Widget _buildTimelineOnizleme(Color renk1, Color renk2, Color yaziRengi, Color yaziRengiSecondary, bool seffafTema, bool isDark) {
    final greenAccent = const Color(0xFF4CAF50);
    
    return _buildOnizlemeContainer(renk1, renk2, seffafTema, isDark, 160,
      Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Başlık
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('İstanbul', style: TextStyle(color: yaziRengi, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('28 Recep 1447', style: TextStyle(color: yaziRengiSecondary, fontSize: 10)),
                    Text('21 Ocak 2026', style: TextStyle(color: yaziRengiSecondary.withValues(alpha: 0.6), fontSize: 9)),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Öğle'ye", style: TextStyle(color: greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text('02:30:45', style: TextStyle(color: greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Ana Progress
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: yaziRengiSecondary.withValues(alpha: 0.3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: greenAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Vakit listesi (2 sütun)
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _timelineVakit('İmsak', '05:47', yaziRengi, yaziRengiSecondary, true),
                      _timelineVakit('Güneş', '07:22', yaziRengi, yaziRengiSecondary, false),
                      _timelineVakit('Öğle', '12:30', yaziRengi, yaziRengiSecondary, false),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _timelineVakit('İkindi', '15:14', yaziRengi, yaziRengiSecondary, false),
                      _timelineVakit('Akşam', '17:32', yaziRengi, yaziRengiSecondary, false),
                      _timelineVakit('Yatsı', '18:57', yaziRengi, yaziRengiSecondary, false),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineVakit(String isim, String saat, Color yaziRengi, Color yaziRengiSecondary, bool aktif) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aktif ? const Color(0xFF4CAF50) : yaziRengiSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          Text(isim, style: TextStyle(color: aktif ? yaziRengi : yaziRengiSecondary, fontSize: 9)),
          const Spacer(),
          Text(saat, style: TextStyle(color: aktif ? yaziRengi : yaziRengiSecondary, fontSize: 9, fontWeight: aktif ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  // ==================== ZEN WİDGET ====================
  Widget _buildZenOnizleme(Color renk1, Color renk2, Color yaziRengi, Color yaziRengiSecondary, bool seffafTema, bool isDark) {
    return _buildOnizlemeContainer(renk1, renk2, seffafTema, isDark, 130,
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('İSTANBUL', style: TextStyle(color: yaziRengiSecondary, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('02:30', style: TextStyle(color: yaziRengi, fontSize: 36, fontWeight: FontWeight.w200)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Öğle', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(' vaktine', style: TextStyle(color: yaziRengiSecondary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: yaziRengiSecondary.withValues(alpha: 0.3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ORIGAMI WİDGET ====================
  Widget _buildOrigamiOnizleme(Color renk1, Color renk2, Color yaziRengi, Color yaziRengiSecondary, bool seffafTema, bool isDark) {
    return _buildOnizlemeContainer(renk1, renk2, seffafTema, isDark, 150,
      Stack(
        children: [
          // Köşe katlama efekti
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [yaziRengiSecondary.withValues(alpha: 0.3), Colors.transparent],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Üst
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('İstanbul', style: TextStyle(color: yaziRengi, fontSize: 12, fontStyle: FontStyle.italic, fontFamily: 'serif')),
                        Text('٢٨ رجب ١٤٤٧', style: TextStyle(color: yaziRengiSecondary, fontSize: 11, fontFamily: 'serif')),
                        Text('21 Ocak 2026', style: TextStyle(color: yaziRengiSecondary.withValues(alpha: 0.8), fontSize: 10, fontFamily: 'serif')),
                      ],
                    ),
                    const Spacer(),
                    Text('◯', style: TextStyle(color: yaziRengi.withValues(alpha: 0.3), fontSize: 18)),
                  ],
                ),
                const Spacer(),
                // Orta
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('───', style: TextStyle(color: yaziRengiSecondary.withValues(alpha: 0.5), fontSize: 8)),
                    const SizedBox(width: 8),
                    Text('Güneş Vakti', style: TextStyle(color: yaziRengiSecondary, fontSize: 10, fontStyle: FontStyle.italic, fontFamily: 'serif')),
                    const SizedBox(width: 8),
                    Text('───', style: TextStyle(color: yaziRengiSecondary.withValues(alpha: 0.5), fontSize: 8)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('02:30:45', style: TextStyle(color: yaziRengi, fontSize: 30, fontFamily: 'serif')),
                Text("Öğle'ye kalan", style: TextStyle(color: yaziRengiSecondary, fontSize: 10, fontFamily: 'serif')),
                const Spacer(),
                // Alt: Progress
                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    color: yaziRengiSecondary.withValues(alpha: 0.2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: yaziRengi.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ORTAK CONTAINER ====================
  Widget _buildOnizlemeContainer(Color renk1, Color renk2, bool seffafTema, bool isDark, double height, Widget child) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: seffafTema
            ? null
            : LinearGradient(
                colors: [renk1, renk2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: seffafTema ? Colors.transparent : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          if (seffafTema)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CustomPaint(
                  painter: CheckerboardPainter(),
                  size: Size.infinite,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildArkaPlanSecimi(String widgetId, int selectedIndex) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _arkaPlanSecenekleri.length,
      itemBuilder: (context, index) {
        final secenek = _arkaPlanSecenekleri[index];
        final isSelected = selectedIndex == index;
        final isTransparent = secenek['key'] == 'transparent';

        return GestureDetector(
          onTap: () {
            setState(() {
              _secilenArkaPlanIndex[widgetId] = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: isTransparent
                  ? null
                  : LinearGradient(
                      colors: [secenek['renk1'], secenek['renk2']],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Stack(
              children: [
                if (isTransparent)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CustomPaint(
                      painter: CheckerboardPainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                Center(
                  child: Text(
                    secenek['isim'].split(' ').first,
                    style: TextStyle(
                      color:
                          isTransparent ||
                              (secenek['renk1'] as Color).computeLuminance() >
                                  0.5
                          ? Colors.black
                          : Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildYaziRengiSecimi(String widgetId, int selectedIndex) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _yaziRengiSecenekleri.length,
      itemBuilder: (context, index) {
        final secenek = _yaziRengiSecenekleri[index];
        final isSelected = selectedIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              _secilenYaziRengiIndex[widgetId] = index;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: secenek['renk'],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: (secenek['renk'] as Color).computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    size: 20,
                  )
                : null,
          ),
        );
      },
    );
  }
}

/// Şeffaf arka plan göstermek için kareli desen
class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 8.0;
    final paint1 = Paint()..color = Colors.grey.shade300;
    final paint2 = Paint()..color = Colors.grey.shade100;

    for (double x = 0; x < size.width; x += cellSize) {
      for (double y = 0; y < size.height; y += cellSize) {
        final isEven = ((x / cellSize) + (y / cellSize)).toInt() % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
