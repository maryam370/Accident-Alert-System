import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> fetchResolvedAccidents() async {
    String currentUserId = _auth.currentUser!.uid;

    QuerySnapshot accidentSnapshot = await _firestore
        .collection('accidents')
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'resolved')
        .get();

    List<Map<String, dynamic>> accidentDetails = [];

    for (var doc in accidentSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      data['ambulanceName'] =
          await _getEntityName(data['assignedAmbulanceId']);
      data['hospitalName'] = await _getEntityName(data['assignedHospitalId']);
      data['policeName'] = await _getEntityName(data['assignedPoliceId']);

      accidentDetails.add(data);
    }

    return accidentDetails;
  }

  Future<String> _getEntityName(String? userId) async {
    if (userId == null || userId.isEmpty) return "Not Assigned";
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      
      body: FutureBuilder(
        future: fetchResolvedAccidents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return const Center(
              child: Text(
                'No resolved accidents found.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          List accidents = snapshot.data as List;

          return ListView.builder(
            itemCount: accidents.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final accident = accidents[index];
              final timestamp = accident['timestamp'] as Timestamp;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "Resolved Accident",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(thickness: 1, height: 20),
                      InfoRow(icon: Icons.local_hospital, label: "Hospital", value: accident['hospitalName']),
                      InfoRow(icon: Icons.local_police, label: "Police", value: accident['policeName']),
                      InfoRow(icon: Icons.local_taxi, label: "Ambulance", value: accident['ambulanceName']),
                      InfoRow(icon: Icons.access_time, label: "Time", value: formatTimestamp(timestamp)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
