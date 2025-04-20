import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emergencyContactController;
  late TextEditingController _bloodGroupController;
  bool _monitoringEnabled = true;
  bool _locationEnabled = true;

  @override
  void initState() {
    super.initState();
    _emergencyContactController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _emergencyContactController.text = data['medicalRecords']?['EmergencyContact']?['Number'] ?? '';
        _bloodGroupController.text = data['medicalRecords']?['BloodGroup'] ?? '';
        _monitoringEnabled = data['settings']?['monitoringEnabled'] ?? true;
        _locationEnabled = data['settings']?['locationEnabled'] ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🩺 Update Medical Info',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bloodGroupController,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Enter blood group' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty ?? true ? 'Enter contact number' : null,
              ),
              const SizedBox(height: 30),
              const Text('⚙️ App Settings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Enable Accident Monitoring'),
                value: _monitoringEnabled,
                activeColor: Colors.teal,
                onChanged: (value) => setState(() => _monitoringEnabled = value),
              ),
              SwitchListTile(
                title: const Text('Enable Location Sharing'),
                value: _locationEnabled,
                activeColor: Colors.teal,
                onChanged: (value) => setState(() => _locationEnabled = value),
              ),
              const SizedBox(height: 30),
              const Text('ℹ️ About',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                color: Colors.teal.shade50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Accident Alert System'),
                  subtitle: const Text('Version 1.0.0\nDeveloped by Your Team'),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('SAVE SETTINGS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'medicalRecords': {
        'BloodGroup': _bloodGroupController.text,
        'EmergencyContact': {
          'Number': _emergencyContactController.text,
        }
      },
      'settings': {
        'monitoringEnabled': _monitoringEnabled,
        'locationEnabled': _locationEnabled,
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Settings saved successfully')));
  }

  @override
  void dispose() {
    _emergencyContactController.dispose();
    _bloodGroupController.dispose();
    super.dispose();
  }
}
