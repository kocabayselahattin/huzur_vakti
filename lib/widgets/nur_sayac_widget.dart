import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/konum_service.dart';
import '../services/diyanet_api_service.dart';
import '../services/tema_service.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

class NurSayacWidget extends StatefulWidget {
  const NurSayacWidget({super.key});

  @override
  State<NurSayacWidget> createState() => _NurSayacWidgetState();
}

class _NurSayacWidgetState extends State<NurSayacWidget>
    with TickerProviderStateMixin {
  final TemaService _temaService = TemaService();
  Timer? _timer;
  String _gelecekVakit = "Öğle";
  Duration _kalanSure = const Duration();
  Map<String, String> _vakitler = {};
  double _ecirOrani = 0.0;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _vakitleriYukle();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _vakitHesapla();
      }
    });
    _temaService.addListener(_onTemaChanged);
  }

  void _onTemaChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _glowController.dispose();
    _rotateController.dispose();
    _temaService.removeListener(_onTemaChanged);
    super.dispose();
  }

  Future<void> _vakitleriYukle() async {
    final konumlar = await KonumService.getKonumlar();
    final aktifIndex = await KonumService.getAktifKonumIndex();

    if (konumlar.isEmpty || aktifIndex >= konumlar.length) return;

    final konum = konumlar[aktifIndex];
    final ilceId = konum.ilceId;

    try {
      final vakitler = await DiyanetApiService.getBugunVakitler(ilceId);

      if (mounted && vakitler != null) {
        setState(() {
          _vakitler = vakitler;
        });
        _vakitHesapla();
      }
    } catch (e) {
      debugPrint('Vakitler yüklenemedi: $e');
    }
  }

  void _vakitHesapla() {
    if (_vakitler.isEmpty) return;

    final now = DateTime.now();
    final vakitSirasi = ['Imsak', 'Gunes', 'Ogle', 'Ikindi', 'Aksam', 'Yatsi'];
    final vakitIsimleri = {
      'Imsak': 'İmsak',
      'Gunes': 'Güneş',
      'Ogle': 'Öğle',
      'Ikindi': 'İkindi',
      'Aksam': 'Akşam',
      'Yatsi': 'Yatsı',
    };

    DateTime? gelecekVakitZamani;
    String? gelecekVakitIsmi;
    String? gelecekVakitKey;
    final vakitTimes = <String, DateTime>{};

    for (final vakit in vakitSirasi) {
      final vakitStr = _vakitler[vakit];
      if (vakitStr == null) continue;

      final parts = vakitStr.split(':');
      if (parts.length != 2) continue;

      final vakitZamani = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      vakitTimes[vakit] = vakitZamani;

      if (gelecekVakitZamani == null && vakitZamani.isAfter(now)) {
        gelecekVakitZamani = vakitZamani;
        gelecekVakitIsmi = vakitIsimleri[vakit];
        gelecekVakitKey = vakit;
      }
    }

    if (gelecekVakitZamani == null) {
      final imsakZamani = vakitTimes['Imsak'];
      if (imsakZamani != null) {
        gelecekVakitZamani = imsakZamani.add(const Duration(days: 1));
        gelecekVakitIsmi = 'İmsak';
        gelecekVakitKey = 'Imsak';
      }
    }

    if (gelecekVakitZamani != null &&
        gelecekVakitIsmi != null &&
        gelecekVakitKey != null) {
      final kalan = gelecekVakitZamani.difference(now);

      final imsakToday = vakitTimes['Imsak'];
      final yatsiToday = vakitTimes['Yatsi'];
      DateTime? onceVakitZamani;

      if (gelecekVakitKey == 'Imsak' &&
          imsakToday != null &&
          now.isBefore(imsakToday) &&
          yatsiToday != null) {
        onceVakitZamani = yatsiToday.subtract(const Duration(days: 1));
      } else {
        final nextIndex = vakitSirasi.indexOf(gelecekVakitKey);
        if (nextIndex != -1) {
          final prevKey =
              vakitSirasi[(nextIndex - 1 + vakitSirasi.length) %
                  vakitSirasi.length];
          onceVakitZamani = vakitTimes[prevKey];
        }
        onceVakitZamani ??= yatsiToday;
      }

      onceVakitZamani ??= now;
      final toplamSure = gelecekVakitZamani
          .difference(onceVakitZamani)
          .inSeconds;
      final gecenSure = now.difference(onceVakitZamani).inSeconds;
      final oran = toplamSure <= 0
          ? 0.0
          : (gecenSure / toplamSure).clamp(0.0, 1.0);

      setState(() {
        _gelecekVakit = gelecekVakitIsmi ?? '';
        _kalanSure = kalan;
        _ecirOrani = oran;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _kalanSure.inHours;
    final minutes = _kalanSure.inMinutes.remainder(60);
    final seconds = _kalanSure.inSeconds.remainder(60);

    final hijriNow = HijriCalendar.now();
    final miladi = DateFormat('d MMM yyyy', 'tr_TR').format(DateTime.now());
    final hicri =
        '${hijriNow.hDay} ${_getHijriMonth(hijriNow.hMonth)} ${hijriNow.hYear}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3949AB).withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dönen nur efekti
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _rotateController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _NurPainter(_rotateController.value),
                );
              },
            ),
          ),
          // İçerik
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tarih satırı (kompakt)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      miladi,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.white38)),
                    Text(
                      hicri,
                      style: const TextStyle(color: Colors.amber, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Vakit bilgisi
                AnimatedBuilder(
                  animation: _glowAnimation,
                  builder: (context, child) {
                    return Opacity(opacity: _glowAnimation.value, child: child);
                  },
                  child: Text(
                    _gelecekVakit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Kalan süre
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeUnit(hours.toString().padLeft(2, '0')),
                    _buildSeparator(),
                    _buildTimeUnit(minutes.toString().padLeft(2, '0')),
                    _buildSeparator(),
                    _buildTimeUnit(seconds.toString().padLeft(2, '0')),
                  ],
                ),
                const SizedBox(height: 12),
                // Ecir barı
                _buildEcirBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 20,
          color: Colors.white.withOpacity(0.5),
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildEcirBar() {
    return Column(
      children: [
        Container(
          height: 5,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: _ecirOrani,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.amber, Colors.orange, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getHijriMonth(int month) {
    const months = [
      'Muharrem',
      'Safer',
      'Rebiülevvel',
      'Rebiülahir',
      'Cemaziyelevvel',
      'Cemaziyelahir',
      'Recep',
      'Şaban',
      'Ramazan',
      'Şevval',
      'Zilkade',
      'Zilhicce',
    ];
    return months[month - 1];
  }
}

class _NurPainter extends CustomPainter {
  final double progress;

  _NurPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    for (int i = 0; i < 8; i++) {
      final angle = (progress * 2 * math.pi) + (i * math.pi / 4);
      final startPoint = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + (radius + 50) * math.cos(angle),
        center.dy + (radius + 50) * math.sin(angle),
      );

      paint.shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromPoints(startPoint, endPoint));

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(_NurPainter oldDelegate) => true;
}
