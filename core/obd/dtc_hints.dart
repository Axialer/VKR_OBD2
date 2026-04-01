import 'dtc_catalog.dart';

/// Встроенный минимум (если asset не загрузился).
const Map<String, String> kDtcDescriptionsRu = {  'P0101': 'Неисправность цепи ДМРВ (MAF/MAP)',
  'P0133': 'Медленный отклик датчика кислорода (банк 1 датчик 1)',
  'P0301': 'Пропуски зажигания — цилиндр 1',
  'P0420': 'Низкая эффективность каталитического нейтрализатора (банк 1)',
  'P0562': 'Низкое напряжение бортсети',
  'P0563': 'Высокое напряжение бортсети',
};

const Map<String, String> kDtcRecommendationsRu = {
  'P0171': 'Проверить подсос воздуха, ДМРВ/ДАД, давление топлива, лямбда-зонд.',
  'P0301': 'Проверить свечи зажигания, катушки, компрессию в 1-м цилиндре.',
  'P0420': 'Проверить герметичность выпуска, лямбда-зонды, состояние катализатора.',
  'P0562': 'Проверить аккумулятор, генератор и состояние ремня.',
};

Map<String, String> dtcDescriptionsFallbackRu() => Map<String, String>.from(kDtcDescriptionsRu);
Map<String, String> dtcRecommendationsFallbackRu() => Map<String, String>.from(kDtcRecommendationsRu);

String dtcDescriptionRu(String code) {
  final c = code.toUpperCase();
  final fromAsset = DtcCatalog.instance.lookup(c);
  if (fromAsset != null && fromAsset.isNotEmpty) return fromAsset;
  return kDtcDescriptionsRu[c] ??
      'Код зарегистрирован ЭБУ. Уточните описание в сервисной документации или расширьте справочник.';
}

String? dtcRecommendationRu(String code) {
  return kDtcRecommendationsRu[code.toUpperCase()];
}
