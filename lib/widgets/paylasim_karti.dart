import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/kuran_veri_service.dart';
import '../services/tema_service.dart';

/// Paylaşım kartında gösterilebilecek içerik türleri.
enum PaylasimIcerikTuru { ayet, hadis, dua, esma }

/// Karta basılacak içerik. Arapça metin yoksa o bölüm hiç çizilmez.
class PaylasimIcerigi {
  final PaylasimIcerikTuru tur;

  /// Kartın üst şeridindeki etiket (örn. "GÜNÜN AYETİ").
  final String baslik;
  final String? arapca;
  final String metin;
  final String kaynak;

  const PaylasimIcerigi({
    required this.tur,
    required this.baslik,
    required this.metin,
    required this.kaynak,
    this.arapca,
  });

  IconData get ikon {
    switch (tur) {
      case PaylasimIcerikTuru.ayet:
        return Icons.menu_book_rounded;
      case PaylasimIcerikTuru.hadis:
        return Icons.star_rounded;
      case PaylasimIcerikTuru.dua:
        return Icons.favorite_rounded;
      case PaylasimIcerikTuru.esma:
        return Icons.auto_awesome_rounded;
    }
  }

  /// Ayet paylaşımları besmele ile başlar.
  bool get besmeleliMi => tur == PaylasimIcerikTuru.ayet;

  /// Görsel paylaşılamazsa / metin olarak paylaşılırsa kullanılacak düz metin.
  String duzMetin(String imza) {
    final tampon = StringBuffer()
      ..writeln(baslik)
      ..writeln();
    if (besmeleliMi) {
      tampon
        ..writeln(KuranVeriService.besmele)
        ..writeln();
    }
    if ((arapca ?? '').trim().isNotEmpty) {
      tampon
        ..writeln(arapca!.trim())
        ..writeln();
    }
    tampon.writeln('"${metin.trim()}"');
    if (kaynak.trim().isNotEmpty) {
      tampon
        ..writeln()
        ..writeln('— ${kaynak.trim()}');
    }
    if (imza.trim().isNotEmpty) {
      tampon
        ..writeln()
        ..writeln(imza.trim());
    }
    return tampon.toString().trim();
  }
}

/// Kartın renk şeması. `temaId` dolu olan stil, kullanıcının o anki
/// uygulama temasından türetilir; diğerleri sabit paletlerdir.
class PaylasimKartiStili {
  /// Stil adının dil dosyasındaki anahtarı.
  final String isimAnahtari;
  final String yedekIsim;
  final List<Color> arkaPlan;
  final Color vurgu;
  final Color yaziPrimary;
  final Color yaziSecondary;
  final bool acikZemin;

  const PaylasimKartiStili({
    required this.isimAnahtari,
    required this.yedekIsim,
    required this.arkaPlan,
    required this.vurgu,
    required this.yaziPrimary,
    required this.yaziSecondary,
    this.acikZemin = false,
  });

  /// Önizlemedeki stil noktasında gösterilen renk.
  Color get onizlemeRengi => arkaPlan.first;

  /// Aktif uygulama temasından bir stil üretir; kart uygulamayla aynı
  /// görünsün isteyen kullanıcı için ilk seçenek budur.
  factory PaylasimKartiStili.temadan(TemaRenkleri renkler) {
    return PaylasimKartiStili(
      isimAnahtari: 'card_style_theme',
      yedekIsim: 'Tema',
      arkaPlan: [
        renkler.kartArkaPlan,
        Color.alphaBlend(
          renkler.arkaPlan.withValues(alpha: 0.85),
          renkler.kartArkaPlan,
        ),
      ],
      vurgu: renkler.vurgu,
      yaziPrimary: renkler.yaziPrimary,
      yaziSecondary: renkler.yaziSecondary,
      acikZemin: renkler.kartArkaPlan.computeLuminance() > 0.5,
    );
  }

