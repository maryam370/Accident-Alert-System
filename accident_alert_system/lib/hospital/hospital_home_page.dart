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
    final Color _primaryColor = const Color(0xFF0D5D9F); // Deep blue
  final Color _cardColor = const Color(0xFFE6F2FF); // Light blue
  final Color _accentColor = const Color(0xFF4A90E2); // Medium blue

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

      // if (token != null) {
      //   final userId = _auth.currentUser?.uid;
      //   if (userId != null) {
      //     await _firestore
      //         .collection('hospital_info')
      //         .doc(userId)
      //         .update({'fcmToken': token});
      //   }
      // }

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
      color: _cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Case Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CASE #${caseData['id'].substring(0, 6).toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(caseData['status']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatAmbulanceStatus(caseData['status']),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reported At: ${_formatDateTime(caseData['timestamp'])}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            // Patient Information
            _buildInfoSection(
              icon: Icons.person_outlined,
              title: 'PATIENT INFORMATION',
              items: [
                _buildInfoRow('Name', victim?['name'] ?? 'Unknown'),
                if (victim?['bloodGroup'] != null)
                  _buildInfoRow('Blood Type', victim!['bloodGroup']),
                if (victim?['allergies'] != null && victim!['allergies'].isNotEmpty)
                  _buildInfoRow('Allergies', victim!['allergies'].join(', ')),
              ],
            ),

            // Emergency Contact
            if (emergencyContact != null)
              _buildInfoSection(
                icon: Icons.emergency_outlined,
                title: 'EMERGENCY CONTACT',
                items: [
                  _buildInfoRow('Name', emergencyContact['name']),
                  _buildInfoRow('Relation', emergencyContact['relation']),
                  _buildInfoRow('Phone', emergencyContact['number']),
                ],
              ),

            // Ambulance Information
            if (ambulance != null)
              _buildInfoSection(
                icon: Icons.medical_services_outlined,
                title: 'AMBULANCE DETAILS',
                items: [
                  _buildInfoRow('Driver', ambulance['name']),
                  _buildInfoRow('Service Area', ambulance['serviceArea']),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('statusUpdates')
                        .where('accidentId', isEqualTo: caseData['id'])
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildInfoRow('Status', 'Loading...');
                      }
                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return _buildInfoRow('Status', 'Not Dispatched');
                      }
                      final statusUpdate = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                      return _buildInfoRow('Status', _formatAmbulanceStatus(statusUpdate['updateType']));
                    },
                  ),
                ],
              ),

            // Action Button
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => _confirmAdmission(caseData['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'CONFIRM ADMISSION',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(icon, size: 20, color: _primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const Divider(),
        ...items,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
    Color _getStatusColor(String status) {
    switch (status) {
      case 'ambulance_assigned':
        return Colors.orange;
      case 'en_route':
        return Colors.blue;
      case 'arrived':
        return Colors.green;
      case 'transporting':
        return Colors.purple;
      case 'arrived_at_hospital':
        return Colors.teal;
      default:
        return Colors.grey;
    }
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
              child: CircularProgressIndicator(color: _primaryColor),
            )
          : _activeCases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 48,
                        color: _primaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active cases assigned',
                        style: TextStyle(
                          color: _primaryColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: _primaryColor,
                  onRefresh: () async {
                    setState(() => _isLoading = true);
                    _setupActiveCasesListener();
                    return Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _activeCases.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildCaseCard(_activeCases[index]),
                  ),
                ),
    );
  }
}
