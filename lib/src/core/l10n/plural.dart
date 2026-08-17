/// Русские формы: 1 / 2–4 / 5–0 и 11–19.
String ruPlural(int n, String one, String few, String many) {
  final abs = n.abs();
  final mod100 = abs % 100;
  final mod10 = abs % 10;
  if (mod100 >= 11 && mod100 <= 19) return many;
  if (mod10 == 1) return one;
  if (mod10 >= 2 && mod10 <= 4) return few;
  return many;
}

String countPhrase({
  required String lang,
  required int n,
  required String esOne,
  required String esMany,
  required String enOne,
  required String enMany,
  required String ruOne,
  required String ruFew,
  required String ruMany,
}) {
  switch (lang) {
    case 'ru':
      return '$n ${ruPlural(n, ruOne, ruFew, ruMany)}';
    case 'en':
      return n == 1 ? '1 $enOne' : '$n $enMany';
    default:
      return n == 1 ? '1 $esOne' : '$n $esMany';
  }
}