  /// Tema stili hariç sabit paletler.
  static const List<PaylasimKartiStili> sabitStiller = [
    PaylasimKartiStili(
      isimAnahtari: 'card_style_night',
      yedekIsim: 'Gece',
      arkaPlan: [Color(0xFF13203A), Color(0xFF0A1122)],
      vurgu: Color(0xFFD9B45B),
      yaziPrimary: Color(0xFFF3F1EA),
      yaziSecondary: Color(0xFFA7B0C4),
    ),
    PaylasimKartiStili(
      isimAnahtari: 'card_style_emerald',
      yedekIsim: 'Zümrüt',
      arkaPlan: [Color(0xFF0E3B32), Color(0xFF07211D)],
      vurgu: Color(0xFF74C69D),
      yaziPrimary: Color(0xFFF0F7F3),
      yaziSecondary: Color(0xFF9FC7B6),
    ),
    PaylasimKartiStili(
      isimAnahtari: 'card_style_sepia',
      yedekIsim: 'Sepya',
      arkaPlan: [Color(0xFFF7EEDD), Color(0xFFE8D9BE)],
      vurgu: Color(0xFF9A6B2F),
      yaziPrimary: Color(0xFF3B2C18),
      yaziSecondary: Color(0xFF7A6547),
      acikZemin: true,
    ),
    PaylasimKartiStili(
      isimAnahtari: 'card_style_plain',
      yedekIsim: 'Sade',
      arkaPlan: [Color(0xFFFFFFFF), Color(0xFFF1F2F4)],
      vurgu: Color(0xFF2E5E8C),
      yaziPrimary: Color(0xFF1A1D23),
      yaziSecondary: Color(0xFF6B7280),
      acikZemin: true,
    ),
    PaylasimKartiStili(
      isimAnahtari: 'card_style_rose',
      yedekIsim: 'Gül',
      arkaPlan: [Color(0xFF3B1220), Color(0xFF1D0910)],
      vurgu: Color(0xFFE0A3B4),
      yaziPrimary: Color(0xFFF8EEF1),
      yaziSecondary: Color(0xFFC79AA6),
    ),
  ];
}

/// Paylaşılmak üzere PNG'ye çevrilen kart.
///
/// Genişliği sabittir; [PaylasimKartiService.pngUret] bu widget'ı 3x piksel
/// oranıyla yakaladığı için çıktı 1080 piksel genişliğinde olur.
class PaylasimKarti extends StatelessWidget {
  /// Kartın mantıksal genişliği. 3x yakalamada 1080 px eder.
  static const double genislik = 360;

  final PaylasimIcerigi icerik;
  final PaylasimKartiStili stil;

  /// Arapça metin varsa gösterilsin mi (kullanıcı kapatabilir).
  final bool arapcaGoster;

  /// Kartın altındaki uygulama imzası.
  final String imza;

  const PaylasimKarti({
    super.key,
    required this.icerik,
    required this.stil,
    required this.imza,
    this.arapcaGoster = true,
  });

  /// Uzun metinlerde kartın taşmaması için yazı boyutunu kademeli küçültür.
  double _metinBoyutu(String metin) {
    final uzunluk = metin.characters.length;
    if (uzunluk < 120) return 20;
    if (uzunluk < 260) return 18;
    if (uzunluk < 450) return 16;
    if (uzunluk < 800) return 14;
    return 12.5;
  }

  double _arapcaBoyutu(String metin) {
    final uzunluk = metin.characters.length;
    if (uzunluk < 90) return 26;
    if (uzunluk < 200) return 22;
    if (uzunluk < 400) return 19;
    return 16;
  }

