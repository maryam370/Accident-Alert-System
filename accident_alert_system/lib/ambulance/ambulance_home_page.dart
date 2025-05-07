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
  final Color primaryColor = const Color(0xFF0D5D9F); // Your primary blue
  int _currentIndex = 0;
  final List<Widget> _pages = [
    AmbulanceDashboard(),
    StatusPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          color: primaryColor, // Use your primary blue color
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
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
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 0 
                      ? Colors.white.withOpacity(0.2) 
                      : Colors.transparent,
                ),
                child: const Icon(Icons.home_filled),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == 1 
                      ? Colors.white.withOpacity(0.2) 
                      : Colors.transparent,
                ),
                child: const Icon(Icons.local_hospital),
              ),
              label: 'Status',
            ),
          ],
        ),
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
  final Color primaryColor = const Color(0xFF0D5D9F);
  final Color cardColor = const Color(0xFFE6F2FF);
  final Color accentColor = const Color(0xFF4A90E2);
  final Color textColor = const Color(0xFF333333);
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
    final location = notification['accidentLocation'];

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACCIDENT ALERT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(notification['timestamp']),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),

            if (victim != null) ...[
              _buildInfoSection(
                icon: Icons.person_outlined,
                title: 'Victim Information',
                items: [
                  _buildInfoItem('Name', victim['name']),
                  if (victim['phoneNumber'] != null)
                    _buildInfoItem('Phone', victim['phoneNumber']),
                  if (victim['bloodType'] != null)
                    _buildInfoItem('Blood Type', victim['bloodType']),
                  if (victim['allergies'] != null && victim['allergies'].isNotEmpty)
                    _buildInfoItem('Allergies', victim['allergies'].join(', ')),
                ],
              ),
              const SizedBox(height: 12),
            ],

            if (emergencyContact != null) ...[
              _buildInfoSection(
                icon: Icons.emergency_outlined,
                title: 'Emergency Contact',
                items: [
                  _buildInfoItem('Name', emergencyContact['name']),
                  _buildInfoItem('Relation', emergencyContact['relation']),
                  _buildInfoItem('Phone', emergencyContact['number']),
                ],
              ),
              const SizedBox(height: 12),
            ],

               if (location != null) ...[
  Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 18,
          color: const Color.fromARGB(255, 8, 88, 153),
        ),
        const SizedBox(width: 6),
        Text(
          "Location",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color.fromARGB(255, 8, 88, 153),
          ),
        ),
      ],
    ),
  ),
  OutlinedButton(
    onPressed: () async {
      // final lat = location['latitude'].toString();
      // final lon = location['longitude'].toString();
      // await _openMap(lat, lon);
    },
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color.fromARGB(255, 8, 88, 153),
      side: const BorderSide(
        color: Color.fromARGB(255, 8, 88, 153),
        width: 1.2,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.map_outlined, size: 18),
        SizedBox(width: 6),
        Text(
          "View on Map",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 12),
],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectAssignment(notification['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('REJECT'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptAssignment(notification['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('ACCEPT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
      appBar:AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Alert',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D5D9F),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.blue.shade100,
        toolbarHeight: kToolbarHeight + MediaQuery.of(context).padding.top + 30,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 48,
                        color: primaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active alerts',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () async {
                    setState(() => _isLoading = true);
                    _setupNotificationsListener();
                    return Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildNotificationCard(_notifications[index]),
                  ),
                ),
    );
  }
}


