import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Add this line


class UserHomePage extends StatefulWidget {
  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    HomePage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Home Page'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isMonitoring = false;
  int _count = 0;
  String? _fcmToken;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    await _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $_fcmToken");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received');
      _showNotificationDialog(message);
    });

    // Handle when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _showNotificationDialog(message);
      }
    });

    // Handle when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_showNotificationDialog);
  }

  void _showNotificationDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Alert'),
        content: Text(message.notification?.body ?? 'Emergency detected'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

Future<void> _sendNotification() async {
  if (_fcmToken == null) return;

  const serverUrl = 'http://10.0.2.2:3000/send-notification';
  
  try {
    final response = await http.post(
      Uri.parse(serverUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'token': _fcmToken, 
        'title': 'Emergency Alert', 
        'body': 'Accident detected! Help is on the way!'
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification');
    }
  } catch (e) {
    print('Error sending notification: $e');
  }
}



  void _startMonitoring() {
    setState(() {
      _isMonitoring = true;
      _count = 0;
    });
    _countdownLoop();
  }

  void _countdownLoop() {
    Future.delayed(Duration(seconds: 1), () {
      if (_isMonitoring && _count < 10) {
        setState(() => _count++);
        if (_count == 10) {
          _sendNotification(); // Automatically send notification
          setState(() => _isMonitoring = false);
        } else {
          _countdownLoop();
        }
      }
    });
  }

  void _stopMonitoring() {
    setState(() {
      _isMonitoring = false;
      _count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isMonitoring ? 'Monitoring: $_count/10' : 'Ready to monitor',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isMonitoring ? Colors.red : Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text(
              _isMonitoring ? 'STOP MONITORING' : 'START MONITORING',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder pages
class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text('History Page'));
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text('Settings Page'));
}