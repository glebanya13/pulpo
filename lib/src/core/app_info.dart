class AppInfo {
  static const version = '1.0.1';
  /// Shown under the icon on the home screen (iOS/Android).
  static const displayName = 'Monedero';
  /// Set in App Store Connect — not read from the binary.
  static const appStoreName = 'Monedero: Control de gastos';
  /// iOS / App Store bundle id.
  static const bundleId = 'com.pulpo.app';
  /// Android applicationId (Play Console / Firebase Android app).
  static const androidBundleId = 'com.pulpo.android';
  /// Flip when the client provides google-services.json / GoogleService-Info.plist.
  static const firebaseConfigured = true;
  static const firebaseProjectId = 'pulpo-mobi';
  /// Return URL for Sign in with Apple (Services ID in Apple Developer + Firebase).
  static const appleAuthHandler =
      'https://pulpo-mobi.firebaseapp.com/__/auth/handler';
  /// Services ID in Apple Developer (must match Firebase Auth → Apple).
  static const appleServicesId = 'com.pulpo.app.signin';
  static const googleServerClientId =
      '734611302573-l7occ13kr4q6r7el0l6uuoaoakrd5af1.apps.googleusercontent.com';

  static const site = 'https://monedero.mobi';
  static const privacyUrl = '$site/privacy';
  static const termsUrl = '$site/terms';
  static const supportUrl = '$site/support';
  static const supportEmail = 'hola@monedero.mobi';

  /// WhatsApp username without @ — opens via wa.me (no phone number in the link).
  static const whatsAppUsername = 'monedero.mobi';
  static const whatsAppHandle = '@$whatsAppUsername';
  static const whatsAppUrl = 'https://wa.me/$whatsAppUsername';

  static final privacyUri = Uri.parse(privacyUrl);
  static final termsUri = Uri.parse(termsUrl);
  static final supportUri = Uri.parse(supportUrl);
  static final mailtoUri = Uri.parse('mailto:$supportEmail');
  static final whatsAppUri = Uri.parse(whatsAppUrl);
}
