import 'package:accident_alert_system/admin/admin_users_page.dart';
import 'package:accident_alert_system/admin/admin_report_page.dart';
import 'package:accident_alert_system/admin/admin_alert_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {

  int _currentIndex = 0; // Tracks the current page index

  // Pages for navigation
  final List<Widget> _pages = [
    HomePage(),
    UsersPage(), // Home page (AdminHomePage content)
    AlertPage(), // Alerts page
    AdminReportPage(), // Reports page
  ];

 @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _pages[_currentIndex],
   bottomNavigationBar: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.blue.shade800,
        Colors.blue.shade600,
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        spreadRadius: 2,
        offset: Offset(0, -2),
      ),
    ],
  ),
  child: BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: (index) => setState(() => _currentIndex = index),
    backgroundColor: Colors.transparent,
    elevation: 0,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.white.withOpacity(0.7),
    selectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    unselectedLabelStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    type: BottomNavigationBarType.fixed,
    items: [
      BottomNavigationBarItem(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == 0 
                ? Colors.white.withOpacity(0.2) 
                : Colors.transparent,
          ),
          child: Icon(Icons.home_filled),
        ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == 1 
                ? Colors.white.withOpacity(0.2) 
                : Colors.transparent,
          ),
          child: Icon(Icons.person),
        ),
        label: 'Users',
      ),
      BottomNavigationBarItem(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == 2 
                ? Colors.white.withOpacity(0.2) 
                : Colors.transparent,
          ),
          child: Icon(Icons.warning),
        ),
        label: 'alerts',
      ),
      BottomNavigationBarItem(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == 2 
                ? Colors.white.withOpacity(0.2) 
                : Colors.transparent,
          ),
          child: Icon(Icons.report),
        ),
        label: 'reports',
      ),
    ],
  ),
),
    );
  }
}

  class HomePage extends StatelessWidget {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    // Get count of users with a given role
    Future<int> _getUserCount(String role) async {
      final querySnapshot = await _firestore.collection('users').where('role', isEqualTo: role).get();
      return querySnapshot.docs.length;
    }

    // Get total number of accidents
    Future<int> _getTotalAccidents() async {
      final querySnapshot = await _firestore.collection('accidents').get();
      return querySnapshot.docs.length;
    }

    // Get active accidents (anything not resolved)
    Future<int> _getActiveAccidents() async {
      final querySnapshot = await _firestore
          .collection('accidents')
          .where('status', isNotEqualTo: 'resolved')
          .get();
      return querySnapshot.docs.length;
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
                'Home page',
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
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildCardRow([
            _buildStatCard(
              context: context,
              icon: Icons.local_hospital,
              title: 'Hospitals',
              future: _getUserCount('Hospital'),
              color: Color(0xFF2E86DE),
            ),
            _buildStatCard(
              context: context,
              icon: Icons.local_police,
              title: 'Police',
              future: _getUserCount('Police'),
              color: Color(0xFF28B463),
            ),
          ]),
          const SizedBox(height: 20),
          _buildCardRow([
            _buildStatCard(
              context: context,
              icon: Icons.medical_services,
              title: 'Ambulance',
              future: _getUserCount('Ambulance'),
              color: Color(0xFFF39C12),
            ),
            _buildStatCard(
              context: context,
              icon: Icons.people,
              title: 'Users',
              future: _getUserCount('user'),
              color: Color(0xFF8E44AD),
            ),
          ]),
          const SizedBox(height: 20),
          _buildCardRow([
            _buildStatCard(
              context: context,
              icon: Icons.car_crash,
              title: 'Total Accidents',
              future: _getTotalAccidents(),
              color: Color(0xFFE74C3C),
            ),
            _buildStatCard(
              context: context,
              icon: Icons.warning,
              title: 'Active Accidents',
              future: _getActiveAccidents(),
              color: Color(0xFFF1C40F),
            ),
          ]),
        ],
      ),
    ),
  );
}


  Widget _buildCardRow(List<Widget> cards) {
    return Row(
      children: cards
          .map((card) => Expanded(child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: card)))
          .toList(),
    );
  }
  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Future<int> future,
    required Color color,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: FutureBuilder<int>(
          future: future,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }


    Widget _buildCard({
      required IconData icon,
      required String title,
      required int count,
      required Color color,
    }) {
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
                'Total: $count',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }
  }