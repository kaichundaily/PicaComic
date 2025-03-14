import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';

extension AppTranslation on String {
  String _translate() {
    var locale = App.locale;
    var key = "${locale.languageCode}_${locale.countryCode}";
    if (locale.languageCode == "en") {
      key = "en_US";
    }
    return (translations[key]?[this]) ?? this;
  }

  String get tl => _translate();

  String get tlEN => translations["en_US"]![this] ?? this;

  String tlParams(Map<String, String> values) {
    var res = _translate();
    for (var entry in values.entries) {
      res = res.replaceFirst("@${entry.key}", entry.value);
    }
    return res;
  }

  static late final Map<String, Map<String, String>> translations;

  static Future<void> init() async{
    var data = await rootBundle.load("assets/translation.json");
    var json = jsonDecode(utf8.decode(data.buffer.asUint8List()));
    translations = { for (var e in json.entries) e.key : Map<String, String>.from(e.value) };
  }
}

extension ListTranslation on List<String> {
  List<String> _translate() {
    return List.generate(length, (index) => this[index].tl);
  }

  List<String> get tl => _translate();
}
