import 'package:shared_preferences/shared_preferences.dart';

class KonumService {
  static const String _ilKey = 'selected_il';
  static const String _ilIdKey = 'selected_il_id';
  static const String _ilceKey = 'selected_ilce';
  static const String _ilceIdKey = 'selected_ilce_id';

  // Seçilen il bilgisini kaydet
  static Future<void> setIl(String ilAdi, String ilId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ilKey, ilAdi);
    await prefs.setString(_ilIdKey, ilId);
  }

  // Seçilen ilçe bilgisini kaydet
  static Future<void> setIlce(String ilceAdi, String ilceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ilceKey, ilceAdi);
    await prefs.setString(_ilceIdKey, ilceId);
  }

  // Kaydedilen il adını getir
  static Future<String?> getIl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ilKey);
  }

  // Kaydedilen il ID'sini getir
  static Future<String?> getIlId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ilIdKey);
  }

  // Kaydedilen ilçe adını getir
  static Future<String?> getIlce() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ilceKey);
  }

  // Kaydedilen ilçe ID'sini getir
  static Future<String?> getIlceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ilceIdKey);
  }
  
  // İlçe ID'sinin geçerli olup olmadığını kontrol et
  // Bazı eski ilçe ID'leri API'de çalışmıyor (örn: 1219, 1823, 1421 vb.)
  static Future<bool> isIlceIdValid(String? ilceId) async {
    if (ilceId == null || ilceId.isEmpty) return false;
    
    // Bilinen geçersiz ID'ler (eski lokal veri ID'leri, API'de 500/400 hatası veren)
    const invalidIds = [
      '1219', '1823', '1020', '1003', '1421', // Eski sistem ID'leri
      '1200', '1201', '1202', '1203', '1204', '1205', // Diğer eski ID'ler
    ];
    if (invalidIds.contains(ilceId)) {
      return false;
    }
    
    // Geçerli ID'ler genelde 9000-18000 aralığında (yeni sistem)
    try {
      final idNum = int.parse(ilceId);
      if (idNum < 9000 || idNum > 20000) {
        return false;
      }
    } catch (e) {
      return false;
    }
    
    return true;
  }
  
  // Geçersiz konum varsa temizle
  static Future<bool> validateAndClearIfInvalid() async {
    final ilceId = await getIlceId();
    final isValid = await isIlceIdValid(ilceId);
    
    if (!isValid && ilceId != null) {
      print('⚠️ Geçersiz ilçe ID tespit edildi: $ilceId - Temizleniyor...');
      await clearKonum();
      return false;
    }
    
    return isValid;
  }

  // Tüm konum bilgilerini temizle
  static Future<void> clearKonum() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ilKey);
    await prefs.remove(_ilIdKey);
    await prefs.remove(_ilceKey);
    await prefs.remove(_ilceIdKey);
  }
}
