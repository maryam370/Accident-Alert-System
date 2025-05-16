import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class AlertPage extends StatefulWidget {
  @override
  _AlertPageState createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _ambulances = [];
  List<Map<String, dynamic>> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _fetchResponders();
      _setupCasesListener();
      await _setupFCMNotifications();
    } catch (e) {
      print('Initialization error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchResponders() async {
    final ambulanceSnap = await _firestore.collection('ambulance_info').get();
    final hospitalSnap = await _firestore.collection('hospital_info').get();

    setState(() {
      _ambulances = ambulanceSnap.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      _hospitals = hospitalSnap.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    });
  }

  void _setupCasesListener() {
    _firestore.collection('accidents')
      .where('status', isNotEqualTo: 'resolved')
      .snapshots()
      .listen((snapshot) async {
        List<Map<String, dynamic>> casesWithDetails = [];

        for (var doc in snapshot.docs) {
          var caseData = doc.data();
          caseData['id'] = doc.id;

          if (caseData['assignedAmbulanceId'] != null && caseData['assignedAmbulanceId'].toString().isNotEmpty) {
  var ambulanceDoc = await _firestore.collection('ambulance_info')
    .doc(caseData['assignedAmbulanceId']).get();
  caseData['assignedAmbulance'] = ambulanceDoc.data();
}

          // Get hospital details if assigned
          if (caseData['assignedHospitalId'] != null && caseData['assignedHospitalId'].toString().isNotEmpty) {
  var hospitalDoc = await _firestore.collection('hospital_info')
    .doc(caseData['assignedHospitalId']).get();
  caseData['assignedHospital'] = hospitalDoc.data();
}

          casesWithDetails.add(caseData);
        }

        setState(() {
          _cases = casesWithDetails;
          _isLoading = false;
        });
      });
  }

  Future<void> _setupFCMNotifications() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          print('New alert: ${message.notification!.title}');
        }
      });
    }
  }

  Future<void> _updateCaseAssignment(
      String caseId, String field, String? responderId) async {
    if (responderId == null) return;
    try {
      await _firestore.collection('accidents').doc(caseId).update({
        field: responderId,
        //'status': 'assigned', // Update status when assigning
      });
      print('$field updated for case $caseId');
    } catch (e) {
      print('Error updating $field: $e');
    }
  }
 Future<void> _openMap(String lat, String lon) async {
  final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");

  try {
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication, // <-- Add this!
      );
    } else {
      throw 'Could not launch map URL';
    }
  } catch (e) {
    print("Error launching map: $e");
  }
}

Widget _buildCaseCard(Map<String, dynamic> caseData) {
  Timestamp timestamp = caseData['timestamp'];
  DateTime date = timestamp.toDate();
  String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(date);
  final Color primaryColor = const Color(0xFF085899);
  final Color secondaryColor = Colors.grey.shade700;

  return Card(
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200, width: 1),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Case #${caseData['id'].substring(0, 8)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              
            ],
          ),
          const SizedBox(height: 16),

          // Location Section
          if (caseData['location'] != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                 onPressed: () async {
  final location = caseData['location'];
  final lat = location['latitude'].toString();
  final lon = location['longitude'].toString();
  await _openMap(lat, lon);
},

                  icon: Icon(Icons.map_outlined, size: 18, color: primaryColor),
                  label: Text(
                    'View on Map',
                    style: TextStyle(color: primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ],

          // Time Section
          Row(
            children: [
              Icon(Icons.access_time, size: 18, color: secondaryColor),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(color: secondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Assigned Responders Section
          if (caseData['assignedAmbulance'] != null) ...[
            _buildResponderCard(
              icon: Icons.medical_services,
              title: 'Assigned Ambulance',
              name: caseData['assignedAmbulance']['name'],
              phone: caseData['assignedAmbulance']['phoneNumber'],
              color: primaryColor,
            ),
            const SizedBox(height: 12),
          ],

          if (caseData['assignedHospital'] != null) ...[
            _buildResponderCard(
              icon: Icons.local_hospital,
              title: 'Assigned Hospital',
              name: caseData['assignedHospital']['name'],
              phone: caseData['assignedHospital']['phoneNumber'],
              color: primaryColor,
            ),
            const SizedBox(height: 12),
          ],

          // Assignment Dropdowns
          _buildAssignmentDropdown(
            label: 'Assign Ambulance',
            value: caseData['assignedAmbulanceId'],
            items: _ambulances,
            onChanged: (value) => _updateCaseAssignment(
              caseData['id'], 'assignedAmbulanceId', value),
          ),
          const SizedBox(height: 12),

          _buildAssignmentDropdown(
            label: 'Assign Hospital',
            value: caseData['assignedHospitalId'],
            items: _hospitals,
            onChanged: (value) => _updateCaseAssignment(
              caseData['id'], 'assignedHospitalId', value),
          ),
        ],
      ),
    ),
  );
}

Widget _buildResponderCard({
  required IconData icon,
  required String title,
  required String name,
  required String phone,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: color.withOpacity(0.15),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Container
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        
        // Information Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              
              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              
              // Phone
              Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    phone,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildAssignmentDropdown({
  required String label,
  required String? value,
  required List<Map<String, dynamic>> items,
  required Function(String?) onChanged,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF585858), // Slightly dark grey for label
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners for a modern feel
          borderSide: const BorderSide(color: Color(0xFF085899), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF085899), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF085899), width: 2),
        ),
      ),
      isExpanded: true,
      value: items.any((item) => item['id'] == value) ? value : null,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Select $label',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
        ...items.map((item) {
          return DropdownMenuItem<String>(
            value: item['id'],
            child: Text(
              '${item['name']} (${item['phoneNumber']})',
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ],
      onChanged: onChanged,
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Emergency Aler',
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
          ? Center(child: CircularProgressIndicator())
          : _cases.isEmpty
              ? Center(child: Text("No active emergency cases"))
              : RefreshIndicator(
                  onRefresh: _initializeData,
                  child: ListView.builder(
                    itemCount: _cases.length,
                    itemBuilder: (context, index) {
                      return _buildCaseCard(_cases[index]);
                    },
                  ),
                ),
    );
  }
}