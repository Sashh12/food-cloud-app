import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Initialize Firebase Cloud Messaging & Firestore Listener
  static Future<void> initialize() async {
    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("🔴 Notifications are denied by the user.");
      return;
    }

    // Subscribe user to "Orderstatus" topic
    await _firebaseMessaging.subscribeToTopic("Orderstatus");

    // Listen for order status updates in Firestore
    _listenForOrderUpdates();

    // Setup local notifications
    await _setupLocalNotifications();
  }

  /// Listen for Firestore Order Status Updates
  // static void _listenForOrderUpdates() {
  //   FirebaseFirestore.instance.collection('Orders').snapshots().listen((snapshot) {
  //     for (var docChange in snapshot.docChanges) {
  //       if (docChange.type == DocumentChangeType.modified) {
  //         var data = docChange.doc.data();
  //         if (data != null && data.containsKey('KitchenorderStatus')) {
  //           String status = data['KitchenorderStatus'];
  //           _showNotification("Order Update", "Your order status is now $status.");
  //         }
  //       }
  //     }
  //   });
  // }

  static void _listenForOrderUpdates() {
    FirebaseFirestore.instance.collection('Orders').snapshots().listen((snapshot) {
      for (var docChange in snapshot.docChanges) {
        var data = docChange.doc.data();
        if (data == null) continue;

        if (docChange.type == DocumentChangeType.added) {
          // 🆕 Notify user when a new order is placed
          _showNotification("Order Placed", "Your order has been placed successfully!");
        }

        if (docChange.type == DocumentChangeType.modified && data.containsKey('KitchenorderStatus')) {
          // 🔄 Notify user when the order status is updated
          String status = data['KitchenorderStatus'];
          _showNotification("Order Update", "Your order status is now $status.");
        }
      }
    });
  }



  /// Setup Local Notifications
  static Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(settings);
  }

  /// Show Local Notification
  static Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_channel',
      'Order Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(0, title, body, details);
  }
}
