import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final Color primaryColor = const Color(0xFF0D5D9F);
  final Color cardColor = const Color(0xFFE6F2FF);
  final Color accentColor = const Color(0xFF4A90E2);
  final Color textColor = const Color(0xFF333333);

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
        content: Text(message.notification?.body ?? 'A new accident occurred.'),
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
          .orderBy('timestamp', descending: true);

      if (_selectedDate != null) {
        final startOfDay = DateTime(
            _selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

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
              'status': caseData['status'],
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
      _isLoading = true;
    });
    _setupCasesListener();
  }
  Future<void> _openMap(String lat, String lon) async {
  try {
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      throw 'Could not launch map URL';
    }
  } catch (e) {
    print("Error launching map: $e");
  }
}


  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final victim = caseData['victim'];
    final ambulance = caseData['ambulance'];
    final hospital = caseData['hospital'];
    final location = caseData['location'];
    final status = caseData['status'] ?? 'Pending';

    Color statusColor = status == 'resolved'
        ? Colors.green
        : status == 'In Progress'
            ? Colors.orange
            : Colors.red;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Add case details navigation if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with case ID and timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Case #${caseData['id'].substring(0, 6).toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy - hh:mm a')
                        .format(caseData['timestamp']),
                    style: TextStyle(
                      color: primaryColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Victim Information
              if (victim != null) ...[
                _buildInfoSection(
                  icon: Icons.person_outline,
                  title: 'Victim',
                  items: [
                    _buildInfoItem('Name', victim['name']),
                    if (victim['phoneNumber'] != null)
                      _buildInfoItem('Phone', victim['phoneNumber']),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Location Information
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
      final lat = location['latitude'].toString();
      final lon = location['longitude'].toString();
      await _openMap(lat, lon);
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

              // Ambulance Information
              if (ambulance != null) ...[
                _buildInfoSection(
                  icon: Icons.medical_services_outlined,
                  title: 'Ambulance',
                  items: [
                    _buildInfoItem('Driver', ambulance['name']),
                    _buildInfoItem('Contact', ambulance['phoneNumber']),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Hospital Information
              if (hospital != null) ...[
                _buildInfoSection(
                  icon: Icons.local_hospital_outlined,
                  title: 'Hospital',
                  items: [
                    _buildInfoItem('Name', hospital['name']),
                    _buildInfoItem('Contact', hospital['phoneNumber']),
                  ],
                ),
              ],
            ],
          ),
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
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(width: 8),
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
            width: 80,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:  AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Cases',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D5D9F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View all incidents',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0D5D9F).withOpacity(0.8),
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
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: Icon(Icons.calendar_today, size: 18, color: primaryColor),
                    label: Text(
                      _selectedDate == null
                          ? 'Filter by Date'
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      style: TextStyle(color: primaryColor),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showAssignedCases,
                    label: const Text(
                      'all cases',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Cases List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  )
                : _allCases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 48,
                              color: primaryColor.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No cases found',
                              style: TextStyle(
                                color: primaryColor.withOpacity(0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_selectedDate != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedDate = null;
                                    _isLoading = true;
                                  });
                                  _setupCasesListener();
                                },
                                child: Text(
                                  'Clear date filter',
                                  style: TextStyle(color: primaryColor),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: () async {
                          setState(() {
                            _isLoading = true;
                          });
                          _setupCasesListener();
                          return Future.delayed(const Duration(seconds: 1));
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _allCases.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _buildCaseCard(_allCases[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}