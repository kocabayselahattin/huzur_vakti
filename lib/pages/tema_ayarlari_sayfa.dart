import 'package:flutter/material.dart';
import '../services/tema_service.dart';

class TemaAyarlariSayfa extends StatefulWidget {
  const TemaAyarlariSayfa({super.key});

  @override
  State<TemaAyarlariSayfa> createState() => _TemaAyarlariSayfaState();
}

class _TemaAyarlariSayfaState extends State<TemaAyarlariSayfa> {
  final TemaService _temaService = TemaService();

  @override
  void initState() {
    super.initState();
    _temaService.addListener(_onTemaChanged);
  }

  @override
  void dispose() {
    _temaService.removeListener(_onTemaChanged);
    super.dispose();
  }

  void _onTemaChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;
    
    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text('Tema Ayarları', style: TextStyle(color: renkler.yaziPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: renkler.yaziPrimary),
      ),
      body: Column(
        children: [
          // Önizleme alanı
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: renkler.kartArkaPlan,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: renkler.vurgu.withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'Tema Önizlemesi',
                  style: TextStyle(
                    color: renkler.yaziSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(renkler.ikon, color: renkler.vurgu, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      renkler.isim,
                      style: TextStyle(
                        color: renkler.yaziPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  renkler.aciklama,
                  style: TextStyle(
                    color: renkler.yaziSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                // Örnek vakit satırı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: renkler.vurgu.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wb_sunny, color: renkler.vurgu, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Güneş',
                          style: TextStyle(
                            color: renkler.vurgu,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '07:45',
                        style: TextStyle(
                          color: renkler.vurgu,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tema listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AppTema.values.length,
              itemBuilder: (context, index) {
                final tema = AppTema.values[index];
                final temaRenkleri = TemaService.temalar[tema]!;
                final secili = _temaService.mevcutTema == tema;

                return GestureDetector(
                  onTap: () async {
                    await _temaService.temayiDegistir(tema);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: temaRenkleri.arkaPlanGradient,
                      color: temaRenkleri.arkaPlanGradient == null 
                          ? temaRenkleri.arkaPlan 
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: secili 
                            ? temaRenkleri.vurgu 
                            : temaRenkleri.ayirac,
                        width: secili ? 3 : 1,
                      ),
                      boxShadow: secili
                          ? [
                              BoxShadow(
                                color: temaRenkleri.vurgu.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Tema ikonu
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: temaRenkleri.kartArkaPlan,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            temaRenkleri.ikon,
                            color: temaRenkleri.vurgu,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Tema bilgisi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                temaRenkleri.isim,
                                style: TextStyle(
                                  color: temaRenkleri.yaziPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                temaRenkleri.aciklama,
                                style: TextStyle(
                                  color: temaRenkleri.yaziSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Renk örnekleri
                        Row(
                          children: [
                            _renkDairesi(temaRenkleri.vurgu),
                            const SizedBox(width: 4),
                            _renkDairesi(temaRenkleri.vurguSecondary),
                            const SizedBox(width: 4),
                            _renkDairesi(temaRenkleri.kartArkaPlan),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Seçim işareti
                        if (secili)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: temaRenkleri.vurgu,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: temaRenkleri.arkaPlan,
                              size: 18,
                            ),
                          )
                        else
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: temaRenkleri.ayirac,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _renkDairesi(Color renk) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: renk,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }
}
