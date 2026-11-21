import 'package:url_launcher/url_launcher.dart';

/// Public places the app points at. Kept in one file so a link changes in a
/// single place instead of in every screen that shows it.
abstract final class WaraqLinks {
  /// Community group (carried over from the React Native generation).
  static const String whatsapp = 'https://chat.whatsapp.com/IsysOrI7U0vCW7PVUHPPnD';

  /// Source code.
  static const String github = 'https://github.com/ayoub-ben-99/waraq-app';
}

/// Opens [url] outside the app. Returns false instead of throwing, so callers
/// can show a message when no browser or WhatsApp is installed.
Future<bool> openExternalLink(String url) async {
  final Uri? uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
