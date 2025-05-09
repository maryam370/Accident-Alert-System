import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
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
   bottomNavigationBar: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.blue.shade800,
        Colors.blue.shade600,
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 2,
        offset: Offset(0, -2),
      ),
    ],
  ),
  child: BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: (index) => setState(() => _currentIndex = index),
    backgroundColor: Colors.transparent,
    elevation: 0,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white.withOpacity(0.7),
    selectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    type: BottomNavigationBarType.fixed,
    items: [
      BottomNavigationBarItem(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == 0 
                ? Colors.white.withOpacity(0.2) 
                : Colors.transparent,
          ),
          child: Icon(Icons.home_filled),
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == 1 
                ? Colors.white.withOpacity(0.2) 
                : Colors.transparent,
          ),
          child: Icon(Icons.history),
        ),
        label: 'History',
      ),
      BottomNavigationBarItem(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == 2 
                ? Colors.white.withOpacity(0.2) 
                : Colors.transparent,
          ),
          child: Icon(Icons.settings),
        ),
        label: 'Settings',
      ),
    ],
  ),
),

    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>with TickerProviderStateMixin {
    late AnimationController _carAnimationController;
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
final _notificationRecipientsCollection = FirebaseFirestore.instance.collection('notification_recipients');

  Location location = new Location();
 bool _serviceEnabled = false;
 PermissionStatus? _permissionGranted;
 LocationData? _locationData;
 

  @override
  void initState() {
    super.initState();
     _carAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this, // This now works because we added TickerProviderStateMixin
    )..repeat(reverse: true);
    _initializeFirebase();
    _requestLocatoinPermission();
   
  }

@override
  void dispose() {
    _accidentStatusSubscription?.cancel();
    _carAnimationController.dispose();
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
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  backgroundColor: Colors.white,
  title: Row(
    children: [
      Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
      SizedBox(width: 10),
      Text(
        'Accident Detected!',
        style: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    ],
  ),
  content: Text(
    'Emergency services will be notified in 10 seconds unless canceled.',
    style: TextStyle(fontSize: 16),
  ),
  actionsAlignment: MainAxisAlignment.end,
  actions: [
    TextButton(
      onPressed: () {
        _notificationCancelled = true;
        Navigator.of(context).pop();
        setState(() => _isDialogShowing = false);
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(
        'CANCEL',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
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

    const serverUrl = 'http://192.168.52.170:3000/send-notification';
    
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          //'token': _fcmToken, 
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
        return 'Accident detected! Help is on the way!';
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

    // Check if notification already exists
    final existingNotifications = await _notificationsCollection
        .where('accidentId', isEqualTo: accidentId)
        .get();
        
    if (existingNotifications.docs.isNotEmpty) return;

    // Create the main notification document
    final notificationMessage = 'New accident detected }';
    final timestamp = FieldValue.serverTimestamp();
    
    final notificationRef = await _notificationsCollection.add({
      'accidentId': accidentId,
      'userId': userId,
      'message': notificationMessage,
      'timestamp': timestamp,
    });

    // Store recipient records in a batch
    final batch = _firestore.batch();
    
    for (final responder in responders.docs) {
      final recipientRef = _notificationRecipientsCollection.doc();
      
      batch.set(recipientRef, {
        'notificationId': notificationRef.id,
        'recipientId': responder.id,
        'status': 'sent', // Can be 'sent', 'delivered', 'read'
        'timestamp': timestamp,
      });
    }

    await batch.commit();
    print('Stored notification with ${responders.docs.length} recipients');
  } catch (e) {
    print('Error storing notification data: $e');
  }
}



 Future<void> _sendNotification() async {
    if (_fcmToken == null) return;

    const serverUrl = 'http://192.168.52.170:3000/send-notification';
    
    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'token': _fcmToken, 
          'title': 'Emergency Alert', 
          'body': 'Accident detected! Help in on the way!'
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
        // Only show dialog if not already showing
        if (!_isDialogShowing) {
          _showNotificationDialog(RemoteMessage(
            notification: RemoteNotification(
              title: 'Emergency Alert',
              body: 'Accident detected! Cancel if it was a false alarm!',
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

  final String userId = FirebaseAuth.instance.currentUser!.uid;
  DatabaseReference flagRef = FirebaseDatabase.instance.ref("monitoring/$userId/flag");

  flagRef.onValue.listen((DatabaseEvent event) {
    final flagValue = event.snapshot.value;
    if (flagValue == true && !_notificationCancelled) {
      _sendNotification();
      setState(() => _isMonitoring = false);
    }
  });
}

  // void _countdownLoop() {
  //   Future.delayed(Duration(seconds: 1), () {
  //     if (_isMonitoring && _count < 10) {
  //       setState(() => _count++);
  //       if (_count == 10) {
  //         _sendNotification(); // Automatically send notification
  //         setState(() => _isMonitoring = false);
  //       } else {
  //         _countdownLoop();
  //       }
  //     }
  //   });
  // }

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
  title: Padding(
    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
    child: const Text(
      'Monitor',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 22,
        color: Color(0xFF0D5D9F),
      ),
    ),
  ),
  centerTitle: true,
  backgroundColor: Colors.white,
  elevation: 0.5,
  shadowColor: Colors.blue.shade100,
  toolbarHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
  automaticallyImplyLeading: false, // Soft blue shadow
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      bottom: Radius.circular(15), // Rounded bottom corners
    ),
  ),
  iconTheme: const IconThemeData(
    color: Color(0xFF0D5D9F), // Matching blue for any leading icons
  ),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0D5D9F).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.logout,
            color: Color(0xFF0D5D9F),
            size: 24,
          ),
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.of(context).pushReplacementNamed('/login');
        },
      ),
    ),
  ],
),
      body: Container(
              color: Colors.white, // Simple white background

      
        child: _currentAccidentId != null
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
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(status),
                                  size: 64,
                                  color: _getStatusColor(status),
                                ),
                              ),
                              const SizedBox(height: 30),
                              Text(
                                _getStatusTitle(status),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getStatusMessage(status),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 30),
                              if (status == 'resolved')
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentAccidentId = null;
                                      _accidentStatusSubscription?.cancel();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 40, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'RETURN TO MONITORING',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated car icon
                      RotationTransition(
                        turns: Tween(begin: -0.05, end: 0.05).animate(
                          _carAnimationController,
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          size: 100,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        _isMonitoring
                            ? 'Monitoring your journey...'//\n$_count/10 checks completed'
                            : 'Ready to monitor your journey',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
  width: double.infinity,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue.shade300, Colors.blue.shade700],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    borderRadius: BorderRadius.circular(50),
  ),
                      child: ElevatedButton(
                        onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMonitoring 
                              ? Colors.red.shade600 
                              : Colors.blue.shade800,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                          shadowColor: Colors.blue.withOpacity(0.3),
                        ),
                        child: Text(
                          _isMonitoring ? 'STOP MONITORING' : 'START MONITORING',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),),
                      const SizedBox(height: 20),
                      if (_isMonitoring)
                        const Text(
                          'Drive safely! We\'ll alert you if we detect an accident',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
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



