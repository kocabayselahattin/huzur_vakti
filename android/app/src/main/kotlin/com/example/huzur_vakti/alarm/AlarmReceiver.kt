package com.example.huzur_vakti.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log

/**
 * Vakit alarmlarını alan BroadcastReceiver
 * AlarmManager tarafından tetiklenir ve AlarmService'i başlatır
 */
class AlarmReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "AlarmReceiver"
        const val ACTION_PRAYER_ALARM = "com.example.huzur_vakti.PRAYER_ALARM"
        const val EXTRA_VAKIT_NAME = "vakit_name"
        const val EXTRA_VAKIT_TIME = "vakit_time"
        const val EXTRA_SOUND_FILE = "sound_file"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_IS_EARLY = "is_early"
        const val EXTRA_EARLY_MINUTES = "early_minutes"
        
        /**
         * Alarm zamanla
         */
        fun scheduleAlarm(
            context: Context,
            alarmId: Int,
            prayerName: String,
            triggerAtMillis: Long,
            soundPath: String?,
            useVibration: Boolean = true
        ) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            // Ses dosyası null veya boş ise SharedPreferences'tan veya varsayılan kullan
            var actualSoundPath = soundPath
            if (actualSoundPath.isNullOrEmpty()) {
                val vakitKey = prayerName.lowercase()
                    .replace("ı", "i").replace("ö", "o").replace("ü", "u")
                    .replace("ş", "s").replace("ğ", "g").replace("ç", "c")
                    .let { name ->
                        when {
                            name.contains("imsak") || name.contains("sahur") -> "imsak"
                            name.contains("gunes") -> "gunes"
                            name.contains("ogle") -> "ogle"
                            name.contains("ikindi") -> "ikindi"
                            name.contains("aksam") -> "aksam"
                            name.contains("yatsi") -> "yatsi"
                            else -> ""
                        }
                    }
                
                if (vakitKey.isNotEmpty()) {
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val savedSound = prefs.getString("flutter.bildirim_sesi_$vakitKey", null)
                    if (!savedSound.isNullOrEmpty()) {
                        actualSoundPath = savedSound
                        Log.d(TAG, "🔊 Ses dosyası SharedPreferences'tan alındı: $vakitKey -> $actualSoundPath")
                    }
                }
                
                // Hala null ise varsayılan ses
                if (actualSoundPath.isNullOrEmpty()) {
                    actualSoundPath = "ding_dong.mp3"
                }
            }
            
            Log.d(TAG, "🔊 Alarm ses dosyası: $actualSoundPath")
            
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                action = ACTION_PRAYER_ALARM
                putExtra(EXTRA_ALARM_ID, alarmId)
                putExtra(EXTRA_VAKIT_NAME, prayerName)
                putExtra(EXTRA_VAKIT_TIME, "")
                putExtra(EXTRA_SOUND_FILE, actualSoundPath)
                putExtra(EXTRA_IS_EARLY, false)
                putExtra(EXTRA_EARLY_MINUTES, 0)
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            val triggerTime = java.text.SimpleDateFormat("dd.MM.yyyy HH:mm:ss", java.util.Locale.getDefault())
                .format(java.util.Date(triggerAtMillis))
            Log.d(TAG, "🕐 Alarm zamanlanıyor: $prayerName - $triggerTime (ID: $alarmId, Ses: $actualSoundPath)")
            
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val canScheduleExact = alarmManager.canScheduleExactAlarms()
                    Log.d(TAG, "📋 Exact alarm izni: $canScheduleExact")
                    
                    if (canScheduleExact) {
                        alarmManager.setAlarmClock(
                            AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent),
                            pendingIntent
                        )
                        Log.d(TAG, "✅ setAlarmClock ile zamanlandı")
                    } else {
                        // Exact alarm izni yoksa setAndAllowWhileIdle kullan (daha az güvenilir ama çalışır)
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent
                        )
                        Log.w(TAG, "⚠️ Exact alarm izni yok! setAndAllowWhileIdle kullanıldı (daha az güvenilir)")
                    }
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAlarmClock(
                        AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent),
                        pendingIntent
                    )
                    Log.d(TAG, "✅ setAlarmClock ile zamanlandı (M+)")
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                    Log.d(TAG, "✅ setExact ile zamanlandı")
                }
                
                Log.d(TAG, "✅ Alarm başarıyla zamanlandı: $prayerName - ID: $alarmId")
                
                // Alarm ID'sini kaydet
                saveAlarmId(context, alarmId)
            } catch (e: SecurityException) {
                Log.e(TAG, "❌ Alarm zamanlama SecurityException: ${e.message}")
                // Güvenlik hatası - izin yok, yine de inexact alarm dene
                try {
                    alarmManager.set(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                    Log.w(TAG, "⚠️ Fallback: Inexact alarm kullanıldı")
                } catch (e2: Exception) {
                    Log.e(TAG, "❌ Fallback alarm da başarısız: ${e2.message}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Alarm zamanlama hatası: ${e.message}")
            }
        }
        
        /**
         * Belirli bir alarmı iptal et
         */
        fun cancelAlarm(context: Context, alarmId: Int) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            
            val intent = Intent(context, AlarmReceiver::class.java).apply {
                action = ACTION_PRAYER_ALARM
            }
            
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                alarmId,
                intent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            
            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
                Log.d(TAG, "🔕 Alarm iptal edildi: ID $alarmId")
            }
            
            // Kayıtlı ID'yi sil
            removeAlarmId(context, alarmId)
        }
        
        /**
         * Tüm alarmları iptal et
         */
        fun cancelAllAlarms(context: Context) {
            // SharedPreferences'dan kayıtlı alarm ID'lerini al
            val prefs = context.getSharedPreferences("alarm_ids", Context.MODE_PRIVATE)
            val alarmIds = prefs.getStringSet("active_alarms", emptySet()) ?: emptySet()
            
            for (idStr in alarmIds) {
                val id = idStr.toIntOrNull() ?: continue
                cancelAlarm(context, id)
            }
            
            // Listeyi temizle
            prefs.edit().remove("active_alarms").apply()
            
            Log.d(TAG, "🔕 Tüm alarmlar iptal edildi (${alarmIds.size} adet)")
        }
        
        /**
         * Alarm ID'sini kaydet
         */
        private fun saveAlarmId(context: Context, alarmId: Int) {
            val prefs = context.getSharedPreferences("alarm_ids", Context.MODE_PRIVATE)
            val alarmIds = prefs.getStringSet("active_alarms", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
            alarmIds.add(alarmId.toString())
            prefs.edit().putStringSet("active_alarms", alarmIds).apply()
        }
        
        /**
         * Alarm ID'sini sil
         */
        private fun removeAlarmId(context: Context, alarmId: Int) {
            val prefs = context.getSharedPreferences("alarm_ids", Context.MODE_PRIVATE)
            val alarmIds = prefs.getStringSet("active_alarms", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
            alarmIds.remove(alarmId.toString())
            prefs.edit().putStringSet("active_alarms", alarmIds).apply()
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "📢 Alarm alındı: ${intent.action}")
        
        when (intent.action) {
            ACTION_PRAYER_ALARM -> {
                // Wake lock al
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                val wakeLock = powerManager.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                    "HuzurVakti::AlarmWakeLock"
                )
                wakeLock.acquire(60_000L) // 1 dakika
                
                try {
                    val alarmId = intent.getIntExtra(EXTRA_ALARM_ID, 0)
                    val vakitName = intent.getStringExtra(EXTRA_VAKIT_NAME) ?: "Vakit"
                    val vakitTime = intent.getStringExtra(EXTRA_VAKIT_TIME) ?: ""
                    var soundFile = intent.getStringExtra(EXTRA_SOUND_FILE) ?: "ding_dong.mp3"
                    val isEarly = intent.getBooleanExtra(EXTRA_IS_EARLY, false)
                    val earlyMinutes = intent.getIntExtra(EXTRA_EARLY_MINUTES, 0)
                    
                    Log.d(TAG, "🔔 Alarm tetiklendi: $vakitName - Ses: $soundFile")
                    
                    // Ses dosyası yoksa veya varsayılan ding_dong ise SharedPreferences'tan al
                    if (soundFile.isEmpty() || soundFile == "ding_dong" || soundFile == "ding_dong.mp3") {
                        val vakitKey = vakitName.lowercase()
                            .replace("ı", "i").replace("ö", "o").replace("ü", "u")
                            .replace("ş", "s").replace("ğ", "g").replace("ç", "c")
                            .let { name ->
                                when {
                                    name.contains("imsak") || name.contains("sahur") -> "imsak"
                                    name.contains("gunes") -> "gunes"
                                    name.contains("ogle") -> "ogle"
                                    name.contains("ikindi") -> "ikindi"
                                    name.contains("aksam") -> "aksam"
                                    name.contains("yatsi") -> "yatsi"
                                    else -> ""
                                }
                            }
                        
                        if (vakitKey.isNotEmpty()) {
                            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                            val savedSound = prefs.getString("flutter.bildirim_sesi_$vakitKey", null)
                            if (!savedSound.isNullOrEmpty()) {
                                soundFile = savedSound
                                Log.d(TAG, "🔊 onReceive - Ses SharedPreferences'tan alındı: $vakitKey -> $soundFile")
                            }
                        }
                    }
                    
                    Log.d(TAG, "🔔 AlarmService başlatılıyor: $vakitName - $vakitTime (Ses: $soundFile)")
                    
                    // AlarmService'i başlat - ACTION_PRAYER_ALARM set etmeli!
                    val serviceIntent = Intent(context, AlarmService::class.java).apply {
                        action = ACTION_PRAYER_ALARM // ÖNEMLİ: Action set etmeliyiz!
                        putExtra(EXTRA_ALARM_ID, alarmId)
                        putExtra(EXTRA_VAKIT_NAME, vakitName)
                        putExtra(EXTRA_VAKIT_TIME, vakitTime)
                        putExtra(EXTRA_SOUND_FILE, soundFile)
                        putExtra(EXTRA_IS_EARLY, isEarly)
                        putExtra(EXTRA_EARLY_MINUTES, earlyMinutes)
                    }
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                    
                } finally {
                    if (wakeLock.isHeld) {
                        wakeLock.release()
                    }
                }
            }
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "📱 Cihaz yeniden başlatıldı, alarmlar yeniden zamanlanacak")
                // Flutter tarafından tetiklenecek
            }
        }
    }
}
