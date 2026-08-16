class AppInfo {
  static const version = '1.0.0';
  static const site = 'https://pulpo.mobi';
  static const privacyUrl = '$site/privacy';
  static const termsUrl = '$site/terms';
  static const supportUrl = '$site/support';
  static const supportEmail = 'support@pulpo.mobi';

  static final privacyUri = Uri.parse(privacyUrl);
  static final termsUri = Uri.parse(termsUrl);
  static final supportUri = Uri.parse(supportUrl);
  static final mailtoUri = Uri.parse('mailto:$supportEmail');
}
