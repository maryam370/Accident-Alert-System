import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class StatusPage extends StatefulWidget {
  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
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
      final ambulanceDoc = await _firestore.collection('ambulance_info').doc(userId).get();
      
      if (!ambulanceDoc.exists || ambulanceDoc.data()?['currentAssignment'] == null) {
        setState(() {
          _isLoading = false;
          _noAssignment = true;
        });
        return;
      }

      final assignmentId = ambulanceDoc.data()?['currentAssignment'];
      
      // Verify this is an accepted assignment
      final recipientQuery = await _firestore.collection('notification_recipients')
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
      final notification = await _firestore.collection('notifications').doc(assignmentId).get();
      if (!notification.exists) throw Exception('Notification not found');

      // Get accident details
      final accidentId = notification['accidentId'];
      final accident = await _firestore.collection('accidents').doc(accidentId).get();
      if (!accident.exists) throw Exception('Accident not found');

      // Get victim info
      final victimId = accident['userId'];
      final victim = await _firestore.collection('user_info').doc(victimId).get();

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
      // First create the status update record
      await _firestore.collection('statusUpdates').add({
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
        await _firestore.collection('notification_recipients')
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
        SnackBar(content: Text('Status updated to ${_getStatusDisplay(newStatus)}')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
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
        onPressed: isAvailable && !_isLoading ? () => _updateStatus(status) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isCurrent ? Colors.blue : (isAvailable ? Colors.green : Colors.grey),
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
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

  Widget _buildAssignmentInfo() {
    if (_assignment == null) return SizedBox();

    final accident = _assignment!['accidentData'];
    final timestamp = accident['timestamp']?.toDate();

    return Card(
      margin: EdgeInsets.all(12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACCIDENT DETAILS', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            Divider(),
            Text('Location: ${accident['location'] ?? 'Unknown'}'),
            if (timestamp != null) ...[
              SizedBox(height: 8),
              Text('Time: ${DateFormat('MMM d, y - h:mm a').format(timestamp)}'),
            ],
            SizedBox(height: 8),
            Text('Current Status: ${_getStatusDisplay(_currentStatus)}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Accident Status"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadCurrentAssignment,
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
                      Icon(Icons.assignment, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No active assignments'),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadCurrentAssignment,
                        child: Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _buildAssignmentInfo(),
                      SizedBox(height: 16),
                      _buildVictimInfo(),
                      SizedBox(height: 24),
                      Text(
                        'UPDATE STATUS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      ..._statusOptions.map(_buildStatusButton),
                    ],
                  ),
                ),
    );
  }
}