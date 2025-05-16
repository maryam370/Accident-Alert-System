import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class StatusPage extends StatefulWidget {
  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final Color _primaryBlue = const Color(0xFF0D5D9F);
  final Color _cardColor = const Color(0xFFE6F2FF);
  final Color _warningColor = Colors.orange;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? _assignment;
  Map<String, dynamic>? _victimInfo;
  String _currentStatus = 'en_route';
  bool _isLoading = true;
  bool _noAssignment = false;

  final List<String> _statusOptions = [
    'en_route',
    'arrived',
    'transporting',
    'arrived_at_hospital',
    'completed'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentAssignment();
  }

  Future<void> _loadCurrentAssignment() async {
    setState(() {
      _isLoading = true;
      _noAssignment = false;
    });

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _noAssignment = true;
      });
      return;
    }

    try {
      // Check ambulance_info first for current assignment
      final ambulanceDoc =
          await _firestore.collection('ambulance_info').doc(userId).get();

      if (!ambulanceDoc.exists ||
          ambulanceDoc.data()?['currentAssignment'] == null) {
        setState(() {
          _isLoading = false;
          _noAssignment = true;
        });
        return;
      }

      final assignmentId = ambulanceDoc.data()?['currentAssignment'];

      // Verify this is an accepted assignment
      final recipientQuery = await _firestore
          .collection('notification_recipients')
          .where('notificationId', isEqualTo: assignmentId)
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .limit(1)
          .get();

      if (recipientQuery.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _noAssignment = true;
        });
        return;
      }

      // Load the full assignment details
      await _loadAssignmentDetails(assignmentId);
    } catch (e) {
      print('Error loading assignment: $e');
      setState(() {
        _isLoading = false;
        _noAssignment = true;
      });
    }
  }

  Future<void> _loadAssignmentDetails(String assignmentId) async {
    try {
      // Get notification details
      final notification =
          await _firestore.collection('notifications').doc(assignmentId).get();
      if (!notification.exists) throw Exception('Notification not found');

      // Get accident details
      final accidentId = notification['accidentId'];
      final accident =
          await _firestore.collection('accidents').doc(accidentId).get();
      if (!accident.exists) throw Exception('Accident not found');

      // Get victim info
      final victimId = accident['userId'];
      final victim =
          await _firestore.collection('user_info').doc(victimId).get();

      setState(() {
        _assignment = {
          'id': assignmentId,
          'accidentId': accidentId,
          ...notification.data()!,
          'accidentData': accident.data(),
        };
        _victimInfo = victim.data();
        _currentStatus = accident['status'] ?? 'en_route';
        _isLoading = false;
        _noAssignment = false;
      });
    } catch (e) {
      print('Error loading assignment details: $e');
      setState(() {
        _isLoading = false;
        _noAssignment = true;
      });
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_assignment == null) return;

    setState(() => _isLoading = true);
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final docId = '${_assignment!['accidentId']}_$userId';

await _firestore.collection('statusUpdates').doc(docId).set({
  'accidentId': _assignment!['accidentId'],
  'responderId': userId,
  'updateType': newStatus,
  'timestamp': FieldValue.serverTimestamp(),
});


      // If completed, clear ambulance assignment
      if (newStatus == 'completed') {
        await _firestore.collection('ambulance_info').doc(userId).update({
          'availability': true,
          'currentAssignment': FieldValue.delete(),
        });

        // Update notification recipient status
        await _firestore
            .collection('notification_recipients')
            .where('notificationId', isEqualTo: _assignment!['id'])
            .where('recipientId', isEqualTo: userId)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.update({'status': 'completed'});
          }
        });
      }

      setState(() {
        _currentStatus = newStatus;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status updated to ${_getStatusDisplay(newStatus)}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update status: $e',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  String _getStatusDisplay(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildStatusButton(String status) {
    final statusIndex = _statusOptions.indexOf(status);
    final currentIndex = _statusOptions.indexOf(_currentStatus);

    bool isCurrent = _currentStatus == status;
    bool isNext = statusIndex == currentIndex + 1;
    bool isAvailable = isCurrent || isNext;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(
        onPressed:
            isAvailable && !_isLoading ? () => _updateStatus(status) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrent
              ? Colors.blue
              : (isAvailable ? Colors.green : Colors.grey),
          minimumSize: Size(double.infinity, 50),
        ),
        child: _isLoading && isAvailable
            ? CircularProgressIndicator(color: Colors.white)
            : Text(_getStatusDisplay(status)),
      ),
    );
  }

  Widget _buildVictimInfo() {
    if (_victimInfo == null) return SizedBox();

    final medical = _victimInfo!['medicalRecords'] ?? {};
    final emergencyContact = medical['emergencyContact'] ?? {};

    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('VICTIM INFORMATION',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            Divider(),
            Text('Name: ${_victimInfo!['name'] ?? 'Unknown'}'),
            SizedBox(height: 8),
            Text('Phone: ${_victimInfo!['phoneNumber'] ?? 'Unknown'}'),
            if (medical['bloodGroup'] != null) ...[
              SizedBox(height: 8),
              Text('Blood Type: ${medical['bloodGroup']}'),
            ],
            if (medical['allergies']?.isNotEmpty ?? false) ...[
              SizedBox(height: 8),
              Text('Allergies: ${medical['allergies'].join(', ')}'),
            ],
            SizedBox(height: 16),
            Text('EMERGENCY CONTACT',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            Divider(),
            if (emergencyContact['name'] != null)
              Text('Name: ${emergencyContact['name']}'),
            if (emergencyContact['relation'] != null) ...[
              SizedBox(height: 8),
              Text('Relation: ${emergencyContact['relation']}'),
            ],
            if (emergencyContact['number'] != null) ...[
              SizedBox(height: 8),
              Text('Phone: ${emergencyContact['number']}'),
            ],
          ],
        ),
      ),
    );
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

  Widget _buildAssignmentInfo() {
  if (_assignment == null) return SizedBox();

  final accident = _assignment!['accidentData'];
  final timestamp = accident['timestamp']?.toDate();

  return Card(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 3,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCIDENT DETAILS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.redAccent,
              letterSpacing: 0.5,
            ),
          ),
          Divider(color: Colors.grey.shade400, thickness: 1),
          if (accident['location'] != null) ...[

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
  final location = accident['location'];
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
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Color(0xFF085899)),
              SizedBox(width: 6),
              Text(
                'Current Status: ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF085899), // ✅ Correct

                ),
              ),
              Expanded(
                child: Text(
                  _getStatusDisplay(_currentStatus),
                  style: TextStyle(
                    color: Color(0xFF085899),
                    fontWeight: FontWeight.w900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
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
                'Accident Status',
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
          : _noAssignment || _assignment == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment, size: 80, color: Colors.grey[400]),
                      SizedBox(height: 20),
                      Text(
                        'No Active Assignments',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadCurrentAssignment,
                        icon: Icon(Icons.refresh),
                        label: Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionCard(
                          "Assignment Info", _buildAssignmentInfo()),
                      SizedBox(height: 16),
                      _buildSectionCard("Victim Info", _buildVictimInfo()),
                      SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Update Status',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            _statusOptions.map(_buildStatusButton).toList(),
                      ),
                    ],
                  ),
                ),
    );
  }

// Helper for reusable card styling
  Widget _buildSectionCard(String title, Widget content) {
    return Card(
      color: Colors.blue[50],
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}
