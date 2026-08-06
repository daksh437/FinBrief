/// Support and legal contact points.
///
/// Google Play requires a working support email on the store listing, and the
/// published Privacy Policy and account-deletion page name the same address —
/// so this is the one place to change it. If you switch to a dedicated support
/// mailbox, update [email] here AND the contact line in
/// backend/legal/delete-account.json and privacy.json.
class SupportConfig {
  SupportConfig._();

  static const email = 'instaflow38@gmail.com';

  /// Public pages served by the backend. Play Console asks for the first two
  /// on the store listing and the third in the Data Safety section.
  static const privacyUrl = 'https://finbrief-backend.onrender.com/privacy';
  static const termsUrl = 'https://finbrief-backend.onrender.com/terms';
  static const deleteAccountUrl = 'https://finbrief-backend.onrender.com/delete-account';

  /// Replies are aimed at this window; the deletion page commits to 30 days,
  /// which is the legal backstop rather than the target.
  static const responseTime = 'within 2 working days';
}
