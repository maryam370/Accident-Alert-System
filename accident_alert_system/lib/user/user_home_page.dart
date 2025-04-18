import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  bool _isDialogShowing = false; // Add this flag
  bool _isMonitoring = false;
  int _count = 0;
  String? _fcmToken;
  bool _notificationCancelled = false;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $_fcmToken");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received');
      // Only show if not already showing and monitoring
      if (!_isDialogShowing && _isMonitoring) {
        _showNotificationDialog(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }
  void _handleBackgroundMessage(RemoteMessage message) {
    // Handle background notification without showing dialog
    print('App opened from background notification');
  }

  void _showNotificationDialog(RemoteMessage message) {
    setState(() => _isDialogShowing = true);
    _notificationCancelled = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(Duration(seconds: 10), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          if (!_notificationCancelled) {
            _saveAccidentToFirestore();
          }
          setState(() => _isDialogShowing = false);
        });

        return AlertDialog(
          title: Text('Accident Detected!'),
          content: Text('Emergency services will be notified in 10 seconds unless canceled'),
          actions: [
            TextButton(
              onPressed: () {
                _notificationCancelled = true;
                Navigator.of(context).pop();
                setState(() => _isDialogShowing = false);
              },
              child: Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _saveAccidentToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get current location (you'll need to implement this)
      // For now using mock location
      final location = {'latitude': 37.4219983, 'longitude': -122.084};

      await _firestore.collection('accidents').add({
        'userId': user.uid,
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'detected',
        'severity': 'high', // You can determine this from sensor data
        'assignedAmbulanceId': '',
        'assignedHospitalId': '',
        'assignedPoliceId': '',
      });

      print('Accident saved to Firestore');
    } catch (e) {
      print('Error saving accident: $e');
    }
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
        // Only show dialog if not already showing
        if (!_isDialogShowing) {
          _showNotificationDialog(RemoteMessage(
            notification: RemoteNotification(
              title: 'Emergency Alert',
              body: 'Accident detected! Help is on the way!',
            ),
          ));
        }
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  void _startMonitoring() {
    setState(() {
      _isMonitoring = true;
      _count = 0;
      _notificationCancelled = false;
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

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text('History Page'));
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(child: Text('Settings Page'));
}
