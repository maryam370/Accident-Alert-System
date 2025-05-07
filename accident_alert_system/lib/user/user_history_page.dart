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

      // Fetch names from respective collections if IDs exist
      data['ambulanceName'] = data['assignedAmbulanceId'] != null 
          ? await _getAmbulanceName(data['assignedAmbulanceId']) 
          : "Not Assigned";
          
      data['hospitalName'] = data['assignedHospitalId'] != null 
          ? await _getHospitalName(data['assignedHospitalId']) 
          : "Not Assigned";
          
    

      accidentDetails.add(data);
    }

    setState(() {
      _accidents = accidentDetails;
      _isLoading = false;
    });
  }

  Future<String> _getAmbulanceName(String ambulanceId) async {
    try {
      DocumentSnapshot ambulanceDoc = await _firestore.collection('ambulance_info').doc(ambulanceId).get();
      if (ambulanceDoc.exists) {
        return ambulanceDoc.get('name') ?? "Ambulance (Unknown)";
      }
    } catch (e) {
      print("Error fetching ambulance name: $e");
    }
    return "Ambulance (Unknown)";
  }

  Future<String> _getHospitalName(String hospitalId) async {
    try {
      DocumentSnapshot hospitalDoc = await _firestore.collection('hospital_info').doc(hospitalId).get();
      if (hospitalDoc.exists) {
        return hospitalDoc.get('name') ?? "Hospital (Unknown)";
      }
    } catch (e) {
      print("Error fetching hospital name: $e");
    }
    return "Hospital (Unknown)";
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
      backgroundColor: Colors.grey.shade50, // Lighter background for contrast
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D5D9F),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'View your past resolved incidents',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: Colors.blue.shade800,
              child: _accidents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No resolved incidents yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your resolved incidents will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _accidents.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final accident = _accidents[index];
                        final timestamp = accident['timestamp'] as Timestamp;

                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _controller,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(_controller),
                                child: child,
                              ),
                            );
                          },
                          child: Card(
                            elevation: 0, // Remove shadow for flat design
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.lightBlue.shade50, // Light blue background
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "Resolved Incident",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.blueGrey.shade800,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          formatTimestamp(timestamp),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blueGrey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildDetailRow(
                                      Icons.local_hospital,
                                      "Hospital",
                                      accident['hospitalName'],
                                      Colors.blue.shade700,
                                    ),
                                    _buildDetailRow(
                                      Icons.medical_services,
                                      "Ambulance",
                                      accident['ambulanceName'],
                                      Colors.teal.shade700,
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

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
          ),
        ],
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