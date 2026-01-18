import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/tema_service.dart';

class KibleSayfa extends StatefulWidget {
  const KibleSayfa({super.key});

  @override
  State<KibleSayfa> createState() => _KibleSayfaState();
}

class _KibleSayfaState extends State<KibleSayfa> with TickerProviderStateMixin {
  final TemaService _temaService = TemaService();
  double? _kibleDerece;
  bool _yukleniyor = true;
  String? _hata;
  Position? _konum;
  late AnimationController _pusulaController;
  late Animation<double> _rotationAnimation;
  double _currentRotation = 0;

  // Kabe koordinatları
  static const double kabeEnlem = 21.4225;
  static const double kabeBoylam = 39.8262;

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onTemaChanged);
    _pusulaController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _pusulaController, curve: Curves.easeInOut),
    );
    _konumuAl();
  }

  @override
  void dispose() {
    _temaService.removeListener(_onTemaChanged);
    _pusulaController.dispose();
    super.dispose();
  }

  void _onTemaChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _konumuAl() async {
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

      // Kıble açısını hesapla
      final kibleAcisi = _kibleHesapla(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _konum = position;
        _kibleDerece = kibleAcisi;
        _yukleniyor = false;
      });

      // Animasyonu başlat
      _animateToAngle(kibleAcisi);
    } catch (e) {
      setState(() {
        _hata = 'Konum alınamadı: $e';
        _yukleniyor = false;
      });
    }
  }

  void _animateToAngle(double targetAngle) {
    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: targetAngle,
    ).animate(CurvedAnimation(
      parent: _pusulaController,
      curve: Curves.easeInOut,
    ));

    _pusulaController.reset();
    _pusulaController.forward();
    _currentRotation = targetAngle;
  }

  double _kibleHesapla(double enlem, double boylam) {
    // Dereceyi radyana çevir
    final lat1 = _toRadians(enlem);
    final lon1 = _toRadians(boylam);
    final lat2 = _toRadians(kabeEnlem);
    final lon2 = _toRadians(kabeBoylam);

    // Kıble açısını hesapla
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    
    double derece = _toDegrees(math.atan2(y, x));
    
    // 0-360 aralığına normalize et
    derece = (derece + 360) % 360;
    
    return derece;
  }

  double _toRadians(double derece) {
    return derece * math.pi / 180;
  }

  double _toDegrees(double radyan) {
    return radyan * 180 / math.pi;
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text(
          'Kıble Yönü',
          style: TextStyle(color: renkler.yaziPrimary),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _konumuAl,
            tooltip: 'Konumu yenile',
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
                    'Konum alınıyor...',
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
              : _pusulaGoster(renkler),
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
              onPressed: _konumuAl,
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

  Widget _pusulaGoster(TemaRenkleri renkler) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Konum bilgisi
          _konumBilgisi(renkler),
          
          const SizedBox(height: 40),
          
          // Pusula
          AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _toRadians(_rotationAnimation.value),
                child: child,
              );
            },
            child: _pusulaWidget(renkler),
          ),
          
          const SizedBox(height: 40),
          
          // Kıble açısı
          _kibleAcisiGoster(renkler),
          
          const SizedBox(height: 20),
          
          // Bilgi notu
          _bilgiNotu(renkler),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _konumBilgisi(TemaRenkleri renkler) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: renkler.ayirac.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: renkler.vurgu, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mevcut Konum',
                style: TextStyle(
                  color: renkler.yaziPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_konum != null) ...[
            Text(
              'Enlem: ${_konum!.latitude.toStringAsFixed(4)}°',
              style: TextStyle(
                color: renkler.yaziSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Boylam: ${_konum!.longitude.toStringAsFixed(4)}°',
              style: TextStyle(
                color: renkler.yaziSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pusulaWidget(TemaRenkleri renkler) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            renkler.kartArkaPlan,
            renkler.kartArkaPlan.withValues(alpha: 0.5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: renkler.vurgu.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dış çember
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: renkler.vurgu,
                width: 3,
              ),
            ),
          ),
          
          // Yönler
          for (int i = 0; i < 4; i++)
            Transform.rotate(
              angle: _toRadians(i * 90.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ['K', 'D', 'G', 'B'][i],
                    style: TextStyle(
                      color: i == 0 ? Colors.red : renkler.yaziPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          
          // Kıble oku (Kabe ikonu)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.mosque,
              color: Colors.white,
              size: 35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _kibleAcisiGoster(TemaRenkleri renkler) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            renkler.vurgu.withValues(alpha: 0.2),
            renkler.vurgu.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: renkler.vurgu.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Kıble Açısı',
            style: TextStyle(
              color: renkler.yaziSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_kibleDerece?.toStringAsFixed(1)}°',
            style: TextStyle(
              color: renkler.vurgu,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getYonAdi(_kibleDerece!),
            style: TextStyle(
              color: renkler.yaziPrimary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getYonAdi(double derece) {
    if (derece >= 337.5 || derece < 22.5) return 'Kuzey';
    if (derece >= 22.5 && derece < 67.5) return 'Kuzeydoğu';
    if (derece >= 67.5 && derece < 112.5) return 'Doğu';
    if (derece >= 112.5 && derece < 157.5) return 'Güneydoğu';
    if (derece >= 157.5 && derece < 202.5) return 'Güney';
    if (derece >= 202.5 && derece < 247.5) return 'Güneybatı';
    if (derece >= 247.5 && derece < 292.5) return 'Batı';
    return 'Kuzeybatı';
  }

  Widget _bilgiNotu(TemaRenkleri renkler) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[700],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Telefonunuzu yatay tutun ve yeşil Kabe ikonunun gösterdiği yöne doğru dönün. Kıble bu yöndedir.',
              style: TextStyle(
                color: renkler.yaziSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
