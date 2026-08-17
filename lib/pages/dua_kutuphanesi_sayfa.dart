import 'package:flutter/material.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';
import '../services/dua_kutuphanesi_service.dart';
import '../widgets/paylasim_karti.dart';
import 'paylasim_onizleme_sayfa.dart';

/// Kütüphane > Dua Kütüphanesi: yemek/uyku/yolculuk/şifa/sıkıntı/istihare
/// kategorilerine göre dua listesi. Her dua Arapça + okunuş + meal ile
/// gösterilir; favorilere eklenebilir ve paylaşılabilir (bkz.
/// [DuaKutuphanesiService], [PaylasimOnizlemeSayfa]).
class DuaKutuphanesiSayfa extends StatefulWidget {
  const DuaKutuphanesiSayfa({super.key});

  @override
  State<DuaKutuphanesiSayfa> createState() => _DuaKutuphanesiSayfaState();
}

/// "Favorilerim" filtresi de bir sekme gibi ele alınır; gerçek bir kategori
/// olmadığı için ayrı bir sabitle temsil edilir.
const String _favorilerSekmesi = 'favoriler';

class _DuaKutuphanesiSayfaState extends State<DuaKutuphanesiSayfa> {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();
  final ScrollController _sekmeKaydirici = ScrollController();

  String _seciliSekme = DuaKutuphanesiService.kategoriler.first;
  Set<String> _favoriIdleri = {};

  @override
  void initState() {
    super.initState();
    _favorileriYukle();
  }

  @override
  void dispose() {
    _sekmeKaydirici.dispose();
    super.dispose();
  }

  Future<void> _favorileriYukle() async {
    final favoriler = await DuaKutuphanesiService.favoriIdleri();
    if (mounted) setState(() => _favoriIdleri = favoriler);
  }

  String _ceviri(String anahtar, String yedek) {
    final deger = _languageService[anahtar];
    if (deger is String && deger.trim().isNotEmpty) return deger;
    return yedek;
  }

  String _kategoriAdi(String kategori) {
    return _ceviri('dua_category_$kategori', kategori);
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text(
          _ceviri('dua_library_title', 'DUA KÜTÜPHANESİ'),
          style: TextStyle(
            letterSpacing: 2,
            fontSize: 14,
            color: renkler.yaziPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
      ),
      body: Container(
        decoration: renkler.arkaPlanGradient != null
            ? BoxDecoration(gradient: renkler.arkaPlanGradient)
            : null,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(height: 52, child: _sekmeSeridi(renkler)),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<DuaKaydi>>(
                  future: _seciliSekme == _favorilerSekmesi
                      ? DuaKutuphanesiService.favoriDualar()
                      : DuaKutuphanesiService.kategoriyeGoreDualar(
                          _seciliSekme,
                        ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: renkler.vurgu),
                      );
                    }
                    final dualar = snapshot.data ?? const [];
                    if (dualar.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _seciliSekme == _favorilerSekmesi
                                ? _ceviri(
                                    'dua_no_favorites',
                                    'Henüz favori dua eklemedin',
                                  )
                                : '',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: renkler.yaziSecondary),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: dualar.length,
                      itemBuilder: (context, index) =>
                          _duaKarti(dualar[index], renkler),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sekmeSeridi(TemaRenkleri renkler) {
    final sekmeler = [..._DuaKutuphanesiSayfaState._tumSekmeler];
    return Scrollbar(
      controller: _sekmeKaydirici,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _sekmeKaydirici,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sekmeler.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final sekme = sekmeler[index];
          final secili = sekme == _seciliSekme;
          final etiket = sekme == _favorilerSekmesi
              ? _ceviri('dua_favorites', 'Favorilerim')
              : _kategoriAdi(sekme);
          return GestureDetector(
            onTap: () => setState(() => _seciliSekme = sekme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: secili
                    ? renkler.vurgu.withOpacity(0.15)
                    : renkler.kartArkaPlan,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: secili
                      ? renkler.vurgu
                      : renkler.yaziSecondary.withOpacity(0.3),
                  width: secili ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (sekme == _favorilerSekmesi)
                    Icon(Icons.favorite_rounded,
                        size: 14,
                        color: secili ? renkler.vurgu : renkler.yaziSecondary),
                  if (sekme == _favorilerSekmesi) const SizedBox(width: 4),
                  Text(
                    etiket,
                    style: TextStyle(
                      color: secili ? renkler.vurgu : renkler.yaziSecondary,
                      fontSize: 13,
                      fontWeight: secili ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static final List<String> _tumSekmeler = [
    ...DuaKutuphanesiService.kategoriler,
    _favorilerSekmesi,
  ];

  Widget _duaKarti(DuaKaydi dua, TemaRenkleri renkler) {
    final favori = _favoriIdleri.contains(dua.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: renkler.vurgu.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dua.baslik,
              style: TextStyle(
                color: renkler.vurgu,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              dua.arapca,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: renkler.yaziPrimary,
                fontSize: 20,
                fontFamily: 'Amiri',
                height: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              dua.okunus,
              style: TextStyle(
                color: renkler.yaziSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dua.meal,
              style: TextStyle(
                color: renkler.yaziPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (dua.kaynak.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                dua.kaynak,
                style: TextStyle(
                  color: renkler.yaziSecondary,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    favori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: favori ? Colors.pink : renkler.yaziSecondary,
                    size: 20,
                  ),
                  onPressed: () => _favoriDegistir(dua),
                ),
                IconButton(
                  icon: Icon(Icons.share_rounded,
                      color: renkler.vurgu, size: 20),
                  onPressed: () => _duaPaylas(dua),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _favoriDegistir(DuaKaydi dua) async {
    final eklendiMi = await DuaKutuphanesiService.favoriDegistir(dua.id);
    if (!mounted) return;
    setState(() {
      if (eklendiMi) {
        _favoriIdleri.add(dua.id);
      } else {
        _favoriIdleri.remove(dua.id);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          eklendiMi
              ? _ceviri('dua_added_to_favorites', 'Favorilere eklendi')
              : _ceviri('dua_removed_from_favorites', 'Favorilerden çıkarıldı'),
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _duaPaylas(DuaKaydi dua) {
    PaylasimOnizlemeSayfa.ac(
      context,
      PaylasimIcerigi(
        tur: PaylasimIcerikTuru.dua,
        baslik: dua.baslik,
        metin: dua.meal,
        kaynak: dua.kaynak,
        arapca: dua.arapca,
      ),
    );
  }
}
