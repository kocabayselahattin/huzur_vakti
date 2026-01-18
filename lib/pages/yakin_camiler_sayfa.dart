import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/tema_service.dart';

class YakinCamilerSayfa extends StatefulWidget {
  const YakinCamilerSayfa({super.key});

  @override
  State<YakinCamilerSayfa> createState() => _YakinCamilerSayfaState();
}

class _YakinCamilerSayfaState extends State<YakinCamilerSayfa> {
  final TemaService _temaService = TemaService();
  List<Map<String, dynamic>> _camiler = [];
  bool _yukleniyor = true;
  String? _hata;
  Position? _konum;

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onTemaChanged);
    _camileriYukle();
  }

  @override
  void dispose() {
    _temaService.removeListener(_onTemaChanged);
    super.dispose();
  }

  void _onTemaChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _camileriYukle() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      // Konum izni kontrolü
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _hata = 'Konum izni reddedildi';
            _yukleniyor = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _hata = 'Konum izni kalıcı olarak reddedildi. Ayarlardan izin verin.';
          _yukleniyor = false;
        });
        return;
      }

      // Konum servisinin açık olup olmadığını kontrol et
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _hata = 'Konum servisi kapalı. Lütfen açın.';
          _yukleniyor = false;
        });
        return;
      }

      // Mevcut konumu al
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      setState(() {
        _konum = position;
      });

      // Overpass API ile yakındaki camileri bul
      await _yakinCamileriAra(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _hata = 'Konum alınamadı: $e';
        _yukleniyor = false;
      });
    }
  }

  Future<void> _yakinCamileriAra(double enlem, double boylam) async {
    try {
      // Overpass API sorgusu (5km yarıçapında camiler)
      final query = '''
        [out:json];
        (
          node["amenity"="place_of_worship"]["religion"="muslim"](around:5000,$enlem,$boylam);
          way["amenity"="place_of_worship"]["religion"="muslim"](around:5000,$enlem,$boylam);
          relation["amenity"="place_of_worship"]["religion"="muslim"](around:5000,$enlem,$boylam);
        );
        out body;
        >;
        out skel qt;
      ''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        final List<Map<String, dynamic>> camiler = [];
        for (final element in elements) {
          if (element['type'] == 'node') {
            final lat = element['lat'] as double;
            final lon = element['lon'] as double;
            final tags = element['tags'] as Map<String, dynamic>?;

            if (tags != null) {
              final mesafe = Geolocator.distanceBetween(
                enlem,
                boylam,
                lat,
                lon,
              );

              camiler.add({
                'ad': tags['name'] ?? 'İsimsiz Cami',
                'enlem': lat,
                'boylam': lon,
                'mesafe': mesafe,
                'adres': tags['addr:street'] ?? '',
              });
            }
          }
        }

        // Mesafeye göre sırala
        camiler.sort((a, b) => (a['mesafe'] as double).compareTo(b['mesafe'] as double));

        setState(() {
          _camiler = camiler;
          _yukleniyor = false;
        });
      } else {
        setState(() {
          _hata = 'Camiler yüklenemedi';
          _yukleniyor = false;
        });
      }
    } catch (e) {
      setState(() {
        _hata = 'Camiler aranırken hata oluştu: $e';
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text(
          'Yakındaki Camiler',
          style: TextStyle(color: renkler.yaziPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _camileriYukle,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _yukleniyor
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: renkler.vurgu),
                  const SizedBox(height: 16),
                  Text(
                    'Yakındaki camiler aranıyor...',
                    style: TextStyle(
                      color: renkler.yaziSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _hata != null
              ? _hataMesaji(renkler)
              : _camileriGoster(renkler),
    );
  }

  Widget _hataMesaji(TemaRenkleri renkler) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              _hata!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: renkler.yaziPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _camileriYukle,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: renkler.vurgu,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _camileriGoster(TemaRenkleri renkler) {
    if (_camiler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mosque,
              size: 80,
              color: renkler.yaziSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Yakınınızda cami bulunamadı',
              style: TextStyle(
                color: renkler.yaziSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '5 km yarıçapında arama yapılıyor',
              style: TextStyle(
                color: renkler.yaziSecondary.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Bilgi banner
        if (_konum != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: renkler.kartArkaPlan,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: renkler.ayirac.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: renkler.vurgu, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mevcut Konumunuz',
                        style: TextStyle(
                          color: renkler.yaziPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_camiler.length} cami bulundu (5 km içinde)',
                        style: TextStyle(
                          color: renkler.yaziSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Cami listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _camiler.length,
            itemBuilder: (context, index) {
              return _camiKarti(_camiler[index], renkler);
            },
          ),
        ),
      ],
    );
  }

  Widget _camiKarti(Map<String, dynamic> cami, TemaRenkleri renkler) {
    final mesafe = (cami['mesafe'] as double) / 1000; // Km'ye çevir
    final mesafeText = mesafe < 1
        ? '${(mesafe * 1000).toInt()} m'
        : '${mesafe.toStringAsFixed(1)} km';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: renkler.ayirac.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: renkler.vurgu.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.mosque,
            color: renkler.vurgu,
            size: 28,
          ),
        ),
        title: Text(
          cami['ad'],
          style: TextStyle(
            color: renkler.yaziPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.near_me,
                  size: 14,
                  color: renkler.yaziSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  mesafeText,
                  style: TextStyle(
                    color: renkler.yaziSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (cami['adres'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                cami['adres'],
                style: TextStyle(
                  color: renkler.yaziSecondary.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.directions,
            color: renkler.vurgu,
            size: 28,
          ),
          onPressed: () {
            _yolTarifiAl(cami);
          },
        ),
      ),
    );
  }

  void _yolTarifiAl(Map<String, dynamic> cami) {
    if (_konum == null) return;

    // URL'yi açmak için showDialog göster
    showDialog(
      context: context,
      builder: (context) {
        final renkler = _temaService.renkler;
        return AlertDialog(
          backgroundColor: renkler.kartArkaPlan,
          title: Text(
            'Yol Tarifi',
            style: TextStyle(color: renkler.yaziPrimary),
          ),
          content: Text(
            '${cami['ad']} için yol tarifi almak ister misiniz?\n\nGoogle Maps ile yürüme yol tarifi özelliği yakında eklenecek.',
            style: TextStyle(color: renkler.yaziSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tamam',
                style: TextStyle(color: renkler.vurgu),
              ),
            ),
          ],
        );
      },
    );
  }
}
