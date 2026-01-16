import 'package:flutter/material.dart';
import 'dart:async';
import '../services/konum_service.dart';
import '../services/diyanet_api_service.dart';

class VakitListesiWidget extends StatefulWidget {
  const VakitListesiWidget({super.key});

  @override
  State<VakitListesiWidget> createState() => _VakitListesiWidgetState();
}

class _VakitListesiWidgetState extends State<VakitListesiWidget> {
  Map<String, String> vakitSaatleri = {
    'Imsak': '—:—',
    'Gunes': '—:—',
    'Ogle': '—:—',
    'Ikindi': '—:—',
    'Aksam': '—:—',
    'Yatsi': '—:—',
  };
  String? aktifVakit;
  String? sonrakiVakit;
  Timer? _timer;
  bool _iconVisible = true;

  @override
  void initState() {
    super.initState();
    _vakitleriYukle();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _aktifVaktiGuncelle();
    });
    // İkon yanıp sönme animasyonu için
    Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) {
        setState(() => _iconVisible = !_iconVisible);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _vakitleriYukle() async {
    final ilceId = await KonumService.getIlceId();
    if (ilceId == null) return;

    try {
      final data = await DiyanetApiService.getVakitler(ilceId);
      if (data != null && data.containsKey('vakitler')) {
        final vakitler = data['vakitler'] as List;

        if (vakitler.isNotEmpty) {
          // Bugünün vakitlerini bul
          final bugun = DateTime.now();

          final bugunVakit =
              vakitler.firstWhere(
                    (v) {
                      final tarih = v['MiladiTarihKisa'] ?? '';
                      try {
                        final parts = tarih.split('.');
                        if (parts.length == 3) {
                          final gun = int.parse(parts[0]);
                          final ay = int.parse(parts[1]);
                          final yil = int.parse(parts[2]);
                          return gun == bugun.day &&
                              ay == bugun.month &&
                              yil == bugun.year;
                        }
                      } catch (e) {
                        // Parse hatası
                      }
                      return false;
                    },
                    orElse: () => vakitler.isNotEmpty
                        ? Map<String, dynamic>.from(vakitler[0])
                        : <String, dynamic>{},
                  )
                  as Map<String, dynamic>;

          setState(() {
            vakitSaatleri = {
              'Imsak': bugunVakit['Imsak'] ?? '—:—',
              'Gunes': bugunVakit['Gunes'] ?? '—:—',
              'Ogle': bugunVakit['Ogle'] ?? '—:—',
              'Ikindi': bugunVakit['Ikindi'] ?? '—:—',
              'Aksam': bugunVakit['Aksam'] ?? '—:—',
              'Yatsi': bugunVakit['Yatsi'] ?? '—:—',
            };
          });
          _aktifVaktiGuncelle();
        }
      }
    } catch (e) {
      // Hata durumunda varsayılan değerler kalacak
    }
  }

  void _aktifVaktiGuncelle() {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final vakitListesi = [
      {'adi': 'Imsak', 'saat': vakitSaatleri['Imsak']!},
      {'adi': 'Gunes', 'saat': vakitSaatleri['Gunes']!},
      {'adi': 'Ogle', 'saat': vakitSaatleri['Ogle']!},
      {'adi': 'Ikindi', 'saat': vakitSaatleri['Ikindi']!},
      {'adi': 'Aksam', 'saat': vakitSaatleri['Aksam']!},
      {'adi': 'Yatsi', 'saat': vakitSaatleri['Yatsi']!},
    ];

    String? yeniAktif;
    String? yeniSonraki;

    for (int i = 0; i < vakitListesi.length; i++) {
      final vakit = vakitListesi[i];
      final saat = vakit['saat'] as String;
      if (saat == '—:—') continue;

      try {
        final parts = saat.split(':');
        final vakitMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);

        if (nowMinutes < vakitMinutes) {
          yeniSonraki = vakit['adi'] as String;
          if (i > 0) {
            yeniAktif = vakitListesi[i - 1]['adi'] as String;
          } else {
            // Eğer ilk vakitten önceyse, önceki günün son vakti aktif
            yeniAktif = vakitListesi.last['adi'] as String;
          }
          break;
        }
      } catch (e) {
        // Parse hatası
      }
    }

    // Eğer tüm vakitler geçtiyse, yatsı aktif ve imsak sonraki
    if (yeniSonraki == null) {
      yeniAktif = vakitListesi.last['adi'] as String;
      yeniSonraki = vakitListesi.first['adi'] as String;
    }

    if (yeniAktif != aktifVakit || yeniSonraki != sonrakiVakit) {
      setState(() {
        aktifVakit = yeniAktif;
        sonrakiVakit = yeniSonraki;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _vakitSatiri(
            "Imsak",
            vakitSaatleri['Imsak']!,
            Icons.nightlight_round,
            'Imsak',
          ),
          _vakitSatiri(
            "Güneş",
            vakitSaatleri['Gunes']!,
            Icons.wb_sunny,
            'Gunes',
          ),
          _vakitSatiri(
            "Öğle",
            vakitSaatleri['Ogle']!,
            Icons.light_mode,
            'Ogle',
          ),
          _vakitSatiri(
            "İkindi",
            vakitSaatleri['Ikindi']!,
            Icons.brightness_6,
            'Ikindi',
          ),
          _vakitSatiri(
            "Akşam",
            vakitSaatleri['Aksam']!,
            Icons.wb_twilight,
            'Aksam',
          ),
          _vakitSatiri(
            "Yatsı",
            vakitSaatleri['Yatsi']!,
            Icons.nights_stay,
            'Yatsi',
          ),
        ],
      ),
    );
  }

  Widget _vakitSatiri(String ad, String saat, IconData icon, String key) {
    final aktif = aktifVakit == key;
    final sonraki = sonrakiVakit == key;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: aktif ? Colors.cyanAccent.withOpacity(0.15) : Colors.transparent,
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: sonraki && !_iconVisible ? 0.2 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: Icon(
              icon,
              color: aktif
                  ? Colors.cyanAccent
                  : sonraki
                      ? Colors.orange
                      : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ad,
              style: TextStyle(
                color: aktif ? Colors.cyanAccent : Colors.white,
                fontSize: 16,
                fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            saat,
            style: TextStyle(
              color: aktif ? Colors.cyanAccent : Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
