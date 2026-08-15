import 'dart:js_interop';

@JS('lifeAppPushSupported')
external JSBoolean _pushSupported();

@JS('lifeAppPushPermission')
external JSString _pushPermission();

@JS('lifeAppEnablePush')
external JSPromise<JSString> _enablePush(JSString vapidPublicKey);

@JS('lifeAppLocalNotify')
external JSBoolean _localNotify(JSString title, JSString body);

class WebPushClient {
  const WebPushClient._();

  static bool get isSupported => _pushSupported().toDart;

  static String get permission {
    if (!isSupported) return 'unsupported';
    return _pushPermission().toDart;
  }

  static Future<String> subscribe(String vapidPublicKey) async {
    final json = await _enablePush(vapidPublicKey.toJS).toDart;
    return json.toDart;
  }

  static bool showLocal(String title, String body) {
    return _localNotify(title.toJS, body.toJS).toDart;
  }
}
