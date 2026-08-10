import 'package:flutter/material.dart';
import '../services/tema_service.dart';
import '../services/language_service.dart';

class EsmaulHusnaSayfa extends StatefulWidget {
  const EsmaulHusnaSayfa({super.key});

  @override
  State<EsmaulHusnaSayfa> createState() => _EsmaulHusnaSayfaState();
}

class _EsmaulHusnaSayfaState extends State<EsmaulHusnaSayfa> {
  final TemaService _temaService = TemaService();
  final LanguageService _languageService = LanguageService();

  List<Map<String, String>> _getEsmaList() {
    final data = _languageService['esmaul_husna_list'];
    if (data is! List) return [];
    return data.map<Map<String, String>>((item) {
      if (item is Map) {
        return {
          'arabic': item['arabic']?.toString() ?? '',
          'name': item['name']?.toString() ?? '',
          'meaning': item['meaning']?.toString() ?? '',
        };
      }
      return {'arabic': '', 'name': '', 'meaning': ''};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final renkler = _temaService.renkler;

    return Scaffold(
      backgroundColor: renkler.arkaPlan,
      appBar: AppBar(
        title: Text(_languageService['esmaul_husna_title']),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: renkler.arkaPlanGradient != null
            ? BoxDecoration(gradient: renkler.arkaPlanGradient)
            : null,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _getEsmaList().length,
          itemBuilder: (context, index) {
            final esma = _getEsmaList()[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Number
                  Container(
                    width: 36,
                    height: 36,
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
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Arabic
                  Text(
                    esma['arabic']!,
                    style: TextStyle(
                      color: renkler.yaziPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(width: 14),
                  // Name and Meaning
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esma['name']!,
                          style: TextStyle(
                            color: renkler.vurgu,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          esma['meaning']!,
                          style: TextStyle(
                            color: renkler.yaziSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
