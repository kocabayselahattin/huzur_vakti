package com.huzura.davet

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log

/**
 * Bildirimlerin büyük ikonunu hazırlar.
 *
 * Launcher ikonu tam çözünürlükte (xxxhdpi'de 512x512'ye kadar) açıldığında
 * bildirim başına megabaytlarca bellek harcanır; oysa sistem ikonu yaklaşık
 * 64dp'ye küçültür. Bu yüzden ikon, hedef boyuta göre alt örneklenerek
 * (inSampleSize) yüklenir.
 */
object BildirimIkonu {

    /** Aynı ikon her bildirimde yeniden çözülmesin diye tutulur. */
    @Volatile
    private var onbellek: Bitmap? = null

    fun buyukIkon(context: Context): Bitmap? {
        onbellek?.let { if (!it.isRecycled) return it }

        return try {
            val kaynaklar = context.applicationContext.resources
            val hedef = kaynaklar.getDimensionPixelSize(
                android.R.dimen.notification_large_icon_width,
            ).coerceAtLeast(1)

            // Önce yalnızca boyutu oku; bitmap belleğe alınmaz.
            val olcum = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeResource(kaynaklar, R.mipmap.ic_launcher, olcum)

            val secenekler = BitmapFactory.Options().apply {
                inSampleSize = ornekOrani(olcum.outWidth, olcum.outHeight, hedef)
            }
            BitmapFactory.decodeResource(kaynaklar, R.mipmap.ic_launcher, secenekler)
                ?.also { onbellek = it }
        } catch (e: Exception) {
            // İkon üretilemezse bildirim büyük ikon olmadan gösterilir.
            Log.w("BildirimIkonu", "Bildirim ikonu hazırlanamadı: ${e.message}")
            null
        }
    }

    /**
     * Görüntüyü hedef boyutun altına düşürmeden küçülten en büyük 2'nin kuvvetini
     * döndürür. Boyut okunamadıysa (0) alt örnekleme yapılmaz.
     */
    private fun ornekOrani(genislik: Int, yukseklik: Int, hedef: Int): Int {
        if (genislik <= 0 || yukseklik <= 0) return 1
        var oran = 1
        while (genislik / (oran * 2) >= hedef && yukseklik / (oran * 2) >= hedef) {
            oran *= 2
        }
        return oran
    }
}
