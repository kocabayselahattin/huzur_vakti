import 'package:huzur_vakti/services/diyanet_api_service.dart';
import 'package:huzur_vakti/services/konum_service.dart';

Future<void> main() async {
  final ilceId = await KonumService.getIlceId();
  if (ilceId == null) {
    print('❌ İlçe ID bulunamadı. Ayarlardan il/ilçe seçimi yapın.');
    return;
  }
  print('İlçe ID: $ilceId');
  final vakitler = await DiyanetApiService.getBugunVakitler(ilceId);
  if (vakitler == null) {
    print('❌ Bugünün vakitleri alınamadı. API veya veri sorunu olabilir.');
  } else {
    print('✅ Bugünün vakitleri:');
    vakitler.forEach((k, v) => print('$k: $v'));
  }
}
