import 'package:flutter/services.dart';

/// Widget'ları ana ekrana ekleme servisi
class WidgetPinService {
  static const MethodChannel _channel = MethodChannel('huzur_vakti/widgets');

  /// Bu cihaz widget pinlemeyi destekliyor mu?
  static Future<bool> canPinWidgets() async {
    try {
      final result = await _channel.invokeMethod<bool>('canPinWidgets');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Widget'ı ana ekrana ekle
  /// [widgetType]: 'klasik', 'mini', 'glass', 'neon', 'cosmic', 'timeline', 'zen', 'origami'
  static Future<bool> pinWidget(String widgetType) async {
    try {
      final result = await _channel.invokeMethod<bool>('pinWidget', {
        'widgetType': widgetType,
      });
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