  /// Kart okunabilir kalsın diye çok uzun metinleri kırpar.
  String _kirp(String metin, int sinir) {
    final temiz = metin.trim();
    if (temiz.characters.length <= sinir) return temiz;
    return '${temiz.characters.take(sinir).toString().trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final metin = _kirp(icerik.metin, 900);
    final arapca = (icerik.arapca ?? '').trim();
    final arapcaVar = arapcaGoster && arapca.isNotEmpty;

    return Container(
      width: genislik,
      constraints: const BoxConstraints(minHeight: 460),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: stil.arkaPlan,
        ),
      ),
      child: Stack(
        children: [
          // Köşe motifleri ve ince çerçeve.
          Positioned.fill(
            child: CustomPaint(
              painter: _KartDeseniPainter(
                renk: stil.vurgu,
                acikZemin: stil.acikZemin,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 34, 30, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _baslikSatiri(),
                const SizedBox(height: 22),

                // Ayetler besmele ile başlar.
                if (icerik.besmeleliMi) ...[
                  Text(
                    KuranVeriService.besmele,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: stil.vurgu,
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                if (arapcaVar) ...[
                  Text(
                    _kirp(arapca, 500),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: stil.yaziPrimary,
                      fontFamily: 'Amiri',
                      fontSize: _arapcaBoyutu(arapca),
                      height: 1.9,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ayirac(),
                  const SizedBox(height: 20),
                ],
                Text(
                  metin,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: stil.yaziPrimary,
                    fontSize: _metinBoyutu(metin),
                    height: 1.75,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 22),
                if (icerik.kaynak.trim().isNotEmpty) _kaynakRozeti(),
                const SizedBox(height: 26),
                _altImza(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _baslikSatiri() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: stil.vurgu.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icerik.ikon, color: stil.vurgu, size: 15),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            icerik.baslik.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: stil.vurgu,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
            ),
          ),
        ),
      ],
    );
  }

  /// Arapça ile meal arasındaki elmas motifli ince ayraç.
  Widget _ayirac() {
    Widget cizgi(List<Color> renkler) => Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: renkler),
        ),
      ),
    );

    final saydam = stil.vurgu.withValues(alpha: 0);
    final dolgu = stil.vurgu.withValues(alpha: 0.45);

    return Row(
      children: [
        cizgi([saydam, dolgu]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: stil.vurgu.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
        cizgi([dolgu, saydam]),
      ],
    );
  }

  Widget _kaynakRozeti() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: stil.vurgu.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: stil.vurgu.withValues(alpha: 0.3)),
        ),
        child: Text(
          '— ${icerik.kaynak.trim()}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: stil.acikZemin ? stil.vurgu : stil.yaziSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _altImza() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 1,
          color: stil.vurgu.withValues(alpha: 0.18),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.nightlight_round,
              size: 12,
              color: stil.vurgu.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 7),
            Text(
              imza,
              style: TextStyle(
                color: stil.yaziSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Kartın köşelerindeki sekiz köşeli yıldız motiflerini ve ince iç çerçeveyi
/// çizer. Metnin okunmasını engellememesi için opaklık düşük tutulur.
class _KartDeseniPainter extends CustomPainter {
  final Color renk;
  final bool acikZemin;

  const _KartDeseniPainter({required this.renk, required this.acikZemin});

  @override
  void paint(Canvas canvas, Size size) {
    final cerceve = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = renk.withValues(alpha: acikZemin ? 0.30 : 0.22);

    canvas.drawRect(
      Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
      cerceve,
    );

    final motif = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = renk.withValues(alpha: acikZemin ? 0.22 : 0.16);

    // Dört köşeye sekiz köşeli yıldız (iki iç içe kare) ve halka.
    const kenar = 46.0;
    final koseler = [
      const Offset(kenar, kenar),
      Offset(size.width - kenar, kenar),
      Offset(kenar, size.height - kenar),
      Offset(size.width - kenar, size.height - kenar),
    ];
    for (final kose in koseler) {
      _yildizCiz(canvas, kose, 20, motif);
      canvas.drawCircle(kose, 27, motif..strokeWidth = 0.8);
      motif.strokeWidth = 1.2;
    }
  }

  /// İki kareyi 45° farkla üst üste çizerek sekiz köşeli yıldız oluşturur.
  void _yildizCiz(Canvas canvas, Offset merkez, double yaricap, Paint boya) {
    for (final baslangic in [0.0, math.pi / 4]) {
      final yol = Path();
      for (var i = 0; i < 4; i++) {
        final aci = baslangic + (math.pi / 2) * i;
        final nokta = Offset(
          merkez.dx + yaricap * math.cos(aci),
          merkez.dy + yaricap * math.sin(aci),
        );
        if (i == 0) {
          yol.moveTo(nokta.dx, nokta.dy);
        } else {
          yol.lineTo(nokta.dx, nokta.dy);
        }
      }
      yol.close();
      canvas.drawPath(yol, boya);
    }
  }

  @override
  bool shouldRepaint(_KartDeseniPainter oldDelegate) =>
      oldDelegate.renk != renk || oldDelegate.acikZemin != acikZemin;
}
