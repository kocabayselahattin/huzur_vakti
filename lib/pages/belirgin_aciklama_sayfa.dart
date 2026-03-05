import 'package:flutter/material.dart';
import '../services/language_service.dart';
import 'gizlilik_politikasi_sayfa.dart';

/// Google Play "Belirgin Açıklama" (Prominent Disclosure) gereksinimi.
/// İzinler istenmeden ÖNCE gösterilir.
/// Hangi verilerin, neden toplandığını açıklar ve kullanıcıdan onay alır.
class BelirginAciklamaSayfa extends StatelessWidget {
  const BelirginAciklamaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LanguageService();

    return Scaffold(
      backgroundColor: const Color(0xFF1B2741),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Kalkan ikonu
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.privacy_tip,
                  size: 50,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 24),

              // Başlık
              Text(
                lang['pd_title'] ?? 'Veri Kullanımı Hakkında',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Açıklama metni
              Text(
                lang['pd_subtitle'] ??
                    'Uygulamayı kullanmaya başlamadan önce, hangi verilerin toplandığını ve nasıl kullanıldığını bilmeniz gerekmektedir.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Veri kullanım listesi
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _veriKarti(
                        Icons.location_on,
                        Colors.blue,
                        lang['pd_location_title'] ?? 'Konum Verisi',
                        lang['pd_location_desc'] ??
                            'Bulunduğunuz konuma göre doğru namaz vakitlerini hesaplamak ve kıble yönünü belirlemek için konum bilginiz kullanılır. Konum verisi sunucularımıza gönderilmez, yalnızca cihazınızda işlenir.',
                      ),
                      _veriKarti(
                        Icons.notifications_active,
                        Colors.orange,
                        lang['pd_notification_title'] ?? 'Bildirimler',
                        lang['pd_notification_desc'] ??
                            'Namaz vakitlerinde sizi bilgilendirmek, ezan sesi çalmak ve özel gün hatırlatmaları göndermek için bildirim izni kullanılır.',
                      ),
                      _veriKarti(
                        Icons.storage,
                        Colors.green,
                        lang['pd_storage_title'] ?? 'Cihaz Depolama',
                        lang['pd_storage_desc'] ??
                            'Tercihleriniz (dil, tema, konum seçimi) yalnızca cihazınızda saklanır. Kişisel verileriniz hiçbir sunucuya aktarılmaz.',
                      ),
                      _veriKarti(
                        Icons.wifi,
                        Colors.purple,
                        lang['pd_network_title'] ?? 'İnternet Erişimi',
                        lang['pd_network_desc'] ??
                            'Namaz vakitlerini Diyanet İşleri Başkanlığı API\'sinden almak için internet bağlantısı kullanılır. Bu süreçte kişisel veri gönderilmez.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Gizlilik politikası linki
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GizlilikPolitikasiSayfa(),
                    ),
                  );
                },
                child: Text(
                  lang['pd_read_privacy_policy'] ??
                      'Gizlilik Politikasını Oku',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Kabul et butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    lang['pd_accept'] ?? 'Kabul Ediyorum',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Reddet butonu
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    lang['pd_decline'] ?? 'Kabul Etmiyorum',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _veriKarti(
    IconData ikon,
    Color renk,
    String baslik,
    String aciklama,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: renk.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, color: renk, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  aciklama,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.5,
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
