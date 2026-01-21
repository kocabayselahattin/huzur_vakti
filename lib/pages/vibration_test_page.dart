import 'package:flutter/material.dart';
import '../services/vibration_service.dart';
import '../services/language_service.dart';

class VibrationTestPage extends StatefulWidget {
  const VibrationTestPage({super.key});

  @override
  State<VibrationTestPage> createState() => _VibrationTestPageState();
}

class _VibrationTestPageState extends State<VibrationTestPage> {
  final LanguageService _languageService = LanguageService();
  late String _sonDurum;

  @override
  void initState() {
    super.initState();
    _sonDurum = _languageService['test_not_started'] ?? 'Test başlamadı';
  }

  Future<void> _testVibration(String type) async {
    setState(() => _sonDurum = '${_languageService['testing'] ?? 'Test ediliyor'}: $type');
    
    try {
      switch (type) {
        case 'light':
          await VibrationService.light();
          break;
        case 'medium':
          await VibrationService.medium();
          break;
        case 'heavy':
          await VibrationService.heavy();
          break;
        case 'selection':
          await VibrationService.selection();
          break;
        case 'success':
          await VibrationService.success();
          break;
      }
      setState(() => _sonDurum = '✅ $type ${_languageService['vibration_success'] ?? 'titreşimi başarılı'}');
    } catch (e) {
      setState(() => _sonDurum = '❌ ${_languageService['error'] ?? 'Hata'}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_languageService['vibration_test_title'] ?? 'Titreşim Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _sonDurum,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${_languageService['vibration_tests'] ?? 'Titreşim Testleri'}:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _testVibration('light'),
              child: Text(_languageService['light_vibration'] ?? 'Hafif Titreşim (Light)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testVibration('medium'),
              child: Text(_languageService['medium_vibration'] ?? 'Orta Titreşim (Medium)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testVibration('heavy'),
              child: Text(_languageService['heavy_vibration'] ?? 'Güçlü Titreşim (Heavy)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testVibration('selection'),
              child: Text(_languageService['selection_vibration'] ?? 'Seçim Titreşimi (Selection)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _testVibration('success'),
              child: Text(_languageService['success_vibration'] ?? 'Başarı Titreşimi (Success Pattern)'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              '${_languageService['test_steps'] ?? 'Test Adımları'}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_languageService['test_step_1'] ?? '1. Her butona basın ve titreşim hissedin'),
            Text(_languageService['test_step_2'] ?? '2. Telefon sessize alınmış olabilir (kontrol edin)'),
            Text(_languageService['test_step_3'] ?? '3. Cihazın titreşim ayarları açık olmalı'),
            Text(_languageService['test_step_4'] ?? '4. Eğer hiçbiri çalışmazsa cihaz sorunu olabilir'),
          ],
        ),
      ),
    );
  }
}
