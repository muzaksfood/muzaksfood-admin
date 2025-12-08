importScripts('https://www.gstatic.com/firebasejs/8.3.2/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.3.2/firebase-messaging.js');

firebase.initializeApp({
    apiKey: "AIzaSyBBpjSJSA4H8C12IYbch_GHfvb78cAgKkE",
    authDomain: "themuzaksfood.firebaseapp.com",
    projectId: "themuzaksfood",
    storageBucket: "themuzaksfood.firebasestorage.app",
    messagingSenderId: "756706863472",
    appId: "1:756706863472:web:67619fa2c184c4b44087b5",
    measurementId: "G-2PP1GE6592"
});

const messaging = firebase.messaging();
messaging.setBackgroundMessageHandler(function (payload) {
    return self.registration.showNotification(payload.data.title, {
        body: payload.data.body ? payload.data.body : '',
        icon: payload.data.icon ? payload.data.icon : ''
    });
});