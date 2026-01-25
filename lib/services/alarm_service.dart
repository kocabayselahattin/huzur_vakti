import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Android alarm sistemi için Flutter servis sınıfı
/// Bildirim ayarları ile senkronize çalışır
class AlarmService {
  static const _channel = MethodChannel('huzur_vakti/alarms');

  /// Belirli bir vakit için alarm kurar
  /// [prayerName] - Vakit adı (Örn: "Sabah", "Öğle")
  /// [triggerAtMillis] - Alarmın tetikleneceği zaman (Unix timestamp ms)
  /// [soundPath] - Ses dosyası yolu (null ise varsayılan ses kullanılır)
  /// [useVibration] - Titreşim kullanılsın mı
  /// [alarmId] - Benzersiz alarm ID'si (varsayılan: prayerName.hashCode)
  static Future<bool> scheduleAlarm({
    required String prayerName,
    required int triggerAtMillis,
    String? soundPath,
    bool useVibration = true,
    int? alarmId,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final triggerTime = DateTime.fromMillisecondsSinceEpoch(triggerAtMillis);
      
      debugPrint('🔔 Alarm kurulacak: $prayerName');
      debugPrint('   Zaman: $triggerTime');
      debugPrint('   Ses: $soundPath');
      debugPrint('   ID: ${alarmId ?? prayerName.hashCode}');
      
      if (triggerAtMillis <= now) {
        debugPrint('⚠️ Alarm zamanı geçmiş, atlanıyor');
        return false;
      }
      
      final result = await _channel.invokeMethod<bool>('scheduleAlarm', {
        'prayerName': prayerName,
        'triggerAtMillis': triggerAtMillis,
        'soundPath': soundPath,
        'useVibration': useVibration,
        'alarmId': alarmId ?? prayerName.hashCode,
      });
      
      debugPrint('✅ Alarm kuruldu: $prayerName - Sonuç: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('❌ Alarm kurma hatası: $e');
      return false;
    }
  }

  /// Belirli bir alarmı iptal eder
  static Future<bool> cancelAlarm(int alarmId) async {
    try {
      final result = await _channel.invokeMethod<bool>('cancelAlarm', {
        'alarmId': alarmId,
      });
      return result ?? false;
    } catch (e) {
      print('Alarm iptal hatası: $e');
      return false;
    }
  }

  /// Tüm alarmları iptal eder
  static Future<bool> cancelAllAlarms() async {
    try {
      final result = await _channel.invokeMethod<bool>('cancelAllAlarms');
      return result ?? false;
    } catch (e) {
      print('Tüm alarmları iptal hatası: $e');
      return false;
    }
  }

  /// Alarm çalıyor mu kontrol eder
  static Future<bool> isAlarmPlaying() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAlarmPlaying');
      return result ?? false;
    } catch (e) {
      print('Alarm kontrol hatası: $e');
      return false;
    }
  }

  /// Çalan alarmı durdurur
  static Future<bool> stopAlarm() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopAlarm');
      return result ?? false;
    } catch (e) {
      print('Alarm durdurma hatası: $e');
      return false;
    }
  }

  /// Vakit ID'sinden benzersiz alarm ID'si oluşturur
  /// Aynı günde farklı vakitler için farklı ID'ler üretir
  static int generateAlarmId(String prayerKey, DateTime date) {
    // prayerKey: "imsak", "gunes", "ogle", "ikindi", "aksam", "yatsi", "imsak_erken" vs.
    // Tarih ve vakit bazında benzersiz ID
    // Vakit index'ini kullan: 1-İmsak, 2-Güneş, 3-Öğle, 4-İkindi, 5-Akşam, 6-Yatsı
    // Erken alarm için +10 ekle
    
    int vakitIndex;
    bool isErken = prayerKey.contains('_erken');
    String cleanKey = prayerKey.replaceAll('_erken', '');
    
    switch (cleanKey) {
      case 'imsak':
        vakitIndex = 1;
        break;
      case 'gunes':
        vakitIndex = 2;
        break;
      case 'ogle':
        vakitIndex = 3;
        break;
      case 'ikindi':
        vakitIndex = 4;
        break;
      case 'aksam':
        vakitIndex = 5;
        break;
      case 'yatsi':
        vakitIndex = 6;
        break;
      default:
        vakitIndex = 0;
    }
    
    if (isErken) {
      vakitIndex += 10; // Erken alarmlar için 11-16 arası
    }
    
    // Format: YYYYMMDD * 100 + vakitIndex
    // Örnek: 20260125 * 100 + 3 = 2026012503 (25 Ocak 2026 Öğle)
    final dateInt = date.year * 10000 + date.month * 100 + date.day;
    final alarmId = dateInt * 100 + vakitIndex;
    
    return alarmId;
  }
}
