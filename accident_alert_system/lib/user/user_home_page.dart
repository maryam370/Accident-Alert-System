import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';
import 'package:accident_alert_system/user/user_history_page.dart';
import 'package:accident_alert_system/user/user_settings_page.dart';
import 'dart:async';





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
  String? _currentAccidentId;
  StreamSubscription<DocumentSnapshot>? _accidentStatusSubscription;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _notificationsCollection = FirebaseFirestore.instance.collection('notifications');

  Location location = new Location();
 bool _serviceEnabled = false;
 PermissionStatus? _permissionGranted;
 LocationData? _locationData;
 

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _requestLocatoinPermission();
  }

@override
  void dispose() {
    _accidentStatusSubscription?.cancel();
    super.dispose();
  }


  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp();
    await _setupNotifications();
  }
  void _requestLocatoinPermission() async{
  _serviceEnabled = await location.serviceEnabled();
  if(!_serviceEnabled){
    _serviceEnabled=await location.requestService();
    if(!_serviceEnabled){
      return;
    }
  }
  _permissionGranted=await location.hasPermission();
if(_permissionGranted==PermissionStatus.denied){
  _permissionGranted=await location.requestPermission();
  if(_permissionGranted==PermissionStatus.granted){
    return;
  }
}
_locationData=await location.getLocation();
setState(() {
  
});
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

      final location = {
        'latitude': _locationData?.latitude ?? 0.0, 
        'longitude': _locationData?.longitude ?? 0.0
      };

      // Create accident document
      final accidentRef = await _firestore.collection('accidents').add({
        'userId': user.uid,
        'location': location,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'detected',
        'assignedAmbulanceId': '',
        'assignedHospitalId': '',
        'assignedPoliceId': '',
      });

      _currentAccidentId = accidentRef.id;
      
      // Start listening for status updates
      _setupAccidentStatusListener();

      // Store notification data for responders
      await _storeNotificationData(
        accidentId: accidentRef.id,
        userId: user.uid,
        location: location,
      );

      setState(() {}); // Trigger UI rebuild
    } catch (e) {
      print('Error saving accident: $e');
    }
  }
  void _setupAccidentStatusListener() {
    if (_currentAccidentId == null) return;

    String? lastStatus;
    
    _accidentStatusSubscription = _firestore
        .collection('accidents')
        .doc(_currentAccidentId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        final status = snapshot.data()?['status'] ?? 'detected';
        
        // Only send notification if status changed
        if (status != lastStatus) {
          lastStatus = status;
          
          // Update UI
          _showStatusUpdate(status);
          setState(() {});
          
          // Send push notification for this status update
          await _sendStatusNotification(status);
        }
      }
    });
  }
  Future<void> _sendStatusNotification(String status) async {
    if (_fcmToken == null) return;

    const serverUrl = 'http://10.0.2.2:3000/send-notification';
    
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'token': _fcmToken, 
          'title': _getNotificationTitle(status),
          'body': _getNotificationBody(status),
          'data': {
            'type': 'status_update',
            'status': status,
            'accidentId': _currentAccidentId,
          }
        }),
      );

      if (response.statusCode == 200) {
        print('Status notification sent: $status');
      } else {
        print('Failed to send status notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending status notification: $e');
    }
  }

  String _getNotificationTitle(String status) {
    switch (status) {
      case 'detected': return 'Accident Reported';
      case 'ambulance_dispatched': return 'Ambulance Coming';
      case 'hospital_notified': return 'Hospital Ready';
      case 'resolved': return 'Case Resolved';
      default: return 'Status Update';
    }
  }

  String _getNotificationBody(String status) {
    switch (status) {
      case 'detected': 
        return 'Emergency services have been notified about your accident.';
      case 'ambulance_dispatched': 
        return 'An ambulance is on its way to your location.';
      case 'hospital_notified': 
        return 'Nearby hospitals have been prepared for your arrival.';
      case 'resolved': 
        return 'Your accident case has been successfully resolved.';
      default: 
        return 'Your accident status has been updated.';
    }
  }

  void _showStatusUpdate(String status) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getStatusMessage(status)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'detected':
        return 'Accident detected! Help is on the way';
      case 'ambulance_dispatched':
        return 'Ambulance has been dispatched';
      case 'hospital_notified':
        return 'Hospital has been notified';
      case 'resolved':
        return 'Your accident case has been resolved';
      default:
        return 'Status updated: $status';
    }
  }

  // NEW METHOD: Stores notification data without sending push notifications
  Future<void> _storeNotificationData({
    required String accidentId,
    required String userId,
    required Map<String, dynamic> location,
  }) async {
    try {
      // Get all emergency responders
      final responders = await _firestore.collection('users')
          .where('role', whereIn: ['Hospital', 'Police', 'Ambulance'])
          .get();

      // Store a notification document for each responder
      final batch = _firestore.batch();
      final timestamp = FieldValue.serverTimestamp();
      
      for (final responder in responders.docs) {
        final notificationRef = _notificationsCollection.doc();
        
        batch.set(notificationRef, {
          'accidentId': accidentId,
          'userId': userId,
          'responderId': responder.id,
          'message': 'New accident detected at ${location['latitude']}, ${location['longitude']}',
          'timestamp': timestamp,
          'status': 'sent',
        });
      }

      await batch.commit();
      print('Stored notifications for ${responders.docs.length} responders');
    } catch (e) {
      print('Error storing notification data: $e');
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
    body: _currentAccidentId != null
        ? StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('accidents')
                .doc(_currentAccidentId)
                .snapshots(),
            builder: (context, snapshot) {
              final status = snapshot.hasData
                  ? snapshot.data!.get('status') ?? 'detected'
                  : 'detected';

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getStatusIcon(status),
                      size: 64,
                      color: _getStatusColor(status),
                    ),
                    SizedBox(height: 20),
                    Text(
                      _getStatusTitle(status),
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16),
                    Text(
                      _getStatusMessage(status),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 30),
                    if (status == 'resolved')
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentAccidentId = null;
                            _accidentStatusSubscription?.cancel();
                          });
                        },
                        child: Text('RETURN TO MONITORING'),
                      ),
                  ],
                ),
              );
            },
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isMonitoring
                      ? 'Monitoring: $_count/10'
                      : 'Ready to monitor',
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isMonitoring ? Colors.red : Colors.blue,
                    padding: EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    _isMonitoring ? 'STOP MONITORING' : 'START MONITORING',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
  );
}

    // Helper methods for status UI
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'detected': return Icons.warning;
      case 'ambulance_dispatched': return Icons.local_hospital;
      case 'hospital_notified': return Icons.medical_services;
      case 'resolved': return Icons.check_circle;
      default: return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'detected': return Colors.orange;
      case 'ambulance_dispatched': return Colors.blue;
      case 'hospital_notified': return Colors.green;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'detected': return 'ACCIDENT DETECTED';
      case 'ambulance_dispatched': return 'AMBULANCE DISPATCHED';
      case 'hospital_notified': return 'HOSPITAL NOTIFIED';
      case 'resolved': return 'CASE RESOLVED';
      default: return 'STATUS UPDATE';
    }
  }

}



