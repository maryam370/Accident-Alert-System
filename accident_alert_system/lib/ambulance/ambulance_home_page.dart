import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:accident_alert_system/ambulance/status_page.dart';

class AmbulanceHomePage extends StatefulWidget {
  @override
  _AmbulanceHomePageState createState() => _AmbulanceHomePageState();
}

class _AmbulanceHomePageState extends State<AmbulanceHomePage> {

  int _currentIndex = 0;
  final List<Widget> _pages = [
    AmbulanceDashboard(),
    StatusPage(),
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
          BottomNavigationBarItem(icon: Icon(Icons.local_hospital), label: 'status'),
        ],
      ),
    );
  }
}

class AmbulanceDashboard extends StatefulWidget {
  @override
  _AmbulanceDashboardState createState() => _AmbulanceDashboardState();
}

class _AmbulanceDashboardState extends State<AmbulanceDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupNotificationsListener();
    _setupFCMNotifications();
  }

  Future<void> _setupFCMNotifications() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await FirebaseMessaging.instance.getToken();
    print("Ambulance FCM Token: $token");

    if (token != null) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('ambulance_info')
            .doc(userId)
            .update({'fcmToken': token});
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🚑 Ambulance received FCM push while in foreground');
      if (message.notification != null) {
        _showNotificationDialog(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🚑 App opened from background FCM notification');
    });
  }

  void _showNotificationDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'New Notification'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  void _setupNotificationsListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore.collection('notification_recipients')
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: 'sent')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((recipientSnapshot) async {
      List<Map<String, dynamic>> notifications = [];

      for (var doc in recipientSnapshot.docs) {
        final recipientData = doc.data();
        final notificationId = recipientData['notificationId'];

        // Fetch notification details
        final notifDoc = await _firestore.collection('notifications')
            .doc(notificationId)
            .get();
        if (!notifDoc.exists) continue;

        final notifData = notifDoc.data()!;
        final accidentId = notifData['accidentId'];

        // Fetch accident details
        final accidentDoc = await _firestore.collection('accidents')
            .doc(accidentId)
            .get();
        if (!accidentDoc.exists) continue;

        final accidentData = accidentDoc.data()!;
        if (accidentData['status'] != 'detected') continue;

        // Fetch victim (user) info
        final victimId = accidentData['userId'];
        final victimDoc = await _firestore.collection('user_info')
            .doc(victimId)
            .get();

        Map<String, dynamic>? victimInfo;
        if (victimDoc.exists) {
          victimInfo = victimDoc.data()!;
          // Extract medical records if they exist
          if (victimInfo.containsKey('medicalRecords')) {
            final medical = victimInfo['medicalRecords'];
            victimInfo['bloodType'] = medical['bloodGroup'];
            victimInfo['emergencyContact'] = medical['emergencyContact'];
            victimInfo['allergies']= medical['allergies'];
          }
        }

        notifications.add({
          'id': notificationId,
          ...notifData,
          'timestamp': (notifData['timestamp'] as Timestamp).toDate(),
          'victim': victimInfo,
          'accidentLocation': accidentData['location'],
          'accidentAddress': accidentData['address'],
        });
      }

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    });
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final victim = notification['victim'];
    final emergencyContact = victim?['emergencyContact'];

    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEW ACCIDENT ALERT',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 16
              ),
            ),
            SizedBox(height: 12),
            Text(
              notification['message'],
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Time: ${DateFormat('MMM d, y - h:mm a').format(notification['timestamp'])}',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            
            if (victim != null) ...[
              Text(
                'VICTIM INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue
                ),
              ),
              Divider(),
              if (victim['name'] != null)
                Text('Name: ${victim['name']}'),
              if (victim['phoneNumber'] != null)
                Text('Phone: ${victim['phoneNumber']}'),
              if (victim['bloodType'] != null)
                Text('Blood Type: ${victim['bloodType']}'),
              if (victim['allergies'] != null && victim['allergies'].isNotEmpty)
                Text('Allergies: ${victim['allergies'].join(', ')}'),
              
              SizedBox(height: 12),
              
              if (emergencyContact != null) ...[
                Text(
                  'EMERGENCY CONTACT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue
                  ),
                ),
                Divider(),
                Text('Name: ${emergencyContact['name']}'),
                Text('Relation: ${emergencyContact['relation']}'),
                Text('Phone: ${emergencyContact['number']}'),
              ],
            ],
            
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _rejectAssignment(notification['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                  ),
                  child: Text('REJECT'),
                ),
                ElevatedButton(
                  onPressed: () => _acceptAssignment(notification['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                  ),
                  child: Text('ACCEPT ASSIGNMENT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rejectAssignment(String notificationId) async {
    final userId = _auth.currentUser!.uid;

    final recipientQuery = await _firestore.collection('notification_recipients')
        .where('notificationId', isEqualTo: notificationId)
        .where('recipientId', isEqualTo: userId)
        .get();

    for (var doc in recipientQuery.docs) {
      await doc.reference.update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {
      _notifications.removeWhere((n) => n['id'] == notificationId);
    });
  }

  Future<void> _acceptAssignment(String notificationId) async {
    final userId = _auth.currentUser!.uid;

    final recipientQuery = await _firestore.collection('notification_recipients')
        .where('notificationId', isEqualTo: notificationId)
        .where('recipientId', isEqualTo: userId)
        .get();

    for (var doc in recipientQuery.docs) {
      await doc.reference.update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    }

    // Update ambulance status
    await _firestore.collection('ambulance_info')
        .doc(userId)
        .update({
          'availability': false,
          'currentAssignment': notificationId
        });

    // Update accident record
    final notification = await _firestore.collection('notifications')
        .doc(notificationId)
        .get();

    await _firestore.collection('accidents')
        .doc(notification['accidentId'])
        .update({
          'assignedAmbulanceId': userId,
          'status': 'ambulance_dispatched'
        });
         Navigator.push(
    context,
    MaterialPageRoute(builder: (context) =>  StatusPage()),
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ambulance Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _setupNotificationsListener(),
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No new accident notifications'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(_notifications[index]);
                  },
                ),
    );
  }
}


