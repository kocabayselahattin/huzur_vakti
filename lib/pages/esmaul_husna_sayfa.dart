import 'package:flutter/material.dart';
import '../services/tema_service.dart';

class EsmaulHusnaSayfa extends StatefulWidget {
  const EsmaulHusnaSayfa({super.key});

  @override
  State<EsmaulHusnaSayfa> createState() => _EsmaulHusnaSayfaState();
}

class _EsmaulHusnaSayfaState extends State<EsmaulHusnaSayfa> {
  final TemaService _temaService = TemaService();

  static const List<Map<String, String>> _esmaulHusna = [
    {'arapca': 'الله', 'turkce': 'Allah', 'anlam': 'Bütün isimlerin vasıflarını içine alan öz adı'},
    {'arapca': 'الرَّحْمَنُ', 'turkce': 'Er-Rahman', 'anlam': 'Dünyada bütün mahlûkata merhamet eden, şefkat gösteren'},
    {'arapca': 'الرَّحِيمُ', 'turkce': 'Er-Rahim', 'anlam': 'Ahirette, müminlere sonsuz merhamet eden'},
    {'arapca': 'الْمَلِكُ', 'turkce': 'El-Melik', 'anlam': 'Mülkün gerçek sahibi, bütün kâinatın hükümdarı'},
    {'arapca': 'الْقُدُّوسُ', 'turkce': 'El-Kuddüs', 'anlam': 'Her türlü eksiklik ve ayıptan münezzeh olan'},
    {'arapca': 'السَّلامُ', 'turkce': 'Es-Selam', 'anlam': 'Her türlü tehlikelerden selamete çıkaran'},
    {'arapca': 'الْمُؤْمِنُ', 'turkce': 'El-Mümin', 'anlam': 'Güven veren, emin kılan, koruyan'},
    {'arapca': 'الْمُهَيْمِنُ', 'turkce': 'El-Müheymin', 'anlam': 'Koruyup gözeten, her şeye şahit olan'},
    {'arapca': 'الْعَزِيزُ', 'turkce': 'El-Aziz', 'anlam': 'Sonsuz izzet sahibi, mağlup edilemeyen'},
    {'arapca': 'الْجَبَّارُ', 'turkce': 'El-Cebbar', 'anlam': 'İstediğini zorla yaptıran, ulaşılmaz'},
    {'arapca': 'الْمُتَكَبِّرُ', 'turkce': 'El-Mütekebbir', 'anlam': 'Büyüklükte eşi benzeri olmayan'},
    {'arapca': 'الْخَالِقُ', 'turkce': 'El-Hâlık', 'anlam': 'Yaratan, yoktan var eden'},
    {'arapca': 'الْبَارِئُ', 'turkce': 'El-Bâri', 'anlam': 'Her şeyi kusursuzca yaratan'},
    {'arapca': 'الْمُصَوِّرُ', 'turkce': 'El-Musavvir', 'anlam': 'Şekil veren, tasvir eden'},
    {'arapca': 'الْغَفَّارُ', 'turkce': 'El-Gaffar', 'anlam': 'Günahları çok bağışlayan'},
    {'arapca': 'الْقَهَّارُ', 'turkce': 'El-Kahhar', 'anlam': 'Her şeye galip gelen'},
    {'arapca': 'الْوَهَّابُ', 'turkce': 'El-Vehhab', 'anlam': 'Karşılıksız çok hediye eden'},
    {'arapca': 'الرَّزَّاقُ', 'turkce': 'Er-Rezzak', 'anlam': 'Bütün canlıların rızkını veren'},
    {'arapca': 'الْفَتَّاحُ', 'turkce': 'El-Fettah', 'anlam': 'Her türlü güçlüğü açan, kolaylaştıran'},
    {'arapca': 'الْعَلِيمُ', 'turkce': 'El-Alîm', 'anlam': 'Her şeyi en ince ayrıntısına kadar bilen'},
    {'arapca': 'الْقَابِضُ', 'turkce': 'El-Kâbıd', 'anlam': 'Rızkı tutan, daraltan'},
    {'arapca': 'الْبَاسِطُ', 'turkce': 'El-Bâsıt', 'anlam': 'Rızkı açan, genişleten'},
    {'arapca': 'الْخَافِضُ', 'turkce': 'El-Hâfıd', 'anlam': 'Dereceleri alçaltan'},
    {'arapca': 'الرَّافِعُ', 'turkce': 'Er-Râfi', 'anlam': 'Dereceleri yükselten'},
    {'arapca': 'الْمُعِزُّ', 'turkce': 'El-Muizz', 'anlam': 'İzzet ve şeref veren'},
    {'arapca': 'الْمُذِلُّ', 'turkce': 'El-Müzill', 'anlam': 'Alçaltan, zelil kılan'},
    {'arapca': 'السَّمِيعُ', 'turkce': 'Es-Semi', 'anlam': 'Her şeyi işiten'},
    {'arapca': 'الْبَصِيرُ', 'turkce': 'El-Basîr', 'anlam': 'Her şeyi gören'},
    {'arapca': 'الْحَكَمُ', 'turkce': 'El-Hakem', 'anlam': 'Hüküm veren, hâkimlerin hâkimi'},
    {'arapca': 'الْعَدْلُ', 'turkce': 'El-Adl', 'anlam': 'Mutlak adalet sahibi'},
    {'arapca': 'اللَّطِيفُ', 'turkce': 'El-Latîf', 'anlam': 'Lütuf sahibi, nazik davranan'},
    {'arapca': 'الْخَبِيرُ', 'turkce': 'El-Habîr', 'anlam': 'Her şeyden haberdar olan'},
    {'arapca': 'الْحَلِيمُ', 'turkce': 'El-Halîm', 'anlam': 'Çok yumuşak davranan, hilim sahibi'},
    {'arapca': 'الْعَظِيمُ', 'turkce': 'El-Azîm', 'anlam': 'Büyüklükte sonsuz olan'},
    {'arapca': 'الْغَفُورُ', 'turkce': 'El-Gafûr', 'anlam': 'Çok bağışlayan'},
    {'arapca': 'الشَّكُورُ', 'turkce': 'Eş-Şekûr', 'anlam': 'Az iyiliğe çok mükâfat veren'},
    {'arapca': 'الْعَلِيُّ', 'turkce': 'El-Aliyy', 'anlam': 'Yüceliğin sahibi'},
    {'arapca': 'الْكَبِيرُ', 'turkce': 'El-Kebîr', 'anlam': 'Büyüklükte sınırsız olan'},
    {'arapca': 'الْحَفِيظُ', 'turkce': 'El-Hafîz', 'anlam': 'Her şeyi koruyup gözeten'},
    {'arapca': 'الْمُقِيتُ', 'turkce': 'El-Mukît', 'anlam': 'Bedenlerin ve ruhların gıdasını veren'},
    {'arapca': 'الْحَسِيبُ', 'turkce': 'El-Hasîb', 'anlam': 'Hesap soran, hesaba çeken'},
    {'arapca': 'الْجَلِيلُ', 'turkce': 'El-Celîl', 'anlam': 'Celâlet ve azamet sahibi'},
    {'arapca': 'الْكَرِيمُ', 'turkce': 'El-Kerîm', 'anlam': 'Sonsuz kerem sahibi'},
    {'arapca': 'الرَّقِيبُ', 'turkce': 'Er-Rakîb', 'anlam': 'Her şeyi gözetleyen'},
    {'arapca': 'الْمُجِيبُ', 'turkce': 'El-Mücîb', 'anlam': 'Duaları kabul eden'},
    {'arapca': 'الْوَاسِعُ', 'turkce': 'El-Vâsi', 'anlam': 'İlmi ve merhameti sınırsız olan'},
    {'arapca': 'الْحَكِيمُ', 'turkce': 'El-Hakîm', 'anlam': 'Her işi hikmetli olan'},
    {'arapca': 'الْوَدُودُ', 'turkce': 'El-Vedûd', 'anlam': 'Çok seven, çok sevilen'},
    {'arapca': 'الْمَجِيدُ', 'turkce': 'El-Mecîd', 'anlam': 'Şanı çok yüce olan'},
    {'arapca': 'الْبَاعِثُ', 'turkce': 'El-Bâis', 'anlam': 'Ölüleri dirilten'},
    {'arapca': 'الشَّهِيدُ', 'turkce': 'Eş-Şehîd', 'anlam': 'Her yerde hazır ve nazır olan'},
    {'arapca': 'الْحَقُّ', 'turkce': 'El-Hakk', 'anlam': 'Varlığı gerçek olan'},
    {'arapca': 'الْوَكِيلُ', 'turkce': 'El-Vekîl', 'anlam': 'Güvenilip dayanılan'},
    {'arapca': 'الْقَوِيُّ', 'turkce': 'El-Kaviyy', 'anlam': 'Sonsuz güç sahibi'},
    {'arapca': 'الْمَتِينُ', 'turkce': 'El-Metîn', 'anlam': 'Çok sağlam, pek güçlü'},
    {'arapca': 'الْوَلِيُّ', 'turkce': 'El-Veliyy', 'anlam': 'Müminlerin dostu'},
    {'arapca': 'الْحَمِيدُ', 'turkce': 'El-Hamîd', 'anlam': 'Övgüye lâyık olan'},
    {'arapca': 'الْمُحْصِي', 'turkce': 'El-Muhsî', 'anlam': 'Her şeyi sayan'},
    {'arapca': 'الْمُبْدِئُ', 'turkce': 'El-Mübdi', 'anlam': 'İlk yaratan'},
    {'arapca': 'الْمُعِيدُ', 'turkce': 'El-Muîd', 'anlam': 'Tekrar yaratan'},
    {'arapca': 'الْمُحْيِي', 'turkce': 'El-Muhyî', 'anlam': 'Hayat veren'},
    {'arapca': 'الْمُمِيتُ', 'turkce': 'El-Mümît', 'anlam': 'Ölümü yaratan'},
    {'arapca': 'الْحَيُّ', 'turkce': 'El-Hayy', 'anlam': 'Diri, her şeyi bilen ve her şeye gücü yeten'},
    {'arapca': 'الْقَيُّومُ', 'turkce': 'El-Kayyûm', 'anlam': 'Her şeyi ayakta tutan'},
    {'arapca': 'الْوَاجِدُ', 'turkce': 'El-Vâcid', 'anlam': 'İstediğini, istediği anda bulan'},
    {'arapca': 'الْمَاجِدُ', 'turkce': 'El-Mâcid', 'anlam': 'Şerefi ve keremi sonsuz olan'},
    {'arapca': 'الْوَاحِدُ', 'turkce': 'El-Vâhid', 'anlam': 'Tek olan, ortağı olmayan'},
    {'arapca': 'الصَّمَدُ', 'turkce': 'Es-Samed', 'anlam': 'Hiçbir şeye muhtaç olmayan'},
    {'arapca': 'الْقَادِرُ', 'turkce': 'El-Kâdir', 'anlam': 'Her şeye gücü yeten'},
    {'arapca': 'الْمُقْتَدِرُ', 'turkce': 'El-Muktedir', 'anlam': 'Kudret sahibi'},
    {'arapca': 'الْمُقَدِّمُ', 'turkce': 'El-Mukaddim', 'anlam': 'Öne alan'},
    {'arapca': 'الْمُؤَخِّرُ', 'turkce': 'El-Muahhir', 'anlam': 'Geriye bırakan'},
    {'arapca': 'الأَوَّلُ', 'turkce': 'El-Evvel', 'anlam': 'Varlığının başlangıcı olmayan'},
    {'arapca': 'الآخِرُ', 'turkce': 'El-Âhir', 'anlam': 'Varlığının sonu olmayan'},
    {'arapca': 'الظَّاهِرُ', 'turkce': 'Ez-Zâhir', 'anlam': 'Varlığı açık olan'},
    {'arapca': 'الْبَاطِنُ', 'turkce': 'El-Bâtın', 'anlam': 'Gizli olan'},
    {'arapca': 'الْوَالِي', 'turkce': 'El-Vâlî', 'anlam': 'Her şeyi yöneten'},
    {'arapca': 'الْمُتَعَالِي', 'turkce': 'El-Müteâlî', 'anlam': 'Yüce olan'},
    {'arapca': 'الْبَرُّ', 'turkce': 'El-Berr', 'anlam': 'İyilik ve ihsan sahibi'},
    {'arapca': 'التَّوَّابُ', 'turkce': 'Et-Tevvâb', 'anlam': 'Tevbeleri kabul eden'},
    {'arapca': 'الْمُنْتَقِمُ', 'turkce': 'El-Müntekim', 'anlam': 'İntikam alan'},
    {'arapca': 'الْعَفُوُّ', 'turkce': 'El-Afüvv', 'anlam': 'Affeden'},
    {'arapca': 'الرَّءُوفُ', 'turkce': 'Er-Raûf', 'anlam': 'Çok şefkatli'},
    {'arapca': 'مَالِكُ الْمُلْكِ', 'turkce': 'Mâlikül-Mülk', 'anlam': 'Mülkün sahibi'},
    {'arapca': 'ذُو الْجَلالِ وَالإكْرَامِ', 'turkce': 'Zülcelâli vel-İkrâm', 'anlam': 'Celâl ve ikram sahibi'},
    {'arapca': 'الْمُقْسِطُ', 'turkce': 'El-Muksit', 'anlam': 'Adaletle hükmeden'},
    {'arapca': 'الْجَامِعُ', 'turkce': 'El-Câmi', 'anlam': 'Toplayıcı'},
    {'arapca': 'الْغَنِيُّ', 'turkce': 'El-Ganiyy', 'anlam': 'Hiçbir şeye muhtaç olmayan'},
    {'arapca': 'الْمُغْنِي', 'turkce': 'El-Muğnî', 'anlam': 'Zengin kılan'},
    {'arapca': 'الْمَانِعُ', 'turkce': 'El-Mâni', 'anlam': 'Engelleyen'},
    {'arapca': 'الضَّارُّ', 'turkce': 'Ed-Dârr', 'anlam': 'Zarar veren'},
    {'arapca': 'النَّافِعُ', 'turkce': 'En-Nâfi', 'anlam': 'Fayda veren'},
    {'arapca': 'النُّورُ', 'turkce': 'En-Nûr', 'anlam': 'Nur'},
    {'arapca': 'الْهَادِي', 'turkce': 'El-Hâdî', 'anlam': 'Doğru yola ileten'},
    {'arapca': 'الْبَدِيعُ', 'turkce': 'El-Bedî', 'anlam': 'Eşsiz yaratan'},
    {'arapca': 'الْبَاقِي', 'turkce': 'El-Bâkî', 'anlam': 'Ebedî olan'},
    {'arapca': 'الْوَارِثُ', 'turkce': 'El-Vâris', 'anlam': 'Mirasçı'},
    {'arapca': 'الرَّشِيدُ', 'turkce': 'Er-Reşîd', 'anlam': 'Doğru yolu gösteren'},
    {'arapca': 'الصَّبُورُ', 'turkce': 'Es-Sabûr', 'anlam': 'Sabırlı olan'},
  ];

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: const Text('Esmaül Hüsna'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: renkler.arkaPlanGradient != null
            ? BoxDecoration(gradient: renkler.arkaPlanGradient)
            : null,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: 99,
          itemBuilder: (context, index) {
            final esma = _esmaulHusna[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    renkler.kartArkaPlan,
                    renkler.kartArkaPlan.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: renkler.ayirac),
                boxShadow: [
                  BoxShadow(
                    color: renkler.vurgu.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Numara
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: renkler.vurgu.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: renkler.vurgu,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Arapça
                  Text(
                    esma['arapca']!,
                    style: TextStyle(
                      color: renkler.yaziPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Türkçe
                  Text(
                    esma['turkce']!,
                    style: TextStyle(
                      color: renkler.vurgu,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Anlam
                  Expanded(
                    child: Text(
                      esma['anlam']!,
                      style: TextStyle(
                        color: renkler.yaziSecondary,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
