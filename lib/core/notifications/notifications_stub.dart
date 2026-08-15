class WebPushClient {
  const WebPushClient._();

  static bool get isSupported => false;

  static String get permission => 'unsupported';

  static Future<String> subscribe(String vapidPublicKey) {
    throw UnsupportedError('התראות זמינות רק באפליקציית הווב');
  }

  static bool showLocal(String title, String body) => false;
}
