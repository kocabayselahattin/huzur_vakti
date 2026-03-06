import 'package:flutter/material.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';

class GizlilikPolitikasiSayfa extends StatefulWidget {
  const GizlilikPolitikasiSayfa({super.key});

  @override
  State<GizlilikPolitikasiSayfa> createState() =>
      _GizlilikPolitikasiSayfaState();
}

class _GizlilikPolitikasiSayfaState extends State<GizlilikPolitikasiSayfa> {
  final TemaService _temaService = TemaService();
  final LanguageService _lang = LanguageService();

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onChanged);
    _lang.addListener(_onChanged);
  }

  @override
  void dispose() {
    _temaService.removeListener(_onChanged);
    _lang.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: renkler.vurgu,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _lang['privacy_policy'] ?? 'Gizlilik Politikası',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      renkler.vurgu,
                      renkler.vurgu.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.shield,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tarihBilgisi(renkler),
                  const SizedBox(height: 24),
                  _bolum(
                    renkler,
                    _lang['pp_intro_title'] ?? 'Giriş',
                    _lang['pp_intro_body'] ??
                        'Bu gizlilik politikası, Huzur Vakti uygulamasının kullanıcı verilerini nasıl topladığını, kullandığını ve koruduğunu açıklamaktadır.',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_data_collected_title'] ?? 'Toplanan Veriler',
                    _lang['pp_data_collected_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_location_title'] ?? 'Konum Verileri',
                    _lang['pp_location_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_notification_title'] ?? 'Bildirim Verileri',
                    _lang['pp_notification_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_storage_title'] ?? 'Veri Saklama',
                    _lang['pp_storage_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_third_party_title'] ?? 'Üçüncü Taraf Hizmetleri',
                    _lang['pp_third_party_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_security_title'] ?? 'Veri Güvenliği',
                    _lang['pp_security_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_children_title'] ?? 'Çocukların Gizliliği',
                    _lang['pp_children_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_changes_title'] ?? 'Politika Değişiklikleri',
                    _lang['pp_changes_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_contact_title'] ?? 'İletişim',
                    _lang['pp_contact_body'] ?? '',
                  ),
                  const Divider(height: 40),
                  _bolum(
                    renkler,
                    _lang['pp_gdpr_title'] ?? 'GDPR - AB Veri Koruma',
                    _lang['pp_gdpr_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_gdpr_legal_basis_title'] ?? 'Hukuki Dayanak',
                    _lang['pp_gdpr_legal_basis_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_gdpr_rights_title'] ?? 'Kullanıcı Hakları (GDPR)',
                    _lang['pp_gdpr_rights_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_gdpr_data_retention_title'] ?? 'Veri Saklama Süresi',
                    _lang['pp_gdpr_data_retention_body'] ?? '',
                  ),
                  _bolum(
                    renkler,
                    _lang['pp_gdpr_data_deletion_title'] ?? 'Verilerin Silinmesi',
                    _lang['pp_gdpr_data_deletion_body'] ?? '',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarihBilgisi(TemaRenkleri renkler) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renkler.vurgu.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: renkler.vurgu.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.update, color: renkler.vurgu, size: 20),
          const SizedBox(width: 8),
          Text(
            '${_lang['pp_last_updated'] ?? 'Son güncelleme'}: 05.03.2026',
            style: TextStyle(color: renkler.yaziSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _bolum(TemaRenkleri renkler, String baslik, String icerik) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: TextStyle(
              color: renkler.yaziPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            icerik,
            style: TextStyle(
              color: renkler.yaziSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
