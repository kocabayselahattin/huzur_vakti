import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/diyanet_api_service.dart';
import '../services/konum_service.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';

/// Kum Saati Sayaç - 3D Kum Saati animasyonlu benzersiz tasarım
class KumsaatiSayacWidget extends StatefulWidget {
  const KumsaatiSayacWidget({super.key});

  @override
  State<KumsaatiSayacWidget> createState() => _KumsaatiSayacWidgetState();
}

class _KumsaatiSayacWidgetState extends State<KumsaatiSayacWidget>
    with TickerProviderStateMixin {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();
  Timer? _timer;
  Duration _kalanSure = Duration.zero;
  String _sonrakiVakit = '';
  double _ilerlemeOrani = 0.0;
  Map<String, String> _vakitSaatleri = {};

  late AnimationController _sandController;
  late AnimationController _rotateController;
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();

    _sandController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat();

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _vakitleriYukle();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _hesaplaKalanSure();
    });
    _temaService.addListener(_onTemaChanged);
    _languageService.addListener(_onTemaChanged);
  }

  void _onTemaChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sandController.dispose();
    _rotateController.dispose();
    _sparkleController.dispose();
    _temaService.removeListener(_onTemaChanged);
    _languageService.removeListener(_onTemaChanged);
    super.dispose();
  }

  Future<void> _vakitleriYukle() async {
    final ilceId = await KonumService.getIlceId();
    if (ilceId != null) {
      final vakitler = await DiyanetApiService.getBugunVakitler(ilceId);
      if (vakitler != null && mounted) {
        setState(() {
          _vakitSaatleri = {
            'imsak': vakitler['Imsak'] ?? '05:30',
            'gunes': vakitler['Gunes'] ?? '07:00',
            'ogle': vakitler['Ogle'] ?? '12:30',
            'ikindi': vakitler['Ikindi'] ?? '15:45',
            'aksam': vakitler['Aksam'] ?? '18:15',
            'yatsi': vakitler['Yatsi'] ?? '19:45',
          };
        });
        _hesaplaKalanSure();
      }
    }
  }

  void _hesaplaKalanSure() {
    if (_vakitSaatleri.isEmpty) return;

    final now = DateTime.now();
    final nowTotalSeconds = now.hour * 3600 + now.minute * 60 + now.second;

    final vakitListesi = [
      {'adi': _languageService['imsak'] ?? 'İmsak', 'saat': _vakitSaatleri['imsak']!},
      {'adi': _languageService['gunes'] ?? 'Güneş', 'saat': _vakitSaatleri['gunes']!},
      {'adi': _languageService['ogle'] ?? 'Öğle', 'saat': _vakitSaatleri['ogle']!},
      {'adi': _languageService['ikindi'] ?? 'İkindi', 'saat': _vakitSaatleri['ikindi']!},
      {'adi': _languageService['aksam'] ?? 'Akşam', 'saat': _vakitSaatleri['aksam']!},
      {'adi': _languageService['yatsi'] ?? 'Yatsı', 'saat': _vakitSaatleri['yatsi']!},
    ];

    List<int> vakitSaniyeleri = [];
    for (final vakit in vakitListesi) {
      final parts = vakit['saat']!.split(':');
      vakitSaniyeleri.add(int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60);
    }

    DateTime? sonrakiVakitZamani;
    String sonrakiVakitAdi = '';
    double oran = 0.0;

    int sonrakiIndex = -1;
    for (int i = 0; i < vakitSaniyeleri.length; i++) {
      if (vakitSaniyeleri[i] > nowTotalSeconds) {
        sonrakiIndex = i;
        break;
      }
    }

    if (sonrakiIndex == -1) {
      final yarin = now.add(const Duration(days: 1));
      final imsakParts = _vakitSaatleri['imsak']!.split(':');
      sonrakiVakitZamani = DateTime(yarin.year, yarin.month, yarin.day,
          int.parse(imsakParts[0]), int.parse(imsakParts[1]));
      sonrakiVakitAdi = _languageService['imsak'] ?? 'İmsak';
      final yatsiSaniye = vakitSaniyeleri.last;
      final imsakSaniye = vakitSaniyeleri.first;
      final toplamSure = (24 * 3600 - yatsiSaniye) + imsakSaniye;
      final gecenSure = nowTotalSeconds - yatsiSaniye;
      oran = (gecenSure / toplamSure).clamp(0.0, 1.0);
    } else if (sonrakiIndex == 0) {
      final imsakParts = _vakitSaatleri['imsak']!.split(':');
      sonrakiVakitZamani = DateTime(now.year, now.month, now.day,
          int.parse(imsakParts[0]), int.parse(imsakParts[1]));
      sonrakiVakitAdi = _languageService['imsak'] ?? 'İmsak';
      final yatsiSaniye = vakitSaniyeleri.last;
      final imsakSaniye = vakitSaniyeleri.first;
      final toplamSure = (24 * 3600 - yatsiSaniye) + imsakSaniye;
      final gecenSure = nowTotalSeconds + (24 * 3600 - yatsiSaniye);
      oran = (gecenSure / toplamSure).clamp(0.0, 1.0);
    } else {
      final parts = vakitListesi[sonrakiIndex]['saat']!.split(':');
      sonrakiVakitZamani = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      sonrakiVakitAdi = vakitListesi[sonrakiIndex]['adi']!;
      final toplamSure = vakitSaniyeleri[sonrakiIndex] - vakitSaniyeleri[sonrakiIndex - 1];
      final gecenSure = nowTotalSeconds - vakitSaniyeleri[sonrakiIndex - 1];
      oran = (gecenSure / toplamSure).clamp(0.0, 1.0);
    }

    setState(() {
      _kalanSure = sonrakiVakitZamani!.difference(now);
      _sonrakiVakit = sonrakiVakitAdi;
      _ilerlemeOrani = oran;
    });
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;
    final hours = _kalanSure.inHours;
    final minutes = _kalanSure.inMinutes % 60;
    final seconds = _kalanSure.inSeconds % 60;

    // Kum saati renkleri
    final sandColor = Color.lerp(
      const Color(0xFFD4A574),
      const Color(0xFFFFD700),
      _sparkleController.value,
    )!;
    final glassColor = renkler.vurgu.withOpacity(0.3);
    final frameColor = Color.lerp(
      const Color(0xFF8B4513),
      const Color(0xFFCD853F),
      0.5,
    )!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1a0a2e),
            const Color(0xFF16213e),
            const Color(0xFF0f0f23),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: sandColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Yıldızlı arka plan
            AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _StarfieldPainter(
                    progress: _sparkleController.value,
                    color: sandColor,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Ana içerik
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Üst kısım - Vakit bilgisi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sonrakiVakit,
                            style: TextStyle(
                              color: sandColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: sandColor.withOpacity(0.5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _languageService['time_remaining'] ?? 'Kalan Süre',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      // Küçük dönen altın parçacıklar
                      AnimatedBuilder(
                        animation: _rotateController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateController.value * 2 * math.pi,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    sandColor.withOpacity(0.1),
                                    sandColor.withOpacity(0.5),
                                    sandColor.withOpacity(0.1),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.hourglass_empty,
                                color: sandColor,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Kum saati
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_sandController, _sparkleController]),
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _HourglassPainter(
                              progress: _ilerlemeOrani,
                              sandColor: sandColor,
                              glassColor: glassColor,
                              frameColor: frameColor,
                              sandAnimValue: _sandController.value,
                              glowIntensity: _sparkleController.value,
                            ),
                            size: const Size(160, 220),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Zaman göstergesi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          frameColor.withOpacity(0.3),
                          frameColor.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: sandColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTimeUnit(hours.toString().padLeft(2, '0'), 'SA', sandColor),
                        _buildSeparator(sandColor),
                        _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'DK', sandColor),
                        _buildSeparator(sandColor),
                        _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'SN', sandColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // İlerleme çubuğu - Altın şerit
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.black26,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _ilerlemeOrani,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              sandColor.withOpacity(0.5),
                              sandColor,
                              const Color(0xFFFFD700),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: sandColor.withOpacity(0.5),
                              blurRadius: 8,
                            ),
                          ],
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
  }

  Widget _buildTimeUnit(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            shadows: [
              Shadow(color: color.withOpacity(0.5), blurRadius: 10),
            ],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        ':',
        style: TextStyle(
          color: color,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Kum saati çizici
class _HourglassPainter extends CustomPainter {
  final double progress;
  final Color sandColor;
  final Color glassColor;
  final Color frameColor;
  final double sandAnimValue;
  final double glowIntensity;

  _HourglassPainter({
    required this.progress,
    required this.sandColor,
    required this.glassColor,
    required this.frameColor,
    required this.sandAnimValue,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Çerçeve
    final framePaint = Paint()
      ..color = frameColor
      ..style = PaintingStyle.fill;

    // Üst çerçeve
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, 15), width: 100, height: 20),
        const Radius.circular(4),
      ),
      framePaint,
    );

    // Alt çerçeve
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, size.height - 15), width: 100, height: 20),
        const Radius.circular(4),
      ),
      framePaint,
    );

    // Cam parlaklığı
    final glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          glassColor.withOpacity(0.4),
          glassColor.withOpacity(0.1),
          glassColor.withOpacity(0.3),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Cam kenarlık
    final glassStrokePaint = Paint()
      ..color = glassColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Kum saati şekli
    final glassPath = Path();
    
    // Üst kısım (üçgen)
    glassPath.moveTo(centerX - 45, 30);
    glassPath.quadraticBezierTo(centerX - 45, centerY - 20, centerX - 5, centerY);
    glassPath.lineTo(centerX + 5, centerY);
    glassPath.quadraticBezierTo(centerX + 45, centerY - 20, centerX + 45, 30);
    glassPath.close();

    // Alt kısım (üçgen)
    final bottomPath = Path();
    bottomPath.moveTo(centerX - 45, size.height - 30);
    bottomPath.quadraticBezierTo(centerX - 45, centerY + 20, centerX - 5, centerY);
    bottomPath.lineTo(centerX + 5, centerY);
    bottomPath.quadraticBezierTo(centerX + 45, centerY + 20, centerX + 45, size.height - 30);
    bottomPath.close();

    canvas.drawPath(glassPath, glassPaint);
    canvas.drawPath(bottomPath, glassPaint);
    canvas.drawPath(glassPath, glassStrokePaint);
    canvas.drawPath(bottomPath, glassStrokePaint);

    // Kum
    final sandPaint = Paint()
      ..color = sandColor
      ..style = PaintingStyle.fill;

    // Üst kum (azalan)
    final topSandHeight = (1 - progress) * 70;
    if (topSandHeight > 0) {
      final topSandPath = Path();
      final sandY = 30 + (70 - topSandHeight);
      final sandWidth = 45 * (topSandHeight / 70);
      topSandPath.moveTo(centerX - sandWidth, sandY);
      topSandPath.quadraticBezierTo(
        centerX - sandWidth * 0.8,
        sandY + topSandHeight * 0.8,
        centerX,
        centerY - 5,
      );
      topSandPath.quadraticBezierTo(
        centerX + sandWidth * 0.8,
        sandY + topSandHeight * 0.8,
        centerX + sandWidth,
        sandY,
      );
      topSandPath.close();
      canvas.drawPath(topSandPath, sandPaint);
    }

    // Alt kum (artan)
    final bottomSandHeight = progress * 70;
    if (bottomSandHeight > 0) {
      final sandY = size.height - 30 - bottomSandHeight;
      final sandWidth = 45 * (bottomSandHeight / 70);
      final bottomSandPath = Path();
      bottomSandPath.moveTo(centerX - sandWidth, size.height - 30);
      bottomSandPath.quadraticBezierTo(
        centerX - sandWidth * 0.8,
        sandY + bottomSandHeight * 0.2,
        centerX,
        sandY,
      );
      bottomSandPath.quadraticBezierTo(
        centerX + sandWidth * 0.8,
        sandY + bottomSandHeight * 0.2,
        centerX + sandWidth,
        size.height - 30,
      );
      bottomSandPath.close();
      canvas.drawPath(bottomSandPath, sandPaint);
    }

    // Akan kum (ortadaki ince çizgi)
    if (progress > 0 && progress < 1) {
      final flowPaint = Paint()
        ..color = sandColor
        ..strokeWidth = 2 + sandAnimValue * 2
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(centerX, centerY - 5),
        Offset(centerX, centerY + 5),
        flowPaint,
      );

      // Kum parçacıkları
      final random = math.Random((sandAnimValue * 1000).toInt());
      for (int i = 0; i < 5; i++) {
        final particleY = centerY - 10 + random.nextDouble() * 20;
        final particleX = centerX - 2 + random.nextDouble() * 4;
        canvas.drawCircle(
          Offset(particleX, particleY),
          1,
          Paint()..color = sandColor.withOpacity(0.8),
        );
      }
    }

    // Parlama efekti
    final glowPaint = Paint()
      ..color = sandColor.withOpacity(0.1 + glowIntensity * 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawCircle(Offset(centerX, centerY), 30, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.sandAnimValue != sandAnimValue ||
        oldDelegate.glowIntensity != glowIntensity;
  }
}

// Yıldız alanı çizici
class _StarfieldPainter extends CustomPainter {
  final double progress;
  final Color color;

  _StarfieldPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final starPaint = Paint()..color = color.withOpacity(0.3);

    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 0.5 + random.nextDouble() * 1.5;
      final twinkle = (math.sin(progress * 2 * math.pi + i) + 1) / 2;

      canvas.drawCircle(
        Offset(x, y),
        radius * twinkle,
        starPaint..color = color.withOpacity(0.2 + twinkle * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
