import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
    // Request permission for notifications
    await _requestPermission();

    // Get the FCM token
    final String? token = await _getToken();
    developer.log('FCM Token: $token', name: 'com.example.myapp.fcm');

    // Save the token to Firestore
    if (token != null) {
      await _saveTokenToFirestore(token);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Foreground Message Received: ${message.notification?.title}', name: 'com.example.myapp.fcm');
      // Here you could display a local notification or update the UI
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('Background Message Clicked: ${message.notification?.title}', name: 'com.example.myapp.fcm');
      // Here you could navigate to a specific screen based on the notification
    });
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      developer.log('User granted notification permission', name: 'com.example.myapp.fcm');
    } else {
      developer.log('User declined or has not yet granted notification permission', name: 'com.example.myapp.fcm');
    }
  }

  Future<String?> _getToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      await _firestore.collection('fcm_tokens').doc(token).set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
      });
      developer.log('FCM token saved to Firestore', name: 'com.example.myapp.fcm');
    } catch (e) {
      developer.log('Error saving FCM token to Firestore: $e', name: 'com.example.myapp.fcm');
    }
  }
}