import 'package:flutter/material.dart';
import '../services/tema_service.dart';

class IbadetSayfa extends StatelessWidget {
  const IbadetSayfa({super.key});

  static final List<_IbadetContent> _icerikler = [
    _IbadetContent(
      title: 'Namaz',
      subtitle: 'Farzlar, temel sıra ve kısa özet',
      sections: [
        _IbadetSection(
          title: 'Özet',
          items: [
            'Namaz, günün belirli vakitlerinde Allah’a kulluğun temel ifadesidir.',
            'Niyetle başlar, kıyam–rükû–secde ve selamla tamamlanır.',
            'Vakit girmeden kılınmaz; temizliğe ve kıbleye yönelmeye dikkat edilir.',
          ],
        ),
        _IbadetSection(
          title: 'Namazın Farzları (Özet)',
          items: [
            'Niyet',
            'İftitah tekbiri',
            'Kıyam',
            'Kıraat',
            'Rükû',
            'Secde',
            'Ka’de-i ahire',
            'Selam',
          ],
        ),
        _IbadetSection(
          title: 'Kısa Kılınış Sırası',
          items: [
            'Niyet → Tekbir',
            'Kıyam ve kıraat',
            'Rükû',
            'İki secde',
            'Oturma (ka’de) ve selam',
          ],
        ),
      ],
    ),
    _IbadetContent(
      title: '32 Farz',
      subtitle: 'Temel farzlar (özet başlıklar)',
      sections: [
        _IbadetSection(
          title: 'İmanın Şartları (6)',
          items: [
            'Allah’a iman',
            'Meleklere iman',
            'Kitaplara iman',
            'Peygamberlere iman',
            'Ahirete iman',
            'Kadere iman',
          ],
        ),
        _IbadetSection(
          title: 'İslam’ın Şartları (5)',
          items: [
            'Kelime-i şehadet',
            'Namaz kılmak',
            'Oruç tutmak',
            'Zekât vermek',
            'Hacca gitmek (gücü yetene)',
          ],
        ),
        _IbadetSection(
          title: 'Abdestin Farzları (4)',
          items: [
            'Yüzü yıkamak',
            'Kolları dirseklerle birlikte yıkamak',
            'Başın bir kısmını mesh etmek',
            'Ayakları topuklarla birlikte yıkamak',
          ],
        ),
        _IbadetSection(
          title: 'Guslün Farzları (3)',
          items: [
            'Ağıza su vermek',
            'Burna su çekmek',
            'Bütün vücudu yıkamak',
          ],
        ),
        _IbadetSection(
          title: 'Teyemmümün Farzları (2)',
          items: [
            'Niyet',
            'Yüzü ve kolları (dirseklerle) mesh etmek',
          ],
        ),
        _IbadetSection(
          title: 'Not',
          items: [
            'Sayımlar mezhep ve kaynaklara göre farklılık gösterebilir.',
          ],
        ),
      ],
    ),
    _IbadetContent(
      title: '54 Farz',
      subtitle: 'Özet liste (eğitim amaçlı)',
      sections: [
        _IbadetSection(
          title: 'İmanın Şartları (6)',
          items: [
            'Allah’a iman',
            'Meleklere iman',
            'Kitaplara iman',
            'Peygamberlere iman',
            'Ahirete iman',
            'Kadere iman',
          ],
        ),
        _IbadetSection(
          title: 'İslam’ın Şartları (5)',
          items: [
            'Kelime-i şehadet',
            'Namaz',
            'Oruç',
            'Zekât',
            'Hac (gücü yetene)',
          ],
        ),
        _IbadetSection(
          title: 'Temel İbadet Farzları (Özet)',
          items: [
            'Abdestin farzları (4)',
            'Guslün farzları (3)',
            'Teyemmümün farzları (2)',
            'Namazın farzları (özet başlıklar)',
          ],
        ),
        _IbadetSection(
          title: 'Günlük Sorumluluklar (Özet)',
          items: [
            'Helal kazanç ve haramdan sakınmak',
            'Kul hakkına riayet etmek',
            'Anne-babaya saygı ve iyilik',
            'Sözünde durmak, emanete sahip çıkmak',
            'Yalan, gıybet ve iftiradan kaçınmak',
            'İsraf etmemek, ölçülü olmak',
            'Temizliğe dikkat etmek',
            'Komşu ve akrabaya iyilik',
            'Haksızlık yapmamak',
            'Tevbe ve istiğfarda bulunmak',
            'Kalp kırmamak, affedici olmak',
          ],
        ),
        _IbadetSection(
          title: 'Not',
          items: [
            '54 farz listesi kaynaklara göre farklı biçimde sunulabilir.',
            'Bu sayfa kısa ve eğitim amaçlı bir özettir.',
          ],
        ),
      ],
    ),
    _IbadetContent(
      title: 'Cuma Namazı',
      subtitle: 'Kısa rehber ve şartlar',
      sections: [
        _IbadetSection(
          title: 'Özet',
          items: [
            'Cuma namazı, öğle vaktinde cemaatle kılınır.',
            'Hutbe dinlemek farzdır.',
            'Cuma Namazı 10 Rekattır 4 Rekat  İlk Sünnet, 2 Rekat Farz, 4 Rekat Son Sünnet.',
            'Ayrıca 4 Rekat Zuhre Ahir, 2 Rekatta Vaktin Sünneti Niyeti İle Kılınır Toplamda 16 Rekat olur'
          ],
        ),
        _IbadetSection(
          title: 'Kılınış',
          items: [
            'Hutbe dinlenir.',
            '2 rekât farz kılınır.',
          ],
        ),
        _IbadetSection(
          title: 'Şartlara Dair Not',
          items: [
            'Cemaat, vakit ve yer şartları önemlidir.',
          ],
        ),
      ],
    ),
    _IbadetContent(
      title: 'Cenaze Namazı',
      subtitle: 'Dört tekbirli dua',
      sections: [
        _IbadetSection(
          title: 'Özet',
          items: [
            'Cenaze namazı ayakta kılınır.',
            'Rükû ve secde yoktur.',
            'Dört tekbirden oluşur.',
          ],
        ),
        _IbadetSection(
          title: 'Kılınış',
          items: [
            'Niyet',
            '1. tekbir: Fatiha',
            '2. tekbir: Salavat',
            '3. tekbir: Cenaze duası',
            '4. tekbir: Selam',
          ],
        ),
      ],
    ),
    _IbadetContent(
      title: 'Abdest',
      subtitle: 'Farzlar, sünnetler ve bozanlar',
      sections: [
        _IbadetSection(
          title: 'Farzları (4)',
          items: [
            'Yüzü yıkamak',
            'Kolları dirseklerle yıkamak',
            'Başın bir kısmını mesh etmek',
            'Ayakları topuklarla yıkamak',
          ],
        ),
        _IbadetSection(
          title: 'Sünnetleri (Özet)',
          items: [
            'Besmele ve niyet',
            'Ellerin bileklere kadar yıkanması',
            'Ağız ve buruna su vermek',
            'Sıra ve tertibe uymak',
          ],
        ),
        _IbadetSection(
          title: 'Abdesti Bozanlar (Özet)',
          items: [
            'Tuvalet ihtiyacı',
            'Uyku (tam gevşeme)',
            'Kan ve benzeri akıntılar',
            'Aklı gideren haller',
          ],
        ),
      ],
    ),
    _IbadetContent(
      title: 'Teyemmüm',
      subtitle: 'Su bulunmadığında veya kullanılamadığında',
      sections: [
        _IbadetSection(
          title: 'Gerekli Haller',
          items: [
            'Su bulunmaması',
            'Su kullanmanın zararlı olması',
          ],
        ),
        _IbadetSection(
          title: 'Farzları',
          items: [
            'Niyet',
            'Yüz ve kolları mesh etmek',
          ],
        ),
        _IbadetSection(
          title: 'Kılınış',
          items: [
            'Temiz toprak/taş ile yüz mesh edilir.',
            'Kollar dirseklere kadar mesh edilir.',
          ],
        ),
      ],
    ),
    _IbadetContent(
      title: 'İbadet Duaları',
      subtitle: 'Kısa ve temel dualar',
      sections: [
        _IbadetSection(
          title: 'Namaz Açılış (Sübhaneke)',
          items: [
            'Sübhanekellahümme ve bihamdike, ve tebarekesmüke, ve teâlâ cedduke, ve lâ ilâhe ğayrük.',
          ],
        ),
        _IbadetSection(
          title: 'Rükû Duası',
          items: [
            'Sübhâne Rabbiye’l-azîm.',
          ],
        ),
        _IbadetSection(
          title: 'Secde Duası',
          items: [
            'Sübhâne Rabbiye’l-a’lâ.',
          ],
        ),
        _IbadetSection(
          title: 'Kısa Dua',
          items: [
            'Rabbenâ âtinâ fid-dünyâ haseneten ve fil-âhireti haseneten ve kınâ azâben-nâr.',
          ],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final temaService = TemaService();
    final renkler = temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text('İbadet', style: TextStyle(color: renkler.yaziPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _icerikler.length,
        itemBuilder: (context, index) {
          final content = _icerikler[index];
          return _IbadetCard(content: content, renkler: renkler);
        },
      ),
    );
  }
}

class _IbadetCard extends StatelessWidget {
  final _IbadetContent content;
  final TemaRenkleri renkler;

  const _IbadetCard({
    required this.content,
    required this.renkler,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: renkler.kartArkaPlan,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(Icons.menu_book, color: renkler.vurgu),
        title: Text(
          content.title,
          style: TextStyle(
            color: renkler.yaziPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          content.subtitle,
          style: TextStyle(color: renkler.yaziSecondary),
        ),
        trailing: Icon(Icons.chevron_right, color: renkler.yaziSecondary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _IbadetDetaySayfa(content: content),
            ),
          );
        },
      ),
    );
  }
}

class _IbadetDetaySayfa extends StatelessWidget {
  final _IbadetContent content;

  const _IbadetDetaySayfa({required this.content});

  @override
  Widget build(BuildContext context) {
    final temaService = TemaService();
    final renkler = temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text(content.title, style: TextStyle(color: renkler.yaziPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            content.subtitle,
            style: TextStyle(color: renkler.yaziSecondary),
          ),
          const SizedBox(height: 16),
          ...content.sections.map(
            (section) => _IbadetSectionCard(
              section: section,
              renkler: renkler,
            ),
          ),
        ],
      ),
    );
  }
}

class _IbadetSectionCard extends StatelessWidget {
  final _IbadetSection section;
  final TemaRenkleri renkler;

  const _IbadetSectionCard({
    required this.section,
    required this.renkler,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: renkler.kartArkaPlan,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renkler.ayirac),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              color: renkler.vurgu,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: renkler.yaziSecondary)),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: renkler.yaziPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IbadetContent {
  final String title;
  final String subtitle;
  final List<_IbadetSection> sections;

  const _IbadetContent({
    required this.title,
    required this.subtitle,
    required this.sections,
  });
}

class _IbadetSection {
  final String title;
  final List<String> items;

  const _IbadetSection({
    required this.title,
    required this.items,
  });
}
