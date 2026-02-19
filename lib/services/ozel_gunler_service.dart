import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'diyanet_api_service.dart';
import 'konum_service.dart';
import 'language_service.dart';
import 'alarm_service.dart';

/// Special day and night types
enum OzelGunTuru { bayram, kandil, mubarekGece, onemliGun }

/// Special day model - pulls translations dynamically
class OzelGun {
  final String adKey;
  final String aciklamaKey;
  final OzelGunTuru tur;
  final int hicriAy;
  final int hicriGun;
  final bool geceOncesiMi; // Kandil nights start on the previous night

  const OzelGun({
    required this.adKey,
    required this.aciklamaKey,
    required this.tur,
    required this.hicriAy,
    required this.hicriGun,
    this.geceOncesiMi = false,
  });

  /// Returns translated name
  String get ad {
    final langService = LanguageService();
    return langService[adKey] ?? adKey;
  }

  /// Returns translated description
  String get aciklama {
    final langService = LanguageService();
    return langService[aciklamaKey] ?? aciklamaKey;
  }

  /// Returns greeting message
  String get tebrikMesaji {
    final langService = LanguageService();
    switch (tur) {
      case OzelGunTuru.bayram:
        return '${langService['eid_mubarak'] ?? ''} 🌙';
      case OzelGunTuru.kandil:
        return '${langService['kandil_mubarak'] ?? ''} ✨';
      case OzelGunTuru.mubarekGece:
        return '$ad ${langService['blessed_night'] ?? ''} 🤲';
      case OzelGunTuru.onemliGun:
        return '$ad ${langService['blessed_day'] ?? ''} 📿';
    }
  }

  /// Subtitle message
  String get altMesaj {
    return aciklama;
  }
}

class OzelGunlerService {
  static const String _sonGosterilenGunKey = 'son_gosterilen_ozel_gun';

  static const String _hijriDayShiftKey = 'hijri_day_shift';
  static const String _hijriDayShiftDateKey = 'hijri_day_shift_date';

  static int _hijriDayShift = 0;

  /// Session-level popup shown flag
  /// Stays true during the session to show the popup only once
  static bool _sessionPopupShown = false;

