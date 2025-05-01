import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class PoliceHomePage extends StatefulWidget {
  @override
  _PoliceHomePageState createState() => _PoliceHomePageState();
}

class _PoliceHomePageState extends State<PoliceHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _allCases = [];
  bool _isLoading = true;
  DateTime? _selectedDate;
  StreamSubscription<QuerySnapshot>? _casesSubscription;
  String? _policeId; // Store the police officer's ID

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
      _policeId = _auth.currentUser?.uid; // Fetch the logged-in police officer's ID
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
        await _firestore.collection('police_info').doc(userId).update({'fcmToken': token});
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
        content: Text(message.notification?.body ?? 'You have received a new case.'),
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

      Query casesQuery = _firestore.collection('accidents').orderBy('timestamp', descending: true);

      if (_selectedDate != null) {
        final startOfDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        final endOfDay = startOfDay.add(Duration(days: 1));

        casesQuery = casesQuery
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
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
              final victimDoc = await _firestore.collection('user_info').doc(victimId).get();
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

  // Toggle the assigned cases filter when the button is pressed
  void _showAssignedCases() {
    setState(() {
      _isLoading = true;
    });
    _setupCasesListener();
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final victim = caseData['victim'];
    final ambulance = caseData['ambulance'];
    final hospital = caseData['hospital'];
    final location = caseData['location'];
    final status = caseData['status'] ?? 'Pending'; // Default to 'Pending' if null

    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Case ID and Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CASE #${caseData['id'].substring(0, 6).toUpperCase()}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(caseData['timestamp']),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Status Section
            Row(
              children: [
                Text('Status: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                Text(status,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == 'Resolved'
                            ? Colors.green
                            : status == 'In Progress'
                                ? Colors.orange
                                : Colors.red)),
              ],
            ),
            SizedBox(height: 12),

            // Victim Information
            if (victim != null) ...[
              Text('VICTIM INFORMATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Divider(),
              Text('Name: ${victim['name'] ?? 'Unknown'}'),
              if (victim['phoneNumber'] != null) Text('Phone: ${victim['phoneNumber']}'),
              SizedBox(height: 8),
            ],

            // Location
            if (location != null) ...[
              Text('LOCATION', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Divider(),
              Text('Latitude: ${location['latitude']}'),
              Text('Longitude: ${location['longitude']}'),
              SizedBox(height: 8),
            ],

            // Ambulance
            if (ambulance != null) ...[
              Text('AMBULANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Divider(),
              Text('Driver: ${ambulance['name'] ?? 'Unknown'}'),
              Text('Phone: ${ambulance['phoneNumber'] ?? 'N/A'}'),
              SizedBox(height: 8),
            ],

            // Hospital
            if (hospital != null) ...[
              Text('HOSPITAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              Divider(),
              Text('Name: ${hospital['name'] ?? 'Unknown'}'),
              Text('Phone: ${hospital['phoneNumber'] ?? 'N/A'}'),
              SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Police Dashboard'),
      ),
      body: Column(
        children: [
          // Buttons Row below the AppBar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: Text('Date'),
                ),
                ElevatedButton(
                  onPressed: _showAssignedCases,
                  child: Text('All Cases'),
                ),
              ],
            ),
          ),
          
          // Body Content (List of Cases or Loading Indicator)
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _allCases.isEmpty
                  ? Center(child: Text('No cases found.'))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _allCases.length,
                        itemBuilder: (context, index) => _buildCaseCard(_allCases[index]),
                      ),
                    ),
        ],
      ),
    );
  }
}
