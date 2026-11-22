/// Arabic-aware text normalisation for search, ported from the React Native
/// app's `normalize()`. Two strings that a reader would consider identical must
/// compare equal: diacritics are dropped, alef/ya/ta-marbuta forms are unified
/// and Latin text is lower-cased.
String normalizeArabic(String? input) {
  if (input == null) {
    return '';
  }
  final StringBuffer out = StringBuffer();
  for (final int code in input.runes) {
    // Harakat (fatha…sukun) plus the superscript alef and tatweel carry no
    // searchable meaning.
    if (code >= 0x064B && code <= 0x065F) {
      continue;
    }
    if (code == 0x0670 || code == 0x0640) {
      continue;
    }
    final String char = String.fromCharCode(code);
    switch (char) {
      case 'أ':
      case 'إ':
      case 'آ':
      case 'ٱ':
        out.write('ا');
      case 'ى':
      case 'ئ':
      case 'ي':
        out.write('ي');
      case 'ة':
        out.write('ه');
      case 'ؤ':
        out.write('و');
      default:
        out.write(char.toLowerCase());
    }
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// True when [haystack] contains [query] after normalisation. An empty query
/// matches nothing, so empty fields never flood results.
bool containsQuery(String? haystack, String query) {
  final String needle = normalizeArabic(query);
  if (needle.isEmpty) {
    return false;
  }
  return normalizeArabic(haystack).contains(needle);
}
