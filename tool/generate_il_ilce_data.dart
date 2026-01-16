import 'dart:convert';
import 'dart:io';

void main() {
  final sourceFile = File('data/il-ilce-json/js/il-ilce.json');
  if (!sourceFile.existsSync()) {
    stderr.writeln('Kaynak veri dosyası bulunamadı: ${sourceFile.path}');
    exit(1);
  }

  final outputFile = File('lib/data/il_ilce_data.dart');
  outputFile.parent.createSync(recursive: true);

  final decoded = json.decode(sourceFile.readAsStringSync()) as Map<String, dynamic>;
  final cities = (decoded['data'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
    ..sort((a, b) => _plateNumber(a).compareTo(_plateNumber(b)));

  final buffer = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND')
    ..writeln('// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars')
    ..writeln('')
    ..writeln('class IlIlceData {')
    ..writeln('  const IlIlceData._();')
    ..writeln('')
    ..writeln('  static const List<Map<String, Object>> _veriler = <Map<String, Object>>[');

  for (final city in cities) {
    final cityId = _plateNumber(city).toString();
    final cityName = _titleCase(city['il_adi'] as String);
    final districts = (city['ilceler'] as List<dynamic>).cast<Map<String, dynamic>>();

    buffer
      ..writeln('    const <String, Object>{')
      ..writeln("      'SehirID': '$cityId',")
      ..writeln("      'SehirAdi': '${_escape(cityName)}',")
      ..writeln("      'Ilceler': const <Map<String, String>>[");

    for (final district in districts) {
      final districtId = (district['ilce_kodu'] ?? '').toString().trim();
      if (districtId.isEmpty) {
        continue;
      }
      final districtName = _titleCase(district['ilce_adi'] as String);
      buffer.writeln(
        "        const <String, String>{'IlceID': '$districtId', 'IlceAdi': '${_escape(districtName)}'},",
      );
    }

    buffer
      ..writeln('      ],')
      ..writeln('    },');
  }

  buffer
    ..writeln('  ];')
    ..writeln('')
    ..writeln('  static List<Map<String, String>> tumIller() => _veriler')
    ..writeln('      .map((il) => <String, String>{')
    ..writeln("            'SehirID': il['SehirID'] as String,")
    ..writeln("            'SehirAdi': il['SehirAdi'] as String,")
    ..writeln('          })')
    ..writeln('      .toList(growable: false);')
    ..writeln('')
    ..writeln('  static List<Map<String, String>> ilceler(String sehirId) {')
    ..writeln('    final il = _veriler.firstWhere(')
    ..writeln("      (element) => element['SehirID'] == sehirId,")
    ..writeln('      orElse: () => const <String, Object>{},')
    ..writeln('    );')
    ..writeln("    final ilceler = il['Ilceler'];")
    ..writeln('    if (ilceler is List<Map<String, String>>) {')
    ..writeln('      return ilceler;')
    ..writeln('    }')
    ..writeln('    return const <Map<String, String>>[];')
    ..writeln('  }')
    ..writeln('}')
    ..writeln('');

  outputFile.writeAsStringSync('${buffer.toString().trim()}\n');
  stdout.writeln('✔ il_ilce_data.dart dosyası oluşturuldu (${outputFile.path}).');
}

int _plateNumber(Map<String, dynamic> city) {
  final raw = (city['plaka_kodu'] ?? '').toString().trim();
  return int.tryParse(raw) ?? int.parse(raw.replaceAll(RegExp(r'[^0-9]'), ''));
}

String _titleCase(String raw) {
  final lower = _toLowerTr(raw.trim());
  final buffer = StringBuffer();
  var capitalizeNext = true;

  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    if (_isSeparator(ch)) {
      capitalizeNext = true;
      buffer.write(ch);
      continue;
    }

    if (capitalizeNext) {
      buffer.write(_toUpperTr(ch));
      capitalizeNext = false;
    } else {
      buffer.write(ch);
    }
  }

  return buffer.toString();
}

bool _isSeparator(String value) {
  const separators = {' ', '-', '\'', '/', '(', ')'};
  return separators.contains(value);
}

String _toLowerTr(String input) {
  const lowerMap = {
    'I': 'ı',
    'İ': 'i',
    'Ş': 'ş',
    'Ğ': 'ğ',
    'Ü': 'ü',
    'Ö': 'ö',
    'Ç': 'ç',
    'Â': 'â',
    'Ê': 'ê',
    'Î': 'î',
    'Ô': 'ô',
    'Û': 'û',
  };

  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    if (lowerMap.containsKey(ch)) {
      buffer.write(lowerMap[ch]);
    } else {
      buffer.write(ch.toLowerCase());
    }
  }
  return buffer.toString();
}

String _toUpperTr(String input) {
  const upperMap = {
    'i': 'İ',
    'ı': 'I',
    'ş': 'Ş',
    'ğ': 'Ğ',
    'ü': 'Ü',
    'ö': 'Ö',
    'ç': 'Ç',
    'â': 'Â',
    'ê': 'Ê',
    'î': 'Î',
    'ô': 'Ô',
    'û': 'Û',
  };
  return upperMap[input] ?? input.toUpperCase();
}

String _escape(String value) => value
    .replaceAll('\\', r'\\')
    .replaceAll("'", r"\'");
