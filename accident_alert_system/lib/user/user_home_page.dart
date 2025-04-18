import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHomePage extends StatefulWidget {
  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {


  // Navigation bar state
  int _currentIndex = 0; // Tracks the current page index

  // Pages for navigation
  final List<Widget> _pages = [
    HomePage(),
    HistoryPage(), // Home page (UserHomePage content)
    SettingsPage(), // Reports page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('user Home Page'),
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
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isMonitoring = true;
  double _acceleration = 2.5;
  bool _showEmergencyPopup = false;
  int _countdown = 30;

  void _simulateAccident() {
    setState(() {
      _acceleration = 9.8;
      _showEmergencyPopup = true;
      _startCountdown();
    });
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_countdown > 0 && _showEmergencyPopup) {
        setState(() => _countdown--);
        _startCountdown();
      } else if (_countdown == 0) {
        _simulateEmergencySent();
      }
    });
  }

  void _cancelAlert() {
    setState(() {
      _showEmergencyPopup = false;
      _countdown = 30;
      _acceleration = 2.5;
    });
  }

  void _simulateEmergencySent() {
    setState(() {
      _showEmergencyPopup = false;
      _countdown = 30;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency alert sent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RescueAlert'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emergency, color: Colors.red),
            onPressed: _simulateAccident,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(
                          _isMonitoring ? Icons.check_circle : Icons.error,
                          color: _isMonitoring ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isMonitoring ? 'Monitoring Active' : 'Monitoring Paused',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isMonitoring ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Current Sensor Data:', style: TextStyle(fontSize: 16)),
                Text(
                  'Impact: ${_acceleration.toStringAsFixed(1)}G',
                  style: TextStyle(
                    fontSize: 24,
                    color: _acceleration > 5.0 ? Colors.red : Colors.black,
                  ),
                ),
                Text(
                  _acceleration > 5.0 ? '🚨 Possible Accident!' : 'Normal',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                const Text('Your Location:', style: TextStyle(fontSize: 16)),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 50, color: Colors.blue),
                        Text('GPS: 12.34, 56.78'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Emergency Popup (Conditional)
          _showEmergencyPopup
              ? AlertDialog(
                  backgroundColor: Colors.red[50],
                  title: const Text('🚨 ACCIDENT DETECTED!', style: TextStyle(color: Colors.red)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Cancel if this is a mistake. Help will be alerted in:'),
                      const SizedBox(height: 10),
                      Text(
                        '$_countdown seconds',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: _cancelAlert,
                      child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: _simulateEmergencySent,
                      child: const Text('CONFIRM EMERGENCY'),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Medical'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: 0,
        onTap: (index) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigating to ${['Home', 'Medical', 'History', 'Settings'][index]}')),
          );
        },
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('history Page'),
    );
  }
}







class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Reports Page'),
    );
  }
}
