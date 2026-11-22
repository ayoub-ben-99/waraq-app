/// Keys used in [SharedPreferences]. Versioned so a future migration can read
/// the previous shape instead of guessing.
abstract final class PrefsKeys {
  static const String settings = 'waraq.settings.v2';
  static const String documents = 'waraq.documents.v2';
  static const String positions = 'waraq.positions.v2';
  static const String bookmarks = 'waraq.bookmarks.v2';
  static const String review = 'waraq.review.v1';
  static const String sampleSeeded = 'waraq.sample-seeded.v2';
}
