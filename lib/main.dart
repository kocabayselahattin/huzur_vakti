import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/splash_screen.dart';
import 'services/tema_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tema servisini başlat
  final temaService = TemaService();
  await temaService.temayiYukle();
  
  initializeDateFormatting('tr_TR', null).then((_) => runApp(const HuzurVaktiApp()));
}

class HuzurVaktiApp extends StatefulWidget {
  const HuzurVaktiApp({super.key});

  @override
  State<HuzurVaktiApp> createState() => _HuzurVaktiAppState();
}

class _HuzurVaktiAppState extends State<HuzurVaktiApp> {
  final TemaService _temaService = TemaService();

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onTemaChanged);
  }

  @override
  void dispose() {
    _temaService.removeListener(_onTemaChanged);
    super.dispose();
  }

  void _onTemaChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Huzur Vakti',
      theme: _temaService.buildThemeData(),
      home: const SplashScreen(),
    );
  }
}
