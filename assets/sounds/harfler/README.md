# Arapça Harf Sesleri - Türk Hoca Kayıtları

Bu klasör, Elif-Ba sayfasında kullanılmak üzere Türk bir hoca tarafından kaydedilmiş Arapça harf seslerini içerir.

## Dosya İsimlendirme

Her harf için şu formatta ses dosyası oluşturun:
- Dosya adı: Arapça harfin kendisi + `.mp3`
- Örnek: `ا.mp3`, `ب.mp3`, `ت.mp3`, vb.

## Gerekli Dosyalar (28 Harf)

1. `ا.mp3` - Elif (Hemze)
2. `ب.mp3` - Be
3. `ت.mp3` - Te
4. `ث.mp3` - Se
5. `ج.mp3` - Cim
6. `ح.mp3` - Ha
7. `خ.mp3` - Hı
8. `د.mp3` - Dal
9. `ذ.mp3` - Zel
10. `ر.mp3` - Re
11. `ز.mp3` - Ze
12. `س.mp3` - Sin
13. `ش.mp3` - Şın
14. `ص.mp3` - Sad
15. `ض.mp3` - Dad
16. `ط.mp3` - Tı
17. `ظ.mp3` - Zı
18. `ع.mp3` - Ayın
19. `غ.mp3` - Ğayın
20. `ف.mp3` - Fe
21. `ق.mp3` - Kaf
22. `ك.mp3` - Kef
23. `ل.mp3` - Lam
24. `م.mp3` - Mim
25. `ن.mp3` - Nun
26. `ه.mp3` - He
27. `و.mp3` - Vav
28. `ي.mp3` - Ye

## Ses Kayıt Önerileri

1. **Format**: MP3 (128kbps veya üzeri)
2. **Süre**: Her kayıt 2-3 saniye olmalı
3. **İçerik**: 
   - Türk hoca tarafından doğru tecvitle okunmalı
   - Sadece harf sesi (izole edilmiş - hareke/sesli harf eklenmeden)
4. **Kalite**: Arka plan gürültüsü olmamalı
5. **Ses Seviyesi**: Normalize edilmiş (-3dB peak)

## Kullanım

Uygulama önce bu klasörde ses dosyasını arar:
- **Dosya varsa**: Türk hoca sesini çalar (3 kez tekrar eder)
- **Dosya yoksa**: Flutter TTS ile Türkçe açıklama okur (yedek sistem)

## Telif Hakları

Ses kayıtları:
- Telif hakkı sorun oluşturmamalı
- Ücretsiz kullanım izni olmalı
- Eğitim amaçlı olarak kullanılacak

## Alternatif Kaynaklar

Ses dosyalarını şu yollarla edinebilirsiniz:
1. Kendi kayıtlarınızı yapın (önerilen)
2. Creative Commons lisanslı kayıtlar kullanın
3. Açık kaynaklı Arapça eğitim projelerinden alın (lisansa dikkat)

## Teknik Notlar

- Dosyalar `pubspec.yaml`'a otomatik dahil edilir (`assets/sounds/` klasörü zaten tanımlı)
- Dosya boyutu kontrolü gerekir (APK boyutunu artırır)
- Her dosya ~50-100 KB olmalı (toplam ~1-3 MB)
