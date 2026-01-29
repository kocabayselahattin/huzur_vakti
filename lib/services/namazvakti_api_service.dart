import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Ezanvakti.herokuapp.com API servisi - DiyanetAPI için yedek
class NamazVaktiApiService {
  static const _baseUrl = 'https://ezanvakti.herokuapp.com';
  static final Map<String, Map<String, dynamic>> _cache = {};
  static final Map<String, DateTime> _cacheTimes = {};

  /// Bugünün namaz vakitlerini döndürür
  static Future<Map<String, String>?> getBugunVakitler(String ilceId) async {
    // Ezanvakti API format: vakitler/ilceId

    final cacheKey = 'today-$ilceId';
    final now = DateTime.now();

    // Cache kontrolü
    if (_cache.containsKey(cacheKey) && _cacheTimes.containsKey(cacheKey)) {
      final cacheTime = _cacheTimes[cacheKey]!;
      if (now.difference(cacheTime) < const Duration(hours: 6)) {
        final cached = _cache[cacheKey]!;
        return _formatVakitler(cached);
      }
    }

    try {
      final uri = Uri.parse('$_baseUrl/vakitler/$ilceId');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(body);

        if (decoded is List && decoded.isNotEmpty) {
          // Bugünün tarihini bul
          final bugunStr =
              '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

          Map<String, dynamic>? bugun;
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final tarih = item['MiladiTarihKisa'] ?? '';
              if (tarih == bugunStr) {
                bugun = item;
                break;
              }
            }
          }

          // Bulunamazsa ilk kaydı kullan
          bugun ??= decoded[0] as Map<String, dynamic>;

          _cache[cacheKey] = bugun;
          _cacheTimes[cacheKey] = now;

          return _formatVakitler(bugun);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Yedek API hatası: $e');
    }

    return null;
  }

  /// Aylık vakitleri döndürür
  static Future<List<Map<String, dynamic>>> getAylikVakitler(
    String ilceId,
    int yil,
    int ay,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/vakitler/$ilceId');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(body);

        if (decoded is List) {
          // Sadece istenen ayı filtrele
          final vakitler = decoded
              .where((v) {
                if (v is! Map<String, dynamic>) return false;
                final tarih = v['MiladiTarihKisa'] ?? '';
                try {
                  final parts = tarih.split('.');
                  if (parts.length == 3) {
                    final vAy = int.parse(parts[1]);
                    final vYil = int.parse(parts[2]);
                    return vYil == yil && vAy == ay;
                  }
                } catch (e) {
                  // Parse hatası
                }
                return false;
              })
              .map((v) => Map<String, dynamic>.from(v as Map))
              .toList();

          if (vakitler.isNotEmpty) {
            debugPrint('✅ Yedek API: ${vakitler.length} günlük veri');
            return vakitler;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Yedek API aylık vakit hatası: $e');
    }

    return [];
  }

  /// API yanıtını standart formata dönüştürür
  static Map<String, String> _formatVakitler(Map<String, dynamic> data) {
    return {
      'Imsak': data['Imsak']?.toString() ?? '05:30',
      'Gunes': data['Gunes']?.toString() ?? '07:00',
      'Ogle': data['Ogle']?.toString() ?? '12:30',
      'Ikindi': data['Ikindi']?.toString() ?? '15:30',
      'Aksam': data['Aksam']?.toString() ?? '18:00',
      'Yatsi': data['Yatsi']?.toString() ?? '19:30',
      'HicriTarihKisa': data['HicriTarihKisa']?.toString() ?? '',
      'HicriTarihUzun': data['HicriTarihUzun']?.toString() ?? '',
      'MiladiTarihKisa': data['MiladiTarihKisa']?.toString() ?? '',
      'MiladiTarihUzun': data['MiladiTarihUzun']?.toString() ?? '',
    };
  }

  /// Cache'i temizle
  static void clearCache() {
    _cache.clear();
    _cacheTimes.clear();
    debugPrint('✅ Yedek API cache temizlendi');
  }
}
