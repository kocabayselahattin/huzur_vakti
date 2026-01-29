import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

/// Titreşim servisini yöneten sınıf
class VibrationService {
  static const MethodChannel _channel = MethodChannel('huzur_vakti/vibration');

  /// Hafif titreşim (her tıklamada)
  static Future<void> light() async {
    if (Platform.isAndroid) {
      // Android'de doğrudan native titreşim kullan (daha güvenilir)
      try {
        await _channel.invokeMethod('vibrate', {'duration': 25});
        return;
      } catch (e) {
        debugPrint('⚠️ Native hafif titreşim hatası: $e');
      }
    }
    // iOS veya hata durumunda HapticFeedback dene
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('⚠️ HapticFeedback hatası: $e');
    }
  }

  /// Orta şiddette titreşim (normal tıklama)
  static Future<void> medium() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('vibrate', {'duration': 50});
        return;
      } catch (e) {
        debugPrint('⚠️ Native orta titreşim hatası: $e');
      }
    }
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('⚠️ HapticFeedback hatası: $e');
    }
  }

  /// Güçlü titreşim (tur tamamlama, sıfırlama)
  static Future<void> heavy() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('vibrate', {'duration': 80});
        return;
      } catch (e) {
        debugPrint('⚠️ Native güçlü titreşim hatası: $e');
      }
    }
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('⚠️ HapticFeedback hatası: $e');
    }
  }

  /// Seçim değişikliği titreşimi
  static Future<void> selection() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('vibrate', {'duration': 15});
        return;
      } catch (e) {
        debugPrint('⚠️ Native seçim titreşimi hatası: $e');
      }
    }
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('⚠️ Seçim titreşimi hatası: $e');
    }
  }

  /// Özel süreli titreşim (Android native)
  static Future<void> vibrate(int durationMs) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('vibrate', {'duration': durationMs});
      } catch (e) {
        debugPrint('⚠️ Native titreşim hatası: $e');
        await HapticFeedback.selectionClick();
      }
    } else {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Pattern titreşim (Android native)
  static Future<void> vibratePattern(List<int> pattern) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('vibratePattern', {'pattern': pattern});
      } catch (e) {
        debugPrint('⚠️ Pattern titreşim hatası: $e');
      }
    }
  }

  /// Başarı titreşimi (2 kez kesik kesik)
  static Future<void> success() async {
    if (Platform.isAndroid) {
      // 2 kez kesik kesik titreşim: bekleme-titreşim-bekleme-titreşim
      await vibratePattern([0, 80, 100, 80]);
    } else {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    }
  }
}
