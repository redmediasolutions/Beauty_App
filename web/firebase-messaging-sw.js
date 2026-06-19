importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBDBOfk7l7rz1yonFIv36hxJblY67JGVA0",
  authDomain: "glowfit-4dfe8.firebaseapp.com",
  projectId: "glowfit-4dfe8",
  storageBucket: "glowfit-4dfe8.firebasestorage.app",
  messagingSenderId: "536255364081",
  appId: "1:536255364081:web:7ba250a4b16c43976",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification ?? {};
  self.registration.showNotification(title ?? "GlowFit", {
    body: body ?? "",
    icon: "/icons/Icon-192.png",
  });
});
