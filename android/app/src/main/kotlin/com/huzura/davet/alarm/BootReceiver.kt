package com.huzura.davet.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import java.text.SimpleDateFormat
import java.util.*

/**
 * Cihaz yeniden başlatıldığında alarmları yeniden zamanlayan BroadcastReceiver
 * Boot sonrası alarmlar kaybolur, bu receiver onları geri yükler
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
        
        // Vakit isimleri ve SharedPreferences key'leri
        private val VAKIT_KEYS = listOf("imsak", "gunes", "ogle", "ikindi", "aksam", "yatsi")
        private val VAKIT_NAMES = mapOf(
            "imsak" to "İmsak",
            "gunes" to "Güneş", 
            "ogle" to "Öğle",
            "ikindi" to "İkindi",
            "aksam" to "Akşam",
            "yatsi" to "Yatsı"
        )
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d(TAG, "📱 Cihaz yeniden başlatıldı veya uygulama güncellendi")
            Log.d(TAG, "   Action: ${intent.action}")
            
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // Android 15+ kısıtı: BOOT_COMPLETED alıcısından doğrudan FGS başlatılamaz.
            // Bu nedenle boot sonrasında güvenli başlangıç için bayrak yazılır.
            val kilitEkraniBildirimiAktif = prefs.getBoolean("flutter.kilit_ekrani_bildirimi_aktif", false)
            prefs.edit()
                .putBoolean("flutter.pending_lock_screen_start_after_boot", kilitEkraniBildirimiAktif)
                .apply()

            if (kilitEkraniBildirimiAktif) {
                Log.d(TAG, "🔒 Kilit ekranı bildirimi aktif, uygulama açılınca güvenli başlatılacak")
            }
            
            // ÖNEMLİ: Kaydedilmiş vakit alarmlarını yeniden zamanla
            rescheduleAllAlarms(context, prefs)
            
            Log.d(TAG, "✅ Boot receiver işlemi tamamlandı")
        }
    }
    
    /**
     * Kaydedilmiş tüm vakit alarmlarını yeniden zamanla
     */
    private fun rescheduleAllAlarms(context: Context, prefs: android.content.SharedPreferences) {
        Log.d(TAG, "🔔 Vakit alarmları yeniden zamanlanıyor...")
        
        val now = System.currentTimeMillis()
        val today = Calendar.getInstance()
        var scheduledCount = 0
        
        // 7 gün için alarmları zamanla
        for (dayOffset in 0..6) {
            val targetDay = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, dayOffset)
            }
            val dateKey = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault()).format(targetDay.time)
            
            for (vakitKey in VAKIT_KEYS) {
                // Bildirim açık mı?
                val bildirimAcik = prefs.getBoolean("flutter.bildirim_$vakitKey", true)
                if (!bildirimAcik) continue
                
                // Vaktinde bildirim açık mı?
                val varsayilanVaktinde = vakitKey in listOf("ogle", "ikindi", "aksam", "yatsi")
                val vaktindeBildirim = prefs.getBoolean("flutter.vaktinde_$vakitKey", varsayilanVaktinde)
                
                // Vakit saatini al (kaydedilmiş)
                val vakitSaati = prefs.getString("flutter.vakit_${vakitKey}_$dateKey", null)
                if (vakitSaati == null) {
                    // Bugün için kayıtlı vakit yoksa geç (Flutter tarafı zamanlamayı yapacak)
                    continue
                }
                
                // Saat:Dakika parse et
                val parts = vakitSaati.split(":")
                if (parts.size != 2) continue
                
                val hour = parts[0].toIntOrNull() ?: continue
                val minute = parts[1].toIntOrNull() ?: continue
                
                // Erken bildirim dakikası
                val varsayilanErken = when(vakitKey) {
                    "gunes" -> 45
                    else -> 15
                }
                val erkenKey = "flutter.erken_$vakitKey"
                val erkenDakika = when (val raw = prefs.all[erkenKey]) {
                    is Int -> raw
                    is Long -> raw.toInt()
                    is Number -> raw.toInt()
                    is String -> raw.toIntOrNull() ?: varsayilanErken
                    else -> prefs.getInt(erkenKey, varsayilanErken)
                }
                
                // Ses ID'leri (artık .mp3 uzantısı yok)
                val onTimeSoundId = prefs.getString("flutter.bildirim_sesi_$vakitKey", "best") ?: "best"
                val earlySoundId = prefs.getString("flutter.erken_bildirim_sesi_$vakitKey", onTimeSoundId) ?: onTimeSoundId
                
                // Tam vakit zamanı
                val vakitZamani = Calendar.getInstance().apply {
                    set(Calendar.YEAR, targetDay.get(Calendar.YEAR))
                    set(Calendar.MONTH, targetDay.get(Calendar.MONTH))
                    set(Calendar.DAY_OF_MONTH, targetDay.get(Calendar.DAY_OF_MONTH))
                    set(Calendar.HOUR_OF_DAY, hour)
                    set(Calendar.MINUTE, minute)
                    set(Calendar.SECOND, 0)
                    set(Calendar.MILLISECOND, 0)
                }
                
                val vakitName = VAKIT_NAMES[vakitKey] ?: vakitKey
                
                // 1. ERKEN BİLDİRİM
                if (erkenDakika > 0) {
                    val erkenZamani = vakitZamani.timeInMillis - (erkenDakika * 60 * 1000)
                    if (erkenZamani > now) {
                        val erkenAlarmId = generateAlarmId(vakitKey, "erken", dayOffset)
                        scheduleAlarm(
                            context = context,
                            alarmId = erkenAlarmId,
                            prayerName = vakitName,
                            triggerAtMillis = erkenZamani,
                            soundPath = earlySoundId,
                            isEarly = true,
                            earlyMinutes = erkenDakika
                        )
                        scheduledCount++
                    }
                }
                
                // 2. VAKTİNDE BİLDİRİM
                if (vaktindeBildirim && vakitZamani.timeInMillis > now) {
                    val alarmId = generateAlarmId(vakitKey, "vakit", dayOffset)
                    scheduleAlarm(
                        context = context,
                        alarmId = alarmId,
                        prayerName = vakitName,
                        triggerAtMillis = vakitZamani.timeInMillis,
                        soundPath = onTimeSoundId,
                        isEarly = false,
                        earlyMinutes = 0
                    )
                    scheduledCount++
                }
            }
        }
        
        Log.d(TAG, "✅ $scheduledCount alarm yeniden zamanlandı")
    }
    
    /**
     * Benzersiz alarm ID oluştur
     */
    private fun generateAlarmId(vakitKey: String, type: String, dayOffset: Int): Int {
        val vakitIndex = VAKIT_KEYS.indexOf(vakitKey)
        val typeIndex = if (type == "erken") 0 else 1
        return (dayOffset * 100) + (vakitIndex * 10) + typeIndex + 1000
    }
    
    /**
     * Alarm zamanla
     */
    private fun scheduleAlarm(
        context: Context,
        alarmId: Int,
        prayerName: String,
        triggerAtMillis: Long,
        soundPath: String,
        isEarly: Boolean,
        earlyMinutes: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_PRAYER_ALARM
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_VAKIT_NAME, prayerName)
            putExtra(AlarmReceiver.EXTRA_SOUND_FILE, soundPath)
            putExtra(AlarmReceiver.EXTRA_IS_EARLY, isEarly)
            putExtra(AlarmReceiver.EXTRA_EARLY_MINUTES, earlyMinutes)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setAlarmClock(
                        AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent),
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent),
                    pendingIntent
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
            
            val time = SimpleDateFormat("dd.MM HH:mm", Locale.getDefault()).format(Date(triggerAtMillis))
            val type = if (isEarly) "Erken ($earlyMinutes dk)" else "Vaktinde"
            Log.d(TAG, "   ✅ $prayerName - $type - $time (ID: $alarmId)")
        } catch (e: Exception) {
            Log.e(TAG, "   ❌ Alarm zamanlanamadı: ${e.message}")
        }
    }
}
