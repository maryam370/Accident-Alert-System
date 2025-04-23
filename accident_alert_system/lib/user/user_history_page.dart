import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _controller;
  List<Map<String, dynamic>> _accidents = [];
  bool _isLoading = true;

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    String currentUserId = _auth.currentUser!.uid;

    QuerySnapshot accidentSnapshot = await _firestore
        .collection('accidents')
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'resolved')
        .get();

    List<Map<String, dynamic>> accidentDetails = [];

    for (var doc in accidentSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      data['ambulanceName'] = await _getEntityName(data['assignedAmbulanceId']);
      data['hospitalName'] = await _getEntityName(data['assignedHospitalId']);
      data['policeName'] = await _getEntityName(data['assignedPoliceId']);

      accidentDetails.add(data);
    }

    setState(() {
      _accidents = accidentDetails;
      _isLoading = false;
    });
  }

  Future<String> _getEntityName(String? userId) async {
    if (userId == null || userId.isEmpty) return "Not Assigned";
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.get('name') ?? "Unknown";
      }
    } catch (e) {
      print("Error fetching user name: $e");
    }
    return "Unknown";
  }

  String formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat.yMMMEd().add_jm().format(date);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _controller.forward();
    _fetchData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const SizedBox(height: 6),
            const Text(
              'History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'View your past resolved incidents and their assigned responders.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4361EE)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: Color(0xFF4361EE),
              child: _accidents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No resolved accidents found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
                      itemCount: _accidents.length,
                      itemBuilder: (context, index) {
                        final accident = _accidents[index];
                        final timestamp = accident['timestamp'] as Timestamp;

                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _controller.value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - _controller.value)),
                                child: child,
                              ),
                            );
                          },
                          child: Card(
                            color: Color(0xFFEAF1FF), // Soft blue card background
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF4361EE).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF4361EE),
                                            size: 24,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Resolved Incident",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2E3B4E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Divider(height: 1, color: Colors.grey[200]),
                                    SizedBox(height: 12),
                                    InfoRow(
                                      icon: Icons.local_hospital,
                                      label: "Hospital",
                                      value: accident['hospitalName'],
                                      color: Color(0xFF4361EE),
                                    ),
                                    InfoRow(
                                      icon: Icons.local_police,
                                      label: "Police",
                                      value: accident['policeName'],
                                      color: Color(0xFF3A0CA3),
                                    ),
                                    InfoRow(
                                      icon: Icons.medical_services,
                                      label: "Ambulance",
                                      value: accident['ambulanceName'],
                                      color: Color(0xFF4CC9F0),
                                    ),
                                    InfoRow(
                                      icon: Icons.access_time,
                                      label: "Time",
                                      value: formatTimestamp(timestamp),
                                      color: Colors.grey[600]!,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