  /// Sync Hijri calculations with Turkey/Diyanet calendar to prevent 1-day drift.
  ///
  /// The `hijri` package (Umm al-Qura) can differ from Turkey's official
  /// calendar on some dates (e.g., Ramadan start, Berat) by ±1 day.
  ///
  /// We compute a small day shift (typically -1/0/+1) by finding which
  /// `HijriCalendar.fromDate(today + shift)` matches Diyanet's Hijri date.
  static Future<void> syncHijriDayShiftWithDiyanet() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month}-${now.day}';

      // Apply cached shift immediately if available.
      final cachedShift = prefs.getInt(_hijriDayShiftKey);
      if (cachedShift != null) {
        _hijriDayShift = cachedShift;
      }

      // If we already synced today, stop here.
      final cachedDateKey = prefs.getString(_hijriDayShiftDateKey);
      if (cachedDateKey == todayKey) {
        debugPrint(
          '🗓️ [HijriShift] Using cached shift for today: $_hijriDayShift',
        );
        return;
      }

      final ilceId = await KonumService.getIlceId();
      if (ilceId == null ||
          ilceId.isEmpty ||
          KonumService.isManualIlceId(ilceId)) {
        debugPrint('🗓️ [HijriShift] Skip: no Turkey district selected');
        return;
      }

      final vakitler = await DiyanetApiService.getBugunVakitler(ilceId);
      final hicriKisa = vakitler?['HicriTarihKisa']?.toString() ?? '';
      if (hicriKisa.isEmpty || !hicriKisa.contains('.')) {
        debugPrint('🗓️ [HijriShift] Skip: Diyanet Hijri date missing');
        return;
      }

      final parts = hicriKisa.split('.');
      if (parts.length < 3) return;

      final hDay = int.tryParse(parts[0]) ?? 0;
      final hMonth = int.tryParse(parts[1]) ?? 0;
      final hYear = int.tryParse(parts[2]) ?? 0;
      if (hDay <= 0 || hMonth <= 0 || hYear <= 0) return;

      final todayDate = DateTime(now.year, now.month, now.day);

      int? foundShift;
      for (final shift in const [-2, -1, 0, 1, 2]) {
        final testDate = todayDate.add(Duration(days: shift));
        final testHijri = HijriCalendar.fromDate(testDate);
        if (testHijri.hYear == hYear &&
            testHijri.hMonth == hMonth &&
            testHijri.hDay == hDay) {
          foundShift = shift;
          break;
        }
      }

      if (foundShift == null) {
        debugPrint(
          '🗓️ [HijriShift] No matching shift found (Diyanet=$hicriKisa)',
        );
        return;
      }

      _hijriDayShift = foundShift;
      await prefs.setInt(_hijriDayShiftKey, foundShift);
      await prefs.setString(_hijriDayShiftDateKey, todayKey);

      debugPrint(
        '🗓️ [HijriShift] Applied shift=$_hijriDayShift (Diyanet=$hicriKisa)',
      );
    } catch (e) {
      debugPrint('🗓️ [HijriShift] Failed to sync: $e');
    }
  }

  static HijriCalendar hijriNowTR() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    return HijriCalendar.fromDate(base.add(Duration(days: _hijriDayShift)));
  }

  static DateTime? _parseDottedDate(String value) {
    // Expected: dd.MM.yyyy
    final parts = value.split('.');
    if (parts.length < 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  static ({int day, int month, int year})? _parseDottedHijriDate(String value) {
    // Expected: dd.MM.yyyy (Hijri)
    final parts = value.split('.');
    if (parts.length < 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return (day: day, month: month, year: year);
  }

  static bool _isDateInRange(DateTime date, DateTime start, DateTime end) {
    return !date.isBefore(start) && !date.isAfter(end);
  }

  /// TEST MODE - used during development
  /// Should be false in production.
  static const bool _testModu = false;
  static const OzelGun _testOzelGun = OzelGun(
    adKey: 'barat',
    aciklamaKey: 'barat_desc',
    tur: OzelGunTuru.kandil,
    hicriAy: 8,
    hicriGun: 15,
    geceOncesiMi: true,
  );

  /// Special days by Hijri calendar
  /// Hijri months: 1-Muharram, 2-Safar, 3-Rabi al-Awwal, 4-Rabi al-Thani, 5-Jumada al-Awwal,
  /// 6-Jumada al-Thani, 7-Rajab, 8-Shaban, 9-Ramadan, 10-Shawwal, 11-Dhul Qadah, 12-Dhul Hijjah
  static const List<OzelGun> ozelGunler = [
    // Muharram (1)
    OzelGun(
      adKey: 'hijri_new_year',
      aciklamaKey: 'hijri_new_year_desc',
      tur: OzelGunTuru.onemliGun,
      hicriAy: 1,
      hicriGun: 1,
    ),
    OzelGun(
      adKey: 'ashura',
      aciklamaKey: 'ashura_desc',
      tur: OzelGunTuru.onemliGun,
      hicriAy: 1,
      hicriGun: 10,
    ),

    // Rabi al-Awwal (3)
    OzelGun(
      adKey: 'mawlid',
      aciklamaKey: 'mawlid_desc',
      tur: OzelGunTuru.kandil,
      hicriAy: 3,
      hicriGun: 12,
      geceOncesiMi: true,
    ),

    // Rajab (7)
    OzelGun(
      adKey: 'ragaib',
      aciklamaKey: 'ragaib_desc',
      tur: OzelGunTuru.kandil,
      hicriAy: 7,
      hicriGun: 1,
      geceOncesiMi: true,
    ),
    OzelGun(
      adKey: 'miraj',
      aciklamaKey: 'miraj_desc',
      tur: OzelGunTuru.kandil,
      hicriAy: 7,
      hicriGun: 27,
      geceOncesiMi: true,
    ),

    // Shaban (8)
    OzelGun(
      adKey: 'barat',
      aciklamaKey: 'barat_desc',
      tur: OzelGunTuru.kandil,
      hicriAy: 8,
      hicriGun: 15,
      geceOncesiMi: true,
    ),

    // Ramadan (9)
    OzelGun(
      adKey: 'ramadan_start',
      aciklamaKey: 'ramadan_start_desc',
      tur: OzelGunTuru.onemliGun,
      hicriAy: 9,
      hicriGun: 1,
    ),
    OzelGun(
      adKey: 'laylat_al_qadr',
      aciklamaKey: 'laylat_al_qadr_desc',
      tur: OzelGunTuru.mubarekGece,
      hicriAy: 9,
      hicriGun: 27,
      geceOncesiMi: true,
    ),

    // Shawwal (10)
    OzelGun(
      adKey: 'eid_al_fitr',
      aciklamaKey: 'eid_al_fitr_day1',
      tur: OzelGunTuru.bayram,
      hicriAy: 10,
      hicriGun: 1,
    ),
    OzelGun(
      adKey: 'eid_al_fitr',
      aciklamaKey: 'eid_al_fitr_day2',
      tur: OzelGunTuru.bayram,
      hicriAy: 10,
      hicriGun: 2,
    ),
    OzelGun(
      adKey: 'eid_al_fitr',
      aciklamaKey: 'eid_al_fitr_day3',
      tur: OzelGunTuru.bayram,
      hicriAy: 10,
      hicriGun: 3,
    ),

    // Dhul Hijjah (12)
    OzelGun(
      adKey: 'arafa',
      aciklamaKey: 'arafa_desc',
      tur: OzelGunTuru.onemliGun,
      hicriAy: 12,
      hicriGun: 9,
    ),
    OzelGun(
      adKey: 'eid_al_adha',
      aciklamaKey: 'eid_al_adha_day1',
      tur: OzelGunTuru.bayram,
      hicriAy: 12,
      hicriGun: 10,
    ),
    OzelGun(
      adKey: 'eid_al_adha',
      aciklamaKey: 'eid_al_adha_day2',
      tur: OzelGunTuru.bayram,
      hicriAy: 12,
      hicriGun: 11,
    ),
    OzelGun(
      adKey: 'eid_al_adha',
      aciklamaKey: 'eid_al_adha_day3',
      tur: OzelGunTuru.bayram,
      hicriAy: 12,
      hicriGun: 12,
    ),
    OzelGun(
      adKey: 'eid_al_adha',
      aciklamaKey: 'eid_al_adha_day4',
      tur: OzelGunTuru.bayram,
      hicriAy: 12,
      hicriGun: 13,
    ),
  ];

  /// Check if today is a special day
  /// Banner becomes active after 09:00
  static OzelGun? bugunOzelGunMu() {
    // TEST MODE - for development
    if (_testModu) {
      return _testOzelGun;
    }

    final now = DateTime.now();
    final hicri = hijriNowTR();
    final hicriAy = hicri.hMonth;
    final hicriGun = hicri.hDay;

    debugPrint(
      '📅 [OzelGun] Today: $now.day/$now.month/$now.year $now.hour:$now.minute',
    );
    debugPrint('📅 [OzelGun] Hicri: $hicriGun/$hicriAy/$hicri.hYear');

    for (final ozelGun in ozelGunler) {
      // 1. Normal special days (geceOncesiMi == false): only after 09:00
      if (!ozelGun.geceOncesiMi) {
        if (ozelGun.hicriAy == hicriAy && ozelGun.hicriGun == hicriGun) {
          if (now.hour >= 9) {
            debugPrint('✅ [OzelGun] Today is special: \${ozelGun.ad}');
            return ozelGun;
          } else {
            debugPrint(
              '⏰ [OzelGun] \${ozelGun.ad} exists but it is before 09:00 (\${now.hour}:\${now.minute})',
            );
          }
        }
      } else {
        // 2. Kandil/night days: from previous day 09:00 until next day 09:00
        // a) Previous day 09:00 until night
        if (ozelGun.hicriAy == hicriAy && ozelGun.hicriGun == hicriGun + 1) {
          if (now.hour >= 9) {
            debugPrint(
              '✅ [OzelGun] Tomorrow is kandil/night: \${ozelGun.ad} (show today)',
            );
            return ozelGun;
          } else {
            debugPrint(
              '⏰ [OzelGun] Tomorrow is \${ozelGun.ad} but it is before 09:00 (\${now.hour}:\${now.minute})',
            );
          }
        }
        // b) Main day 00:00 to 09:00
        if (ozelGun.hicriAy == hicriAy &&
            ozelGun.hicriGun == hicriGun &&
            now.hour < 9) {
          debugPrint(
            '✅ [OzelGun] Night continues: \${ozelGun.ad} (show until 09:00)',
          );
          return ozelGun;
        }
      }
    }

    debugPrint('❌ [OzelGun] No special day/night today');
    return null;
  }

  /// Check if popup should be shown today
  static Future<bool> popupGosterilmeliMi() async {
    // Do not show again if already shown in this session
    if (_sessionPopupShown) {
      return false;
    }

    final ozelGun = bugunOzelGunMu();
    if (ozelGun == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final sonGosterilen = prefs.getString(_sonGosterilenGunKey);

    final bugun = DateTime.now();
    final bugunKey = '${ozelGun.ad}_${bugun.year}_${bugun.month}_${bugun.day}';

    // Do not show again if already shown today
    if (sonGosterilen == bugunKey) {
      return false;
    }

    return true;
  }

  /// Mark popup as shown
  static Future<void> popupGosterildiIsaretle() async {
    // Mark session flag
    _sessionPopupShown = true;

    final ozelGun = bugunOzelGunMu();
    if (ozelGun == null) return;

    final prefs = await SharedPreferences.getInstance();
    final bugun = DateTime.now();
    final bugunKey = '${ozelGun.ad}_${bugun.year}_${bugun.month}_${bugun.day}';

    await prefs.setString(_sonGosterilenGunKey, bugunKey);
  }

  /// Get upcoming special days (within 30 days)
  static List<Map<String, dynamic>> yaklasanOzelGunler() {
    final List<Map<String, dynamic>> sonuc = [];
    final bugun = hijriNowTR();

    for (final ozelGun in ozelGunler) {
      // This year's date
      int hedefYil = bugun.hYear;

      // If this year's date passed, use next year
      if (ozelGun.hicriAy < bugun.hMonth ||
          (ozelGun.hicriAy == bugun.hMonth && ozelGun.hicriGun < bugun.hDay)) {
        hedefYil++;
      }

      try {
        final hicriTarih = HijriCalendar()
          ..hYear = hedefYil
          ..hMonth = ozelGun.hicriAy
          ..hDay = ozelGun.hicriGun;

        final miladiTarih = hicriTarih.hijriToGregorian(
          hedefYil,
          ozelGun.hicriAy,
          ozelGun.hicriGun,
        );
        final tarih = DateTime(
          miladiTarih.year,
          miladiTarih.month,
          miladiTarih.day,
        ).subtract(Duration(days: _hijriDayShift));
        final simdi = DateTime.now();
        final fark = tarih.difference(simdi).inDays;

        // Add those within 365 days
        if (fark >= 0 && fark <= 365) {
          sonuc.add({
            'ozelGun': ozelGun,
            'tarih': tarih,
            'kalanGun': fark,
            'hicriTarih':
                '${ozelGun.hicriGun} ${_getHicriAyAdi(ozelGun.hicriAy)} $hedefYil',
          });
        }
      } catch (e) {
        // Date conversion error
        debugPrint('Date conversion error: $e');
      }
    }

    // Sort by date
    sonuc.sort(
      (a, b) => (a['kalanGun'] as int).compareTo(b['kalanGun'] as int),
    );

    return sonuc;
  }

  /// Get upcoming special days using Turkey/Diyanet calendar mapping.
  ///
  /// This avoids 1-day drift and also handles Hijri month length differences
  /// (e.g., Ramadan can be 29 days in Turkey).
  static Future<List<Map<String, dynamic>>> yaklasanOzelGunlerAsync({
    int daysAhead = 365,
  }) async {
    final ilceId = await KonumService.getIlceId();
    if (ilceId == null ||
        ilceId.isEmpty ||
        KonumService.isManualIlceId(ilceId)) {
      return yaklasanOzelGunler();
    }

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = startDate.add(Duration(days: daysAhead));

    final dayRows = <({DateTime gDate, int hDay, int hMonth, int hYear})>[];

    // Iterate months between startDate and endDate (inclusive).
    var year = startDate.year;
    var month = startDate.month;
    while (true) {
      final monthStart = DateTime(year, month, 1);
      if (monthStart.isAfter(endDate)) break;

      final list = await DiyanetApiService.getAylikVakitler(
        ilceId,
        year,
        month,
      );
      for (final item in list) {
        final gStr = item['MiladiTarihKisa']?.toString() ?? '';
        final hStr = item['HicriTarihKisa']?.toString() ?? '';
        if (gStr.isEmpty || hStr.isEmpty) continue;

        final gDate = _parseDottedDate(gStr);
        final h = _parseDottedHijriDate(hStr);
        if (gDate == null || h == null) continue;

        if (_isDateInRange(gDate, startDate, endDate)) {
          dayRows.add((
            gDate: gDate,
            hDay: h.day,
            hMonth: h.month,
            hYear: h.year,
          ));
        }
      }

      // next month
      if (month == 12) {
        month = 1;
        year++;
      } else {
        month++;
      }
    }

    // Ensure chronological order.
    dayRows.sort((a, b) => a.gDate.compareTo(b.gDate));

    final result = <Map<String, dynamic>>[];

    for (final ozelGun in ozelGunler) {
      final match =
          dayRows.cast<dynamic>().firstWhere(
                (row) =>
                    row.hMonth == ozelGun.hicriAy &&
                    row.hDay == ozelGun.hicriGun,
                orElse: () => null,
              )
              as ({DateTime gDate, int hDay, int hMonth, int hYear})?;

      if (match == null) continue;

      final kalanGun = match.gDate.difference(startDate).inDays;
      if (kalanGun < 0 || kalanGun > daysAhead) continue;

      result.add({
        'ozelGun': ozelGun,
        'tarih': match.gDate,
        'kalanGun': kalanGun,
        'hicriTarih':
            '${ozelGun.hicriGun} ${_getHicriAyAdi(ozelGun.hicriAy)} ${match.hYear}',
      });
    }

    result.sort(
      (a, b) => (a['kalanGun'] as int).compareTo(b['kalanGun'] as int),
    );
    return result;
  }

  /// Return Hijri month name
  static String _getHicriAyAdi(int ay) {
    final languageService = LanguageService();
    if (ay >= 1 && ay <= 12) {
      return languageService['hijri_month_$ay'] ?? '';
    }
    return '';
  }

  // ========== SPECIAL DAY NOTIFICATIONS ==========

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const int _ozelGunBildirimIdBase = 5000;

  /// Schedule special day notifications
  /// Schedule notifications for special days within 7 days
  /// For geceOncesiMi: schedule both previous day 09:00 and main day 00:05
  static Future<void> scheduleOzelGunBildirimleri() async {
    // Ensure Hijri calendar is aligned (important for conversions used below).
    await syncHijriDayShiftWithDiyanet();

    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('ozel_gun_bildirimleri_aktif') ?? true;

    if (!enabled) {
      debugPrint('📅 Special day notifications disabled');
      await cancelOzelGunBildirimleri();
      return;
    }

    debugPrint('📅 Scheduling special day notifications...');

    // Cancel existing notifications first
    await cancelOzelGunBildirimleri();

    // Get upcoming special days (prefer Diyanet mapping)
    final yaklasanlar = await yaklasanOzelGunlerAsync(daysAhead: 14);
    int zamanlanandi = 0;

    debugPrint('📅 ========== SPECIAL DAY SCHEDULING ==========');
    debugPrint('📅 Found ${yaklasanlar.length} special days total');

    int idOffset = 0;
    for (int i = 0; i < yaklasanlar.length && i < 10; i++) {
      final item = yaklasanlar[i];
      final ozelGun = item['ozelGun'] as OzelGun;
      final tarih = item['tarih'] as DateTime;
      final kalanGun = item['kalanGun'] as int;

      debugPrint('\n🔍 Checking: ${ozelGun.ad}');
      debugPrint('   📆 Date: ${tarih.day}/${tarih.month}/${tarih.year}');
      debugPrint('   ⏰ Days left: $kalanGun');
      debugPrint('   🌙 Night-before: ${ozelGun.geceOncesiMi}');

      // Only schedule for special days within 7 days
      if (kalanGun > 7) {
        debugPrint('   ⏭️ Skipped: more than 7 days');
        continue;
      }

      if (ozelGun.geceOncesiMi) {
        // 1) Previous day at 09:00
        DateTime oncekiGunBildirimi = DateTime(
          tarih.year,
          tarih.month,
          tarih.day - 1,
          9,
          0,
        );
        if (oncekiGunBildirimi.isAfter(DateTime.now())) {
          final tzOncekiGun = tz.TZDateTime.from(oncekiGunBildirimi, tz.local);
          debugPrint(
            '   📍 Night-before notification: ${oncekiGunBildirimi.day}/${oncekiGunBildirimi.month} ${oncekiGunBildirimi.hour}:${oncekiGunBildirimi.minute.toString().padLeft(2, "0")}',
          );
          try {
            await _scheduleOzelGunBildirimi(
              id: _ozelGunBildirimIdBase + idOffset,
              ozelGun: ozelGun,
              scheduledDate: tzOncekiGun,
            );
            zamanlanandi++;
            idOffset++;
          } catch (e) {
            debugPrint(
              '❌ Special day notification scheduling failed: ${ozelGun.ad} - $e',
            );
          }
        }
        // 2) Main day at 00:05
        DateTime geceBildirimi = DateTime(
          tarih.year,
          tarih.month,
          tarih.day,
          0,
          5,
        );
        if (geceBildirimi.isAfter(DateTime.now())) {
          final tzGece = tz.TZDateTime.from(geceBildirimi, tz.local);
          debugPrint(
            '   📍 Night notification: ${geceBildirimi.day}/${geceBildirimi.month} ${geceBildirimi.hour}:${geceBildirimi.minute.toString().padLeft(2, "0")}',
          );
          try {
            await _scheduleOzelGunBildirimi(
              id: _ozelGunBildirimIdBase + idOffset,
              ozelGun: ozelGun,
              scheduledDate: tzGece,
            );
            zamanlanandi++;
            idOffset++;
          } catch (e) {
            debugPrint(
              '❌ Special day notification scheduling failed: ${ozelGun.ad} - $e',
            );
          }
        }
      } else {
        // Other days: 09:00 of the same day
        DateTime bildirimZamani = DateTime(
          tarih.year,
          tarih.month,
          tarih.day,
          9,
          0,
        );
        if (bildirimZamani.isAfter(DateTime.now())) {
          final tzBildirimZamani = tz.TZDateTime.from(bildirimZamani, tz.local);
          debugPrint(
            '   📍 Normal day notification: ${bildirimZamani.day}/${bildirimZamani.month} ${bildirimZamani.hour}:${bildirimZamani.minute.toString().padLeft(2, "0")}',
          );
          try {
            await _scheduleOzelGunBildirimi(
              id: _ozelGunBildirimIdBase + idOffset,
              ozelGun: ozelGun,
              scheduledDate: tzBildirimZamani,
            );
            zamanlanandi++;
            idOffset++;
          } catch (e) {
            debugPrint(
              '❌ Special day notification scheduling failed: ${ozelGun.ad} - $e',
            );
          }
        }
      }
    }

    debugPrint('✅ $zamanlanandi special day notifications scheduled');
  }

  /// Schedule a single special day notification using AlarmManager
  /// Works even when the app is closed
  static Future<void> _scheduleOzelGunBildirimi({
    required int id,
    required OzelGun ozelGun,
    required tz.TZDateTime scheduledDate,
  }) async {
    final languageService = LanguageService();
    await languageService.load();

    // Notification content
    String icon;
    switch (ozelGun.tur) {
      case OzelGunTuru.bayram:
        icon = '🎉';
        break;
      case OzelGunTuru.kandil:
        icon = '🕯️';
        break;
      case OzelGunTuru.mubarekGece:
        icon = '🌙';
        break;
      case OzelGunTuru.onemliGun:
        icon = '📿';
        break;
    }

    final title = '$icon ${ozelGun.ad}';
    final body = ozelGun.tebrikMesaji;

    // Schedule via AlarmManager (works even when app is closed)
    final triggerAtMillis = scheduledDate.millisecondsSinceEpoch;

    final success = await AlarmService.scheduleOzelGunAlarm(
      title: title,
      body: body,
      triggerAtMillis: triggerAtMillis,
      alarmId: id,
    );

    final tarihStr =
        '${scheduledDate.day}/${scheduledDate.month} ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}';

    if (success) {
      debugPrint(
        '   📅 ${ozelGun.ad} - $tarihStr (ID: $id) - scheduled via AlarmManager ✅',
      );
    } else {
      debugPrint(
        '   ❌ ${ozelGun.ad} - AlarmManager scheduling failed, using fallback',
      );

      // Fallback: use zonedSchedule
      final channelName =
          languageService['special_days_channel_name'] ?? 'Special days';
      final channelDesc =
          languageService['special_days_channel_desc'] ??
          'Special days, nights, and holidays';
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'ozel_gunler_channel',
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        visibility: NotificationVisibility.public,
        autoCancel: false,
        ongoing: false,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: androidPlatformChannelSpecifics,
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'ozel_gun_${ozelGun.adKey}',
      );
      debugPrint(
        '   📅 ${ozelGun.ad} - $tarihStr (ID: $id) - scheduled via zonedSchedule',
      );
    }
  }

  /// Cancel special day notifications
  static Future<void> cancelOzelGunBildirimleri() async {
    for (int i = 0; i < 10; i++) {
      await _notificationsPlugin.cancel(id: _ozelGunBildirimIdBase + i);
      await AlarmService.cancelAlarm(_ozelGunBildirimIdBase + i);
    }
    debugPrint('🚫 Special day notifications canceled');
  }

  /// Enable/disable special day notifications
  static Future<void> setOzelGunBildirimleriEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ozel_gun_bildirimleri_aktif', enabled);

    if (enabled) {
      await scheduleOzelGunBildirimleri();
    } else {
      await cancelOzelGunBildirimleri();
    }
  }
}
