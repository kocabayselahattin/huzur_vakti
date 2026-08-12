package com.huzura.davet.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.icu.util.IslamicCalendar
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import com.huzura.davet.MainActivity
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

object WidgetUtils {
    
    // Vakit isimleri sırası
    private val vakitSirasi = listOf("Imsak", "Gunes", "Ogle", "Ikindi", "Aksam", "Yatsi")
    
    // Varsayılan Hicri ay isimleri (çeviri yoksa kullanılır)
    private val defaultHicriAylar = listOf(
        "Muharrem", "Safer", "Rebiülevvel", "Rebiülahir",
        "Cemaziyelevvel", "Cemaziyelahir", "Recep", "Şaban",
        "Ramazan", "Şevval", "Zilkade", "Zilhicce"
    )

    /**
     * Hicri tarihi Android'in yerel IslamicCalendar'ı ile hesaplar.
     * Flutter'ın hijri_day_shift değerini SharedPreferences'tan okuyarak
     * Diyanet takvimiyle senkronize kalır.
     *
     * @return "gün AyAdı yıl" formatında Hicri tarih (ör. "5 Şaban 1447")
     */
    fun getHicriTarih(context: Context): String {
        try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val dayShift = widgetData.getInt("hijri_day_shift", 0)
            
            // Bugünün tarihini shift uygulayarak al
            val cal = Calendar.getInstance()
            cal.add(Calendar.DAY_OF_YEAR, dayShift)
            
            // IslamicCalendar (Umm al-Qura) ile Hicri tarihe çevir
            val islamicCal = IslamicCalendar(cal.time)
            islamicCal.calculationType = IslamicCalendar.CalculationType.ISLAMIC_UMALQURA
            // Re-set the time after changing calculation type
            islamicCal.time = cal.time
            
            val hDay = islamicCal.get(Calendar.DAY_OF_MONTH)
            val hMonth = islamicCal.get(Calendar.MONTH) // 0-based
            val hYear = islamicCal.get(Calendar.YEAR)
            
            // Ay ismini çevirilerden al (1-indexed key: hijri_month_1 .. hijri_month_12)
            val monthIndex = hMonth + 1
            val ayAdi = widgetData.getString("hijri_month_$monthIndex", null)
                ?: defaultHicriAylar.getOrElse(hMonth) { "" }
            
            return "$hDay $ayAdi $hYear"
        } catch (e: Exception) {
            // Hata durumunda Flutter'ın kaydettiği değeri kullan
            val widgetData = HomeWidgetPlugin.getData(context)
            return widgetData.getString("hicri_tarih", "") ?: ""
        }
    }

    /**
     * Miladi (Gregoryen) tarihi cihazın güncel sistem tarihinden hesaplar.
     * Hicri tarihte olduğu gibi, uygulama kapalıyken (gece yarısı geçişi dahil)
     * de her zaman güncel kalması için native olarak hesaplanır.
     *
     * @return "gün Ay yıl" formatında kısa miladi tarih (ör. "12 Ağu 2026")
     */
    fun getMiladiTarih(context: Context): String {
        return try {
            val widgetData = HomeWidgetPlugin.getData(context)
            val dilKodu = widgetData.getString("app_dil", "tr") ?: "tr"
            val locale = when (dilKodu) {
                "en" -> Locale("en", "US")
                "de" -> Locale("de", "DE")
                "fr" -> Locale("fr", "FR")
                "ar" -> Locale("ar", "SA")
                "fa" -> Locale("fa", "IR")
                else -> Locale("tr", "TR")
            }
            val sdf = SimpleDateFormat("d MMM yyyy", locale)
            sdf.format(Calendar.getInstance().time)
        } catch (e: Exception) {
            // Hata durumunda Flutter'ın kaydettiği değeri kullan
            val widgetData = HomeWidgetPlugin.getData(context)
            widgetData.getString("miladi_tarih", "") ?: ""
        }
    }

    /**
     * Natively hesaplanan vakit anahtarını (ör. "Imsak") çevirilmiş isme çevirir.
     * Flutter label_imsak, label_gunes vb. olarak kaydettiği çevirileri kullanır.
     */
    fun getTranslatedVakitAdi(widgetData: SharedPreferences, nativeKey: String): String {
        val labelKey = when (nativeKey) {
            "Imsak", "İmsak" -> "label_imsak"
            "Gunes", "Güneş" -> "label_gunes"
            "Ogle", "Öğle" -> "label_ogle"
            "Ikindi", "İkindi" -> "label_ikindi"
            "Aksam", "Akşam" -> "label_aksam"
            "Yatsi", "Yatsı" -> "label_yatsi"
            else -> null
        }
        if (labelKey != null) {
            val translated = widgetData.getString(labelKey, null)
            if (!translated.isNullOrBlank()) return translated
        }
        // Türkçe fallback
        return when (nativeKey) {
            "Imsak" -> "İmsak"
            "Gunes" -> "Güneş"
            "Ogle" -> "Öğle"
            "Ikindi" -> "İkindi"
            "Aksam" -> "Akşam"
            "Yatsi" -> "Yatsı"
            else -> nativeKey
        }
    }
    
    /**
     * Vakit saatlerinden geri sayım hesapla
     * @return Map içinde: sonrakiVakit, sonrakiSaat, mevcutVakit, mevcutSaat, geriSayim, ilerleme
     */
    fun hesaplaVakitBilgisi(
        imsak: String,
        gunes: String,
        ogle: String,
        ikindi: String,
        aksam: String,
        yatsi: String
    ): Map<String, String> {
        val now = Calendar.getInstance()
        val sdf = SimpleDateFormat("HH:mm", Locale.getDefault())
        
        val vakitler = mapOf(
            "Imsak" to imsak,
            "Gunes" to gunes,
            "Ogle" to ogle,
            "Ikindi" to ikindi,
            "Aksam" to aksam,
            "Yatsi" to yatsi
        )
        
        // Her vakit için Calendar objesi oluştur
        val vakitCalendars = vakitler.map { (isim, saat) ->
            val parts = saat.split(":")
            val cal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, parts.getOrNull(0)?.toIntOrNull() ?: 0)
                set(Calendar.MINUTE, parts.getOrNull(1)?.toIntOrNull() ?: 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            isim to cal
        }
        
        // Sonraki vakti bul
        var sonrakiVakitIndex = -1
        for (i in vakitSirasi.indices) {
            val vakitAdi = vakitSirasi[i]
            val vakitCal = vakitCalendars.find { it.first == vakitAdi }?.second ?: continue
            if (now.before(vakitCal)) {
                sonrakiVakitIndex = i
                break
            }
        }
        
        // Eğer tüm vakitler geçtiyse, yarının imsak vakti
        val sonrakiVakit: String
        val sonrakiSaat: String
        val mevcutVakit: String
        val mevcutSaat: String
        val sonrakiVakitCal: Calendar
        val mevcutVakitCal: Calendar
        
        if (sonrakiVakitIndex == -1) {
            // Gece yarısından sonra, yarının imsak vaktine kadar
            sonrakiVakit = "Imsak"
            sonrakiSaat = imsak
            mevcutVakit = "Yatsı"
            mevcutSaat = yatsi
            
            sonrakiVakitCal = Calendar.getInstance().apply {
                val parts = imsak.split(":")
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, parts.getOrNull(0)?.toIntOrNull() ?: 5)
                set(Calendar.MINUTE, parts.getOrNull(1)?.toIntOrNull() ?: 30)
                set(Calendar.SECOND, 0)
            }
            mevcutVakitCal = vakitCalendars.find { it.first == "Yatsi" }?.second ?: now
        } else if (sonrakiVakitIndex == 0) {
            // İmsak'tan önce (gece)
            sonrakiVakit = "Imsak"
            sonrakiSaat = imsak
            mevcutVakit = "Yatsı"
            mevcutSaat = yatsi
            
            sonrakiVakitCal = vakitCalendars.find { it.first == "Imsak" }?.second ?: now
            mevcutVakitCal = Calendar.getInstance().apply {
                val parts = yatsi.split(":")
                add(Calendar.DAY_OF_YEAR, -1)
                set(Calendar.HOUR_OF_DAY, parts.getOrNull(0)?.toIntOrNull() ?: 19)
                set(Calendar.MINUTE, parts.getOrNull(1)?.toIntOrNull() ?: 30)
                set(Calendar.SECOND, 0)
            }
        } else {
            sonrakiVakit = vakitSirasi[sonrakiVakitIndex]
            sonrakiSaat = vakitler[sonrakiVakit] ?: ""
            mevcutVakit = vakitSirasi[sonrakiVakitIndex - 1]
            mevcutSaat = vakitler[mevcutVakit] ?: ""
            
            sonrakiVakitCal = vakitCalendars.find { it.first == sonrakiVakit }?.second ?: now
            mevcutVakitCal = vakitCalendars.find { it.first == mevcutVakit }?.second ?: now
        }
        
        // Geri sayım hesapla (saniye YOK - widget'lar her 30sn güncellenir)
        val kalanMs = sonrakiVakitCal.timeInMillis - now.timeInMillis
        val kalanSaat = (kalanMs / (1000 * 60 * 60)).toInt()
        val kalanDakika = ((kalanMs / (1000 * 60)) % 60).toInt()
        
        // "Xs Ydk" formatı (saniye yok - widget güncelleme sıklığına uygun)
        val geriSayim = if (kalanSaat > 0) {
            "${kalanSaat}s ${kalanDakika}dk"
        } else {
            "${kalanDakika} dk"
        }
        
        // İlerleme hesapla
        val toplamMs = sonrakiVakitCal.timeInMillis - mevcutVakitCal.timeInMillis
        val gecenMs = now.timeInMillis - mevcutVakitCal.timeInMillis
        val ilerleme = if (toplamMs > 0) ((gecenMs.toDouble() / toplamMs) * 100).toInt().coerceIn(0, 100) else 0
        
        // Vakit isimlerini Türkçeleştir
        val sonrakiVakitTr = when (sonrakiVakit) {
            "Imsak" -> "İmsak"
            "Gunes" -> "Güneş"
            "Ogle" -> "Öğle"
            "Ikindi" -> "İkindi"
            "Aksam" -> "Akşam"
            "Yatsi" -> "Yatsı"
            else -> sonrakiVakit
        }
        
        val mevcutVakitTr = when (mevcutVakit) {
            "Imsak" -> "İmsak"
            "Gunes" -> "Güneş"
            "Ogle" -> "Öğle"
            "Ikindi" -> "İkindi"
            "Aksam" -> "Akşam"
            "Yatsi" -> "Yatsı"
            else -> mevcutVakit
        }
        
        return mapOf(
            "sonrakiVakit" to sonrakiVakitTr,
            "sonrakiSaat" to sonrakiSaat,
            "mevcutVakit" to mevcutVakitTr,
            "mevcutSaat" to mevcutSaat,
            "geriSayim" to geriSayim,
            "ilerleme" to ilerleme.toString()
        )
    }
    
    fun parseColorSafe(hex: String?, defaultColor: Int): Int {
        if (hex.isNullOrBlank()) {
            return defaultColor
        }
        val cleaned = hex.trim()
            .removePrefix("#")
            .removePrefix("0x")
            .removePrefix("0X")

        if (cleaned.length != 6 && cleaned.length != 8) {
            return defaultColor
        }

        return try {
            Color.parseColor("#$cleaned")
        } catch (_: IllegalArgumentException) {
            defaultColor
        }
    }

    fun createLaunchPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun applyCountdown(views: RemoteViews, viewId: Int, remaining: String) {
        // Chronometer widget update'lerinde sürekli reset oluyor
        // Basit TextView kullan - her 5 saniyede güncellenir
        views.setTextViewText(viewId, remaining)
    }

    fun applyFontStyle(views: RemoteViews, styleRes: Int, vararg viewIds: Int) {
        for (viewId in viewIds) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    views.setInt(viewId, "setTextAppearance", styleRes)
                }
            } catch (_: Throwable) {
                // Ignore font styling failures to avoid widget inflate errors.
            }
        }
    }
}
