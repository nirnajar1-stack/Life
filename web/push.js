function lifeAppUrlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
  const raw = atob(base64);
  const output = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i += 1) {
    output[i] = raw.charCodeAt(i);
  }
  return output;
}

function lifeAppPushSupported() {
  return Boolean(
    window.isSecureContext &&
      'Notification' in window &&
      'serviceWorker' in navigator &&
      'PushManager' in window,
  );
}

function lifeAppPushPermission() {
  if (!('Notification' in window)) return 'unsupported';
  return Notification.permission;
}

async function lifeAppEnablePush(vapidPublicKey) {
  if (!lifeAppPushSupported()) {
    throw new Error('unsupported');
  }
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') {
    throw new Error(permission === 'denied' ? 'denied' : 'default');
  }

  const registration = await navigator.serviceWorker.register('push/sw.js', {
    scope: './push/',
  });
  await navigator.serviceWorker.ready;

  const existing = await registration.pushManager.getSubscription();
  if (existing) {
    await existing.unsubscribe();
  }

  const subscription = await registration.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: lifeAppUrlBase64ToUint8Array(vapidPublicKey),
  });
  return JSON.stringify(subscription.toJSON());
}

function lifeAppLocalNotify(title, body) {
  if (!('Notification' in window) || Notification.permission !== 'granted') {
    return false;
  }
  new Notification(title, {
    body: body,
    icon: 'icons/Icon-192.png',
    dir: 'rtl',
    lang: 'he',
  });
  return true;
}

window.lifeAppPushSupported = lifeAppPushSupported;
window.lifeAppPushPermission = lifeAppPushPermission;
window.lifeAppEnablePush = lifeAppEnablePush;
window.lifeAppLocalNotify = lifeAppLocalNotify;
