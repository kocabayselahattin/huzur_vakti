package com.huzura.davet.alarm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.huzura.davet.MainActivity
import com.huzura.davet.BildirimIkonu
import com.huzura.davet.R

/**
 * Özel gün/gece bildirimleri için BroadcastReceiver
 * Uygulama kapalı olsa bile çalışır
 */
class OzelGunReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "OzelGunReceiver"
        const val ACTION_OZEL_GUN_ALARM = "com.huzura.davet.OZEL_GUN_ALARM"
        const val CHANNEL_ID = "ozel_gunler_channel"
        const val NOTIFICATION_ID_BASE = 5000
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "📢 Özel gün alarmı alındı: ${intent.action}")
        
        if (intent.action == ACTION_OZEL_GUN_ALARM) {
            // Wake lock al
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "HuzurVakti::OzelGunWakeLock"
            )
            wakeLock.acquire(30_000L) // 30 saniye
            
            try {
                val alarmId = intent.getIntExtra("alarm_id", 0)
                val title = intent.getStringExtra("title") ?: "Özel Gün"
                val body = intent.getStringExtra("body") ?: ""
                
                Log.d(TAG, "🕌 Özel gün bildirimi gösteriliyor: $title")
                
                // Bildirim göster
                showOzelGunNotification(context, alarmId, title, body)
                
            } finally {
                if (wakeLock.isHeld) {
                    wakeLock.release()
                }
            }
        }
    }
    
    private fun showOzelGunNotification(context: Context, notificationId: Int, title: String, body: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // ÖNEMLİ: Telefon sessiz modda mı kontrol et
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val ringerMode = audioManager.ringerMode
        val isPhoneSilent = (ringerMode == AudioManager.RINGER_MODE_SILENT || 
                            ringerMode == AudioManager.RINGER_MODE_VIBRATE)
        
        Log.d(TAG, "📱 Telefon modu: $ringerMode, Sessiz: $isPhoneSilent")
        
        // Notification channel oluştur (Android 8.0+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Eski kanalı sil ve yeniden oluştur
            try {
                notificationManager.deleteNotificationChannel(CHANNEL_ID)
            } catch (e: Exception) {
                Log.d(TAG, "⚠️ Channel silinirken hata: ${e.message}")
            }
            
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Özel Günler",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Kandiller, bayramlar ve mübarek geceler"
                enableVibration(true)
                enableLights(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                setSound(null, null) // Ses MediaPlayer ile çalınacak, kanal sessiz
            }
            notificationManager.createNotificationChannel(channel)
        }
        
        // Ana uygulamayı açacak intent
        val mainIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mainPendingIntent = PendingIntent.getActivity(
            context, notificationId, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Bildirim oluştur - kullanıcı kaydırarak silebilir ama otomatik silinmez
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_EVENT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(mainPendingIntent)
            .setAutoCancel(false) // Tıklayınca silinmesin
            .setOngoing(false)   // Kaydırılarak silinebilsin
            .setLargeIcon(BildirimIkonu.buyukIkon(context))
            .build()
        
        notificationManager.notify(notificationId, notification)
        Log.d(TAG, "✅ Özel gün bildirimi gösterildi: $title (ID: $notificationId)")
        
        // Ses çal - telefon sessiz modda değilse
        if (!isPhoneSilent) {
            playDefaultNotificationSound(context)
        } else {
            Log.d(TAG, "🔇 Telefon sessiz modda - ses çalınmıyor, titreşim yapılıyor")
            doVibration(context)
        }
    }
    
    /**
     * Varsayılan bildirim sesini çal
     */
    private fun playDefaultNotificationSound(context: Context) {
        try {
            val resId = context.resources.getIdentifier("ding_dong", "raw", context.packageName)
            if (resId != 0) {
                val mediaPlayer = android.media.MediaPlayer()
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                mediaPlayer.setAudioAttributes(audioAttributes)
                
                val afd = context.resources.openRawResourceFd(resId)
                try {
                    mediaPlayer.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    mediaPlayer.prepare()
                } finally {
                    afd.close()
                }
                
                mediaPlayer.isLooping = false
                mediaPlayer.setOnCompletionListener { it.release() }
                mediaPlayer.start()
                Log.d(TAG, "🔊 Özel gün bildirimi sesi çalındı")
            } else {
                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                val ringtone = RingtoneManager.getRingtone(context, uri)
                ringtone?.play()
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Ses çalma hatası: ${e.message}")
        }
    }
    
    /**
     * Titreşim yap
     */
    private fun doVibration(context: Context) {
        try {
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }
            
            val pattern = longArrayOf(0, 300, 200, 300, 200, 300)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(pattern, -1)
            }
            Log.d(TAG, "📳 Titreşim yapıldı")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Titreşim hatası: ${e.message}")
        }
    }
}
