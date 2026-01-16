import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTema {
  gece,      // Varsayılan koyu mavi
  seher,     // Mor-pembe tonları (sahur vakti)
  tan,       // Turuncu-sarı tonları (güneş doğuşu)
  ogle,      // Açık mavi tonları (gündüz)
  aksam,     // Kırmızı-turuncu tonları (gün batımı)
  yildizli,  // Derin siyah + yıldız efekti
}

class TemaRenkleri {
  final Color arkaPlan;
  final Color kartArkaPlan;
  final Color vurgu;
  final Color vurguSecondary;
  final Color yaziPrimary;
  final Color yaziSecondary;
  final Color ayirac;
  final Gradient? arkaPlanGradient;
  final String isim;
  final String aciklama;
  final IconData ikon;

  const TemaRenkleri({
    required this.arkaPlan,
    required this.kartArkaPlan,
    required this.vurgu,
    required this.vurguSecondary,
    required this.yaziPrimary,
    required this.yaziSecondary,
    required this.ayirac,
    this.arkaPlanGradient,
    required this.isim,
    required this.aciklama,
    required this.ikon,
  });
}

class TemaService extends ChangeNotifier {
  static final TemaService _instance = TemaService._internal();
  factory TemaService() => _instance;
  TemaService._internal();

  AppTema _mevcutTema = AppTema.gece;
  
  AppTema get mevcutTema => _mevcutTema;

  static const Map<AppTema, TemaRenkleri> temalar = {
    AppTema.gece: TemaRenkleri(
      arkaPlan: Color(0xFF1B2741),
      kartArkaPlan: Color(0xFF2B3151),
      vurgu: Color(0xFF00BCD4), // Cyan
      vurguSecondary: Color(0xFF26C6DA),
      yaziPrimary: Colors.white,
      yaziSecondary: Color(0xFFB0BEC5),
      ayirac: Color(0xFF3D4466),
      isim: 'Gece',
      aciklama: 'Varsayılan koyu tema',
      ikon: Icons.nights_stay,
    ),
    AppTema.seher: TemaRenkleri(
      arkaPlan: Color(0xFF2D1B4E),
      kartArkaPlan: Color(0xFF3D2B5E),
      vurgu: Color(0xFFE040FB), // Purple/Pink
      vurguSecondary: Color(0xFFFF80AB),
      yaziPrimary: Colors.white,
      yaziSecondary: Color(0xFFCE93D8),
      ayirac: Color(0xFF4A3A6A),
      arkaPlanGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2D1B4E), Color(0xFF1A0F2E)],
      ),
      isim: 'Seher',
      aciklama: 'Sahur vakti tonları',
      ikon: Icons.brightness_3,
    ),
    AppTema.tan: TemaRenkleri(
      arkaPlan: Color(0xFF3E2723),
      kartArkaPlan: Color(0xFF4E3A31),
      vurgu: Color(0xFFFFAB40), // Orange
      vurguSecondary: Color(0xFFFFD54F),
      yaziPrimary: Colors.white,
      yaziSecondary: Color(0xFFFFCC80),
      ayirac: Color(0xFF5D4037),
      arkaPlanGradient: LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF5D4037), Color(0xFF3E2723)],
      ),
      isim: 'Tan',
      aciklama: 'Güneş doğuşu sıcaklığı',
      ikon: Icons.wb_sunny,
    ),
    AppTema.ogle: TemaRenkleri(
      arkaPlan: Color(0xFF1565C0),
      kartArkaPlan: Color(0xFF1976D2),
      vurgu: Color(0xFF64FFDA), // Teal accent
      vurguSecondary: Color(0xFF80DEEA),
      yaziPrimary: Colors.white,
      yaziSecondary: Color(0xFFB3E5FC),
      ayirac: Color(0xFF1E88E5),
      arkaPlanGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
      ),
      isim: 'Öğle',
      aciklama: 'Aydınlık gök mavisi',
      ikon: Icons.light_mode,
    ),
    AppTema.aksam: TemaRenkleri(
      arkaPlan: Color(0xFF4A1C1C),
      kartArkaPlan: Color(0xFF5A2C2C),
      vurgu: Color(0xFFFF7043), // Deep orange
      vurguSecondary: Color(0xFFFFAB91),
      yaziPrimary: Colors.white,
      yaziSecondary: Color(0xFFFFCCBC),
      ayirac: Color(0xFF6D3030),
      arkaPlanGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6D3030), Color(0xFF4A1C1C), Color(0xFF2C1010)],
      ),
      isim: 'Akşam',
      aciklama: 'Gün batımı kızıllığı',
      ikon: Icons.wb_twilight,
    ),
    AppTema.yildizli: TemaRenkleri(
      arkaPlan: Color(0xFF0D0D1A),
      kartArkaPlan: Color(0xFF1A1A2E),
      vurgu: Color(0xFFB388FF), // Light purple
      vurguSecondary: Color(0xFFEA80FC),
      yaziPrimary: Colors.white,
      yaziSecondary: Color(0xFF9E9E9E),
      ayirac: Color(0xFF252540),
      arkaPlanGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF16162D), Color(0xFF0D0D1A)],
      ),
      isim: 'Yıldızlı',
      aciklama: 'Derin gece gökyüzü',
      ikon: Icons.star,
    ),
  };

  TemaRenkleri get renkler => temalar[_mevcutTema]!;

  Future<void> temayiYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final temaIndex = prefs.getInt('tema_index') ?? 0;
    _mevcutTema = AppTema.values[temaIndex];
    notifyListeners();
  }

  Future<void> temayiDegistir(AppTema yeniTema) async {
    _mevcutTema = yeniTema;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tema_index', yeniTema.index);
    notifyListeners();
  }

  // Aktif tema renkleriyle ThemeData oluştur
  ThemeData buildThemeData() {
    final r = renkler;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: r.arkaPlan,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: r.yaziPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
        iconTheme: IconThemeData(color: r.yaziPrimary),
      ),
      colorScheme: ColorScheme.dark(
        primary: r.vurgu,
        secondary: r.vurguSecondary,
        surface: r.kartArkaPlan,
        background: r.arkaPlan,
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: r.yaziPrimary),
        bodyMedium: TextStyle(color: r.yaziPrimary),
        bodySmall: TextStyle(color: r.yaziSecondary),
      ),
      iconTheme: IconThemeData(color: r.vurgu),
      dividerColor: r.ayirac,
      cardColor: r.kartArkaPlan,
    );
  }
}
