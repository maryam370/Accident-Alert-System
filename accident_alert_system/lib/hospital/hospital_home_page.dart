import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class HospitalHomePage extends StatefulWidget {
  @override
  _HospitalHomePageState createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends State<HospitalHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _activeCases = [];
  bool _isLoading = true;
  Map<String, dynamic>? _hospitalInfo;
  StreamSubscription<QuerySnapshot>? _accidentsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _accidentsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      _setupActiveCasesListener();
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
      print("Hospital FCM Token: $token");

      if (token != null) {
        final userId = _auth.currentUser?.uid;
        if (userId != null) {
          await _firestore
              .collection('hospital_info')
              .doc(userId)
              .update({'fcmToken': token});
        }
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🏥 Hospital received FCM push while in foreground');
        if (message.notification != null) {
          _showNotificationDialog(message);
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🏥 App opened from background FCM notification');
      });
    } catch (e) {
      print('FCM setup error: $e');
    }
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
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  Future<void> _loadHospitalInfo() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final doc = await _firestore
          .collection('hospital_info')
          .doc(userId)
          .get()
          .timeout(Duration(seconds: 10));

      if (doc.exists) {
        setState(() => _hospitalInfo = doc.data()!);
      } else {
        print('Hospital info not found for user $userId');
      }
    } catch (e) {
      print('Error loading hospital info: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupActiveCasesListener() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() => _isLoading = false);
        return;
      }
      print('Setting up listener for hospital ID: $userId');

      _accidentsSubscription = _firestore
          .collection('accidents')
          .where('assignedHospitalId', isEqualTo: userId)
          .where('status', isNotEqualTo: 'resolved')
          .orderBy('status') // still required because of the inequality filter
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((accidentsSnapshot) async {
        print(
            'Received snapshot with ${accidentsSnapshot.docs.length} documents');
        if (accidentsSnapshot.docs.isEmpty) {
          setState(() {
            _activeCases = [];
            _isLoading = false;
          });
          return;
        }
        List<Map<String, dynamic>> activeCases = [];
        for (var doc in accidentsSnapshot.docs) {
          try {
            final accidentData = doc.data() as Map<String, dynamic>;
            final victimId = accidentData['userId'];
            final victimDoc = await _firestore
                .collection('user_info')
                .doc(victimId)
                .get()
                .timeout(Duration(seconds: 5));
            Map<String, dynamic>? victimInfo;
            if (victimDoc.exists) {
              victimInfo = victimDoc.data() as Map<String, dynamic>;
              if (victimInfo.containsKey('medicalRecords')) {
                final medical =
                    victimInfo['medicalRecords'] as Map<String, dynamic>;
                victimInfo['bloodGroup'] = medical['bloodGroup'];
                victimInfo['emergencyContact'] = medical['emergencyContact'];
                victimInfo['allergies'] = medical['allergies'];
              }
            }
            Map<String, dynamic>? ambulanceInfo;
            if (accidentData['assignedAmbulanceId'] != null) {
              final ambulanceDoc = await _firestore
                  .collection('ambulance_info')
                  .doc(accidentData['assignedAmbulanceId'])
                  .get()
                  .timeout(Duration(seconds: 5));

              if (ambulanceDoc.exists) {
                ambulanceInfo = ambulanceDoc.data() as Map<String, dynamic>;
              }
            }

            activeCases.add({
              'id': doc.id,
              ...accidentData,
              'timestamp': (accidentData['timestamp'] as Timestamp).toDate(),
              'victim': victimInfo,
              'ambulance': ambulanceInfo,
            });
          } catch (e) {
            print('Error processing accident ${doc.id}: $e');
          }
        }

        setState(() {
          _activeCases = activeCases;
          _isLoading = false;
        });
      }, onError: (error) {
        print('Accidents stream error: $error');
        setState(() => _isLoading = false);
      });
    } catch (e) {
      print('Error setting up listener: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final victim = caseData['victim'];
    final ambulance = caseData['ambulance'];
    final emergencyContact = victim?['emergencyContact'];

    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CASE #${caseData['id'].substring(0, 6).toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Reported At: ${_formatDateTime(caseData['timestamp'])}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (victim != null) ...[
              Text(
                'PATIENT INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Divider(),
              Text('Name: ${victim['name'] ?? 'Unknown'}'),
              if (victim['bloodGroup'] != null)
                Text('Blood Type: ${victim['bloodGroup']}'),
              if (victim['allergies'] != null && victim['allergies'].isNotEmpty)
                Text('Allergies: ${victim['allergies'].join(', ')}'),
              SizedBox(height: 8),
              if (emergencyContact != null) ...[
                Text(
                  'EMERGENCY CONTACT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Divider(),
                Text('Name: ${emergencyContact['name']}'),
                Text('Relation: ${emergencyContact['relation']}'),
                Text('Phone: ${emergencyContact['number']}'),
              ],
            ],
            SizedBox(height: 12),
            if (ambulance != null) ...[
              Text(
                'AMBULANCE INFORMATION',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Divider(),
              Text('Name: ${ambulance['name']}'),
              Text('Service area: ${ambulance['serviceArea']}'),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('statusUpdates')
                    .where('accidentId', isEqualTo: caseData['id'])
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text('Status: Loading...');
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return Text('Status: Not Dispatched');
                  }

                  final statusUpdate =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  return Text(
                      'Status: ${_formatAmbulanceStatus(statusUpdate['updateType'])}');
                },
              ),
            ],
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _confirmAdmission(caseData['id']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('CONFIRM ADMISSION'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmbulanceStatus(String status) {
    switch (status) {
      case 'ambulance_assigned':
        return 'Ambulance Assigned';
      case 'en_route':
        return 'En Route to Scene';
      case 'arrived':
        return 'Arrived at Scene';
      case 'transporting':
        return 'Patient being transported';
      case 'arrived_at_hospital':
        return 'En Route to Hospital';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String _calculateETA(Timestamp timestamp) {
    final now = DateTime.now();
    final accidentTime = timestamp.toDate();
    final difference = now.difference(accidentTime);

    if (difference.inMinutes < 5) return 'Imminent';
    if (difference.inMinutes < 30) return 'Within 30 minutes';
    return 'More than 30 minutes';
  }

  Future<void> _confirmAdmission(String caseId) async {
    await _firestore.collection('accidents').doc(caseId).update({
      'status': 'resolved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      _activeCases.removeWhere((c) => c['id'] == caseId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Patient admission confirmed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hospital Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _setupActiveCasesListener(),
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
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_activeCases.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.medical_services,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No active cases assigned'),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._activeCases
                        .map((caseData) => _buildCaseCard(caseData))
                        .toList(),
                ],
              ),
            ),
    );
  }
}
