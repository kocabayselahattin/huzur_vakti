import 'package:flutter/material.dart';
import 'ana_sayfa.dart';
import 'il_ilce_sec_sayfa.dart';
import '../services/konum_service.dart';
import '../services/diyanet_api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _kontrolVeYonlendir();
  }

  Future<void> _kontrolVeYonlendir() async {
    // 3 saniye splash screen göster
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Kaydedilmiş il/ilçe kontrolü
    final ilceId = await KonumService.getIlceId();
    
    bool ilceGecerli = false;
    
    if (ilceId != null && ilceId.isNotEmpty) {
      // API'den ilçe verisi alınabiliyor mu kontrol et
      try {
        final vakitler = await DiyanetApiService.getVakitler(ilceId);
        // Eğer vakitler başarıyla alındıysa ve içinde gerçek tarih varsa geçerli
        if (vakitler != null && vakitler.containsKey('vakitler')) {
          final vakitList = vakitler['vakitler'] as List;
          if (vakitList.isNotEmpty) {
            // İlk vaktin tarihini kontrol et - eğer doğru formatsa API çalışıyor demektir
            final ilkVakit = vakitList[0];
            final tarih = ilkVakit['MiladiTarihKisa'] ?? '';
            // Format: DD.MM.YYYY - 2026 yılı içermeli
            if (tarih.contains('.') && tarih.contains('2026')) {
              ilceGecerli = true;
              print('✅ Mevcut ilçe ID geçerli: $ilceId');
            }
          }
        }
      } catch (e) {
        print('⚠️ İlçe doğrulama hatası: $e');
      }
      
      // Eğer ilçe geçersizse, eski verileri temizle
      if (!ilceGecerli) {
        print('🔄 Eski ilçe ID geçersiz, veriler temizleniyor: $ilceId');
        await KonumService.clearKonum();
        DiyanetApiService.clearCache();
      }
    }

    if (!ilceGecerli) {
      // İl/İlçe seçilmemişse veya geçersizse önce seçim sayfasına yönlendir
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const IlIlceSecOnboarding(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      // İl/İlçe seçiliyse direkt ana sayfaya git
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AnaSayfa(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan: Derin petrol mavisi (Huzur veren koyu ton)
      backgroundColor: const Color(0xFF0D1B2A),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // Hafif bir gradyan ekleyerek derinlik kazandırıyoruz
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1B4332), // Merkeze yakın hafif yeşil dokunuş
              Color(0xFF081C15), // Kenarlara doğru derinleşen koyu ton
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern Cami İkonu (Neon Efektli)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mosque_outlined,
                size: 120,
                color: Color(0xFF74C69D), // Tatlı nane yeşili neon
              ),
            ),
            const SizedBox(height: 30),
            // Uygulama İsmi
            const Text(
              "HUZUR VAKTİ",
              style: TextStyle(
                color: Color(0xFFD8F3DC), // Çok açık yeşil, beyaza yakın
                fontSize: 32,
                fontWeight: FontWeight.w300, // Modern ve ince yazı tipi
                letterSpacing: 8, // Harf arası boşlukla ferahlık hissi
                shadows: [Shadow(color: Color(0xFF40916C), blurRadius: 15)],
              ),
            ),
            const SizedBox(height: 10),
            // Küçük bir alt yazı (Opsiyonel)
            Text(
              "Vaktin huzuruna erişin",
              style: TextStyle(
                color: const Color(0xFF95D5B2).withOpacity(0.6),
                fontSize: 14,
                fontStyle: FontStyle.italic,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// İlk kullanım için Onboarding Sayfası
class IlIlceSecOnboarding extends StatelessWidget {
  const IlIlceSecOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2741),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hoşgeldin İkonu
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent.withOpacity(0.1),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 80,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(height: 40),

              // Hoşgeldin Başlık
              const Text(
                'Hoş Geldiniz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Açıklama
              Text(
                'Huzur Vakti uygulamasına hoş geldiniz!\n\nDevam etmek için lütfen il ve ilçenizi seçin.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),

              // Devam Et Butonu
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const IlIlceSecSayfa(ilkKurulum: true),
                    ),
                  );

                  if (result == true && context.mounted) {
                    // Seçim başarılı, ana sayfaya git
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const AnaSayfa()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Konum Seç',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // İpucu
              Text(
                'İstediğiniz zaman ayarlardan değiştirebilirsiniz',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
