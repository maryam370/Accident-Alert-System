import 'package:flutter/material.dart';
import 'package:accident_alert_system/admin/casereport.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AdminReportPage extends StatefulWidget {
  @override
  _AdminReportPageState createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _allCases = [];
  bool _isLoading = true;
  DateTime? _selectedDate;
  StreamSubscription<QuerySnapshot>? _casesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _casesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _setupCasesListener();
      await _setupFCMNotifications();
    } catch (e) {
      print('Initialization error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setupFCMNotifications() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token = await FirebaseMessaging.instance.getToken();
      print("Police FCM Token: $token");

      final userId = _auth.currentUser?.uid;
      if (token != null && userId != null) {
        await _firestore
            .collection('police_info')
            .doc(userId)
            .update({'fcmToken': token});
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('👮 Police received FCM push in foreground');
        if (message.notification != null) {
          _showNotificationDialog(message);
          _setupCasesListener();
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('👮 App opened from background notification');
        _setupCasesListener();
      });
    } catch (e) {
      print('FCM setup error: $e');
    }
  }

  void _showNotificationDialog(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content:
            Text(message.notification?.body ?? 'You have received a new case.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setupCasesListener() {
    try {
      _casesSubscription?.cancel();
      setState(() => _isLoading = true);

      Query casesQuery = _firestore
            .collection('accidents')
  .where('status', isEqualTo: 'resolved')
  .orderBy('timestamp', descending: true);

      if (_selectedDate != null) {
        final startOfDay = DateTime(
            _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        final endOfDay = startOfDay.add(Duration(days: 1));

        casesQuery = casesQuery
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay));
      }

      _casesSubscription = casesQuery.snapshots().listen((snapshot) async {
        List<Map<String, dynamic>> caseList = [];

        for (var doc in snapshot.docs) {
          try {
            final caseData = doc.data() as Map<String, dynamic>;
            final victimId = caseData['userId'];

            Map<String, dynamic>? victimInfo;
            if (victimId != null) {
              final victimDoc =
                  await _firestore.collection('user_info').doc(victimId).get();
              if (victimDoc.exists) victimInfo = victimDoc.data();
            }

            Map<String, dynamic>? ambulanceInfo;
            if (caseData['assignedAmbulanceId'] != null) {
              final ambulanceDoc = await _firestore
                  .collection('ambulance_info')
                  .doc(caseData['assignedAmbulanceId'])
                  .get();
              if (ambulanceDoc.exists) ambulanceInfo = ambulanceDoc.data();
            }

            Map<String, dynamic>? hospitalInfo;
            if (caseData['assignedHospitalId'] != null) {
              final hospitalDoc = await _firestore
                  .collection('hospital_info')
                  .doc(caseData['assignedHospitalId'])
                  .get();
              if (hospitalDoc.exists) hospitalInfo = hospitalDoc.data();
            }

            caseList.add({
              'id': doc.id,
              ...caseData,
              'timestamp': (caseData['timestamp'] as Timestamp).toDate(),
              'status': caseData['status'], // Include this
              'victim': victimInfo,
              'ambulance': ambulanceInfo,
              'hospital': hospitalInfo,
            });
          } catch (e) {
            print('Error loading case ${doc.id}: $e');
          }
        }

        setState(() {
          _allCases = caseList;
          _isLoading = false;
        });
      }, onError: (error) {
        print('Cases stream error: $error');
        setState(() => _isLoading = false);
      });
    } catch (e) {
      print('Listener setup error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _isLoading = true;
      });
      _setupCasesListener();
    }
  }

  void _showAssignedCases() {
  setState(() {
    _selectedDate = null;  // <-- This is the missing part!
    _isLoading = true;
  });
  _setupCasesListener();
}


Widget _buildCaseCard(Map<String, dynamic> caseData) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CaseDetailPage(caseData: caseData),
        ),
      );
    },
    child: Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Case ID and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.report, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'CASE #${caseData['id'].substring(0, 6).toUpperCase()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[800],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a')
                          .format(caseData['timestamp']),
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Status
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.black),
                SizedBox(width: 6),
                Text(
                  'Status: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  caseData['status'] ?? 'Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: caseData['status'] == 'Resolved'
                        ? Colors.green
                        : caseData['status'] == 'In Progress'
                            ? Colors.orange
                            : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}



@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      title: Text(
        'Report',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D5D9F),
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 3,
      shadowColor: Colors.blue.shade50,
      toolbarHeight: kToolbarHeight + 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF0D5D9F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _selectDate(context),
                icon: Icon(Icons.calendar_today),
                label: Text('Date'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:Colors.lightBlue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAssignedCases,
                icon: Icon(Icons.list),
                label: Text('All Cases'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _allCases.isEmpty
                  ? Center(
                      child: Text(
                        'No cases found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _allCases.length,
                      itemBuilder: (context, index) =>
                          _buildCaseCard(_allCases[index]),
                    ),
        ),
      ],
    ),
  );
}

}
