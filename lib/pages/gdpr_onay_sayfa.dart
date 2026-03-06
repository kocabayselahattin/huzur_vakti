import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/language_service.dart';
import 'gizlilik_politikasi_sayfa.dart';

/// AB GDPR uyumluluğu için veri koruma onay ekranı.
/// İlk açılışta (AB kullanıcıları dahil tüm kullanıcılar için) gösterilir.
class GdprOnaySayfa extends StatelessWidget {
  const GdprOnaySayfa({super.key});

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

              // AB Kalkan ikonu
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield,
                  size: 50,
                  color: Colors.amber,
                ),
              ),

              const SizedBox(height: 24),

              // Başlık
              Text(
                lang['gdpr_title'] ?? 'Veri Koruma Onayı (GDPR)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Alt başlık
              Text(
                lang['gdpr_subtitle'] ??
                    'Avrupa Birliği Genel Veri Koruma Yönetmeliği (GDPR) kapsamında verilerinizin nasıl işlendiğini bilmeniz gerekmektedir.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // İçerik kartları
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _bilgiKarti(
                        Icons.storage,
                        Colors.blue,
                        lang['gdpr_data_processing_title'] ?? 'Veri İşleme',
                        lang['gdpr_data_processing_desc'] ??
                            'Bu uygulama aşağıdaki verileri toplar ve işler:\n\n• Konum verisi (GPS): Namaz vakitleri, kıble yönü ve yakındaki camiler için\n• Cihaz tercihleri: Dil, tema ve bildirim ayarlarınız\n• İnternet erişimi: Diyanet API\'sinden namaz vakitlerini almak için\n\nTüm veriler cihazınızda saklanır. Kişisel hesap oluşturulmaz, ad-soyad veya e-posta toplanmaz.',
                      ),
                      _bilgiKarti(
                        Icons.gavel,
                        Colors.orange,
                        lang['gdpr_legal_basis_title'] ?? 'Hukuki Dayanak',
                        lang['gdpr_legal_basis_desc'] ??
                            'Verileriniz GDPR Madde 6(1)(a) kapsamında açık rızanıza dayanarak işlenir. Onayınızı istediğiniz zaman geri çekebilirsiniz.',
                      ),
                      _bilgiKarti(
                        Icons.verified_user,
                        Colors.green,
                        lang['gdpr_rights_title'] ?? 'Haklarınız',
                        lang['gdpr_rights_desc'] ??
                            'GDPR kapsamında şu haklara sahipsiniz:\n\n• Verilerinize erişim hakkı\n• Verilerinizin düzeltilmesini isteme hakkı\n• Verilerinizin silinmesini isteme hakkı (unutulma hakkı)\n• Veri işlemeyi kısıtlama hakkı\n• Onayınızı geri çekme hakkı\n\nVerilerinizi silmek için Ayarlar > Verilerimi Sil seçeneğini kullanabilirsiniz.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

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
                  lang['gdpr_read_privacy'] ?? 'Gizlilik Politikasını Oku',
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
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('gdpr_accepted', true);
                    if (!context.mounted) return;
                    Navigator.pop(context, true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    lang['gdpr_accept'] ?? 'Kabul Ediyorum',
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
                    lang['gdpr_decline'] ?? 'Kabul Etmiyorum',
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

  static Widget _bilgiKarti(
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
