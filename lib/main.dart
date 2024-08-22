import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:task_crafter_app/screens/homepage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_downloader/flutter_downloader.dart';

var globalMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyAaDxEMvmVBlX1IpxRv0D8U6THs5WM9w1Q',
      appId: '1:513909251690:android:76934dc4383d725f09f413',
      messagingSenderId: '513909251690',
      projectId: 'taskcrafter-a7c64',
    ),
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // Request Manage External Storage permission
  await _requestManageExternalStoragePermission();

  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Firebase Messaging Service
  await setupFirebaseMessaging();
  await FlutterDownloader.initialize(debug: true);
  runApp(const MyApp());
}

Future<void> _requestManageExternalStoragePermission() async {
  if (await Permission.manageExternalStorage.request().isGranted) {
    print('Manage External Storage permission granted');
  } else {
    print('Manage External Storage permission denied');
    globalMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
            'Manage External Storage permission is required for this app.'),
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a message while in the foreground: ${message.messageId}');
    // Handle your foreground message here
  });

  // Handle messages when the app is opened from a terminated state
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Message clicked!: ${message.messageId}');
    // Handle your message click event here
  });

  // Get the device token
  String? deviceToken = await messaging.getToken();
  print('Device Token: $deviceToken');

  // Store the device token in Firestore under the user's document
  if (deviceToken != null) {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({'deviceToken': deviceToken}, SetOptions(merge: true));
      print('Device Token stored successfully in Firestore');
    } catch (e) {
      print('Error storing device token: $e');
    }
  }

  // Request notification permission if it's the first time
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase Email Password Auth',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: homepage(), // Your home page widget
      scaffoldMessengerKey: globalMessengerKey,
    );
  }
}
