import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BildirimAyarlariSayfa extends StatefulWidget {
  const BildirimAyarlariSayfa({super.key});

  @override
  State<BildirimAyarlariSayfa> createState() => _BildirimAyarlariSayfaState();
}

class _BildirimAyarlariSayfaState extends State<BildirimAyarlariSayfa> {
  // Bildirim açık/kapalı durumları
  Map<String, bool> _bildirimAcik = {
    'imsak': true,
    'gunes': false,
    'ogle': true,
    'ikindi': true,
    'aksam': true,
    'yatsi': true,
  };

  // Erken bildirim süreleri (dakika)
  Map<String, int> _erkenBildirim = {
    'imsak': 30,
    'gunes': 0,
    'ogle': 15,
    'ikindi': 15,
    'aksam': 15,
    'yatsi': 15,
  };

  final List<int> _erkenSureler = [0, 5, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
  }

  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      for (final vakit in _bildirimAcik.keys) {
        _bildirimAcik[vakit] = prefs.getBool('bildirim_$vakit') ?? _bildirimAcik[vakit]!;
        _erkenBildirim[vakit] = prefs.getInt('erken_$vakit') ?? _erkenBildirim[vakit]!;
      }
    });
  }

  Future<void> _ayarlariKaydet() async {
    final prefs = await SharedPreferences.getInstance();

    for (final vakit in _bildirimAcik.keys) {
      await prefs.setBool('bildirim_$vakit', _bildirimAcik[vakit]!);
      await prefs.setInt('erken_$vakit', _erkenBildirim[vakit]!);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim ayarları kaydedildi'),
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
        title: const Text('Bildirim Ayarları'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _ayarlariKaydet,
            tooltip: 'Kaydet',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bilgilendirme kartı
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.cyanAccent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Her vakit için bildirimi açıp kapatabilir ve erken hatırlatma süresi belirleyebilirsiniz.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Vakit bildirimleri
          _vakitBildirimKarti(
            'İmsak',
            'imsak',
            Icons.nightlight_round,
            'Sahur için uyanma vakti',
          ),
          _vakitBildirimKarti(
            'Güneş',
            'gunes',
            Icons.wb_sunny,
            'Güneşin doğuş vakti',
          ),
          _vakitBildirimKarti(
            'Öğle',
            'ogle',
            Icons.light_mode,
            'Öğle namazı vakti',
          ),
          _vakitBildirimKarti(
            'İkindi',
            'ikindi',
            Icons.brightness_6,
            'İkindi namazı vakti',
          ),
          _vakitBildirimKarti(
            'Akşam',
            'aksam',
            Icons.wb_twilight,
            'Akşam namazı ve iftar vakti',
          ),
          _vakitBildirimKarti(
            'Yatsı',
            'yatsi',
            Icons.nights_stay,
            'Yatsı namazı vakti',
          ),

          const SizedBox(height: 24),

          // Tümünü aç/kapat
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (final key in _bildirimAcik.keys) {
                        _bildirimAcik[key] = true;
                      }
                    });
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Tümünü Aç'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    side: const BorderSide(color: Colors.cyanAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      for (final key in _bildirimAcik.keys) {
                        _bildirimAcik[key] = false;
                      }
                    });
                  },
                  icon: const Icon(Icons.notifications_off),
                  label: const Text('Tümünü Kapat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vakitBildirimKarti(
    String baslik,
    String key,
    IconData icon,
    String aciklama,
  ) {
    final acik = _bildirimAcik[key]!;
    final erkenDakika = _erkenBildirim[key]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: acik
            ? Colors.cyanAccent.withOpacity(0.05)
            : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: acik ? Colors.cyanAccent.withOpacity(0.3) : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          // Üst kısım - Switch
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: acik
                    ? Colors.cyanAccent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: acik ? Colors.cyanAccent : Colors.white54,
              ),
            ),
            title: Text(
              baslik,
              style: TextStyle(
                color: acik ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              aciklama,
              style: TextStyle(
                color: acik ? Colors.white54 : Colors.white38,
                fontSize: 12,
              ),
            ),
            trailing: Switch(
              value: acik,
              onChanged: (value) {
                setState(() {
                  _bildirimAcik[key] = value;
                });
              },
              activeColor: Colors.cyanAccent,
            ),
          ),

          // Alt kısım - Erken bildirim seçimi
          if (acik)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.timer,
                    color: Colors.white54,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Erken hatırlatma:',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: erkenDakika,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF2B3151),
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.cyanAccent),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          style: const TextStyle(color: Colors.white),
                          items: _erkenSureler.map((dakika) {
                            String label;
                            if (dakika == 0) {
                              label = 'Zamanında';
                            } else if (dakika < 60) {
                              label = '$dakika dk önce';
                            } else {
                              label = '${dakika ~/ 60} saat önce';
                            }
                            return DropdownMenuItem(
                              value: dakika,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _erkenBildirim[key] = value;
                              });
                            }
                          },
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
}
