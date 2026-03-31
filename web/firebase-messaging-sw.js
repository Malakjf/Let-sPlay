// Minimal Firebase Messaging service worker
// Place this file at web/firebase-messaging-sw.js so the browser can register it.

importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

// Optional: initialize with config if you need it here. Many setups work without
// initialization in the SW as long as the file exists and messaging is configured
// in the main page. If you need to initialize, add your project config below.
// firebase.initializeApp({
//   apiKey: "...",
//   authDomain: "...",
//   projectId: "...",
//   messagingSenderId: "...",
//   appId: "...",
//});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = (payload.notification && payload.notification.title) || 'Notification';
  const notificationOptions = {
    body: (payload.notification && payload.notification.body) || '',
    data: payload.data || {},
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  const url = event.notification.data?.click_action || '/';
  event.waitUntil(clients.matchAll({type: 'window', includeUncontrolled: true}).then(windowClients => {
    for (let client of windowClients) {
      if (client.url === url && 'focus' in client) return client.focus();
    }
    if (clients.openWindow) return clients.openWindow(url);
  }));
});
