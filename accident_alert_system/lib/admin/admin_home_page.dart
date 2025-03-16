import 'package:accident_alert_system/admin/admin_users_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {


  // Navigation bar state
  int _currentIndex = 0; // Tracks the current page index

  // Pages for navigation
  final List<Widget> _pages = [
    HomePage(),
    UsersPage(), // Home page (AdminHomePage content)
    AlertsPage(), // Alerts page
    ReportsPage(), // Reports page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home Page'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login'); // Adjust the route accordingly
            },
          ),
        ],
      ),
      body: _pages[_currentIndex], // Display the current page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Highlight the current page
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the current page index
          });
        },
        type: BottomNavigationBarType.fixed, // Fixed navigation bar
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to get user count for a given role
  Future<int> _getUserCount(String role) async {
    final querySnapshot = await _firestore.collection('users').where('role', isEqualTo: role).get();
    return querySnapshot.docs.length; // Count the number of documents (users)
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Row for Hospital and Police cards
          Row(
            children: [
              Expanded(
                child: FutureBuilder<int>(
                  future: _getUserCount('Hospital'),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildCard(
                      icon: Icons.local_hospital,
                      title: 'Hospitals',
                      count: count,
                      color: Colors.blue,
                    );
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<int>(
                  future: _getUserCount('Police'),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildCard(
                      icon: Icons.local_police,
                      title: 'Police',
                      count: count,
                      color: Colors.green,
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Row for Ambulance/EMS and Users cards
          Row(
            children: [
              Expanded(
                child: FutureBuilder<int>(
                  future: _getUserCount('Ambulance'),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildCard(
                      icon: Icons.medical_services,
                      title: 'Ambulance',
                      count: count,
                      color: Colors.orange,
                    );
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<int>(
                  future: _getUserCount('Admin'),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildCard(
                      icon: Icons.people,
                      title: 'Users',
                      count: count,
                      color: Colors.purple,
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Row for Total Accidents and Active Accidents cards
          Row(
            children: [
              Expanded(
                child: _buildCard(
                  icon: Icons.car_crash,
                  title: 'Total Accidents',
                  count: 35, // Placeholder value
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCard(
                  icon: Icons.warning,
                  title: 'Active Accidents',
                  count: 5, // Placeholder value
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Method to build the individual card
  Widget _buildCard({required IconData icon, required String title, required int count, required Color color}) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Total: $count', // Display the "Total" text with the count
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}


class AlertsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Alerts Page'),
    );
  }
}

class ReportsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Reports Page'),
    );
  }
}