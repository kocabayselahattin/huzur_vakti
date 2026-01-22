import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'pages/splash_screen.dart';
import 'services/tema_service.dart';
import 'services/home_widget_service.dart';
import 'services/dnd_service.dart';
import 'services/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'services/scheduled_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Uygulama dikey yönde sabit kalsın
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Tarih formatını Türkçe için başlat
  await initializeDateFormatting('tr_TR', null);
  
  // Tema servisini başlat
  final temaService = TemaService();
  await temaService.temayiYukle();
  
  // Dil servisini başlat
  final languageService = LanguageService();
  await languageService.load();
  
  // Home Widget servisini başlat ve arka plan güncellemelerini planla
  await HomeWidgetService.initialize();
  
  // Android için arka plan widget güncellemelerini başlat
  if (Platform.isAndroid) {
    try {
      await const MethodChannel('huzur_vakti/widgets')
          .invokeMethod('scheduleWidgetUpdates');
    } catch (e) {
      print('⚠️ Widget arka plan güncellemeleri başlatılamadı: $e');
    }
  }

  // Sessize alma ayarı açıksa DND zamanlamasını kur
  final prefs = await SharedPreferences.getInstance();
  final sessizeAl = prefs.getBool('sessize_al') ?? false;
  if (sessizeAl) {
    await DndService.schedulePrayerDnd();
  }

  // Bildirim altyapısını başlat
  await NotificationService.initialize(null);
  
  // Zamanlanmış bildirim servisini başlat
  await ScheduledNotificationService.initialize();
  
  // 🔔 Uygulama başlatıldığında alarmları yeniden zamanla
  // Bu boot sonrası veya uygulama güncellemesi sonrası alarmları geri yükler
  await ScheduledNotificationService.scheduleAllPrayerNotifications();
  
  runApp(const HuzurVaktiApp());
}

class HuzurVaktiApp extends StatefulWidget {
  const HuzurVaktiApp({super.key});

  @override
  State<HuzurVaktiApp> createState() => _HuzurVaktiAppState();
}

class _HuzurVaktiAppState extends State<HuzurVaktiApp> {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onTemaChanged);
    _languageService.addListener(_onTemaChanged);
  }

  @override
  void dispose() {
    _temaService.removeListener(_onTemaChanged);
    _languageService.removeListener(_onTemaChanged);
    super.dispose();
  }

  void _onTemaChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _languageService['app_name'],
      theme: _temaService.buildThemeData(),
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const SplashScreen(),
    );
  }
}
