import 'package:huzur_vakti/services/diyanet_api_service.dart';
import 'package:huzur_vakti/services/namazvakti_api_service.dart';

Future<void> main() async {
  print('=== API Test Başlıyor ===\n');
  
  // Test için İstanbul Kadıköy (9541)
  const testIlceId = '9541';
  
  print('📍 Test İlçe: İstanbul / Kadıköy (ID: $testIlceId)\n');
  
  // 1. Diyanet API Test
  print('🔹 Diyanet API Test...');
  try {
    final diyanetVakitler = await DiyanetApiService.getBugunVakitler(testIlceId);
    if (diyanetVakitler != null) {
      print('✅ Diyanet API başarılı!');
      print('   İmsak: ${diyanetVakitler['Imsak']}');
      print('   Güneş: ${diyanetVakitler['Gunes']}');
      print('   Öğle: ${diyanetVakitler['Ogle']}');
      print('   İkindi: ${diyanetVakitler['Ikindi']}');
      print('   Akşam: ${diyanetVakitler['Aksam']}');
      print('   Yatsı: ${diyanetVakitler['Yatsi']}');
      print('   Tarih: ${diyanetVakitler['MiladiTarihUzun']}');
      print('   Hicri: ${diyanetVakitler['HicriTarihUzun']}');
    } else {
      print('❌ Diyanet API veri döndürmedi');
    }
  } catch (e) {
    print('❌ Diyanet API hatası: $e');
  }
  
  print('\n🔹 NamazVakti API Test...');
  try {
    final namazvaktiVakitler = await NamazVaktiApiService.getBugunVakitler(testIlceId);
    if (namazvaktiVakitler != null) {
      print('✅ NamazVakti API başarılı!');
      print('   İmsak: ${namazvaktiVakitler['Imsak']}');
      print('   Güneş: ${namazvaktiVakitler['Gunes']}');
      print('   Öğle: ${namazvaktiVakitler['Ogle']}');
      print('   İkindi: ${namazvaktiVakitler['Ikindi']}');
      print('   Akşam: ${namazvaktiVakitler['Aksam']}');
      print('   Yatsı: ${namazvaktiVakitler['Yatsi']}');
    } else {
      print('❌ NamazVakti API veri döndürmedi');
    }
  } catch (e) {
    print('❌ NamazVakti API hatası: $e');
  }
  
  print('\n🔹 Aylık vakitler test...');
  try {
    final aylikVakitler = await DiyanetApiService.getAylikVakitler(
      testIlceId, 
      DateTime.now().year, 
      DateTime.now().month,
    );
    print('✅ Aylık vakitler alındı: ${aylikVakitler.length} gün');
    if (aylikVakitler.isNotEmpty) {
      final ilkGun = aylikVakitler.first;
      print('   İlk gün: ${ilkGun['MiladiTarihKisa']} - İmsak: ${ilkGun['Imsak']}');
      final sonGun = aylikVakitler.last;
      print('   Son gün: ${sonGun['MiladiTarihKisa']} - İmsak: ${sonGun['Imsak']}');
    }
  } catch (e) {
    print('❌ Aylık vakitler hatası: $e');
  }
  
  print('\n=== Test Tamamlandı ===');
}
