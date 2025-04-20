import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyNumberController;
  late TextEditingController _emergencyRelationController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _allergiesController;
  bool _monitoringEnabled = true;
  bool _locationEnabled = true;
  DateTime? _dateOfBirth;
  List<String> _allergies = [];

  // Section visibility toggles
  bool _showPersonalInfo = false;
  bool _showMedicalInfo = false;
  bool _showEmergencyContact = false;
  bool _showAppSettings = true;
  bool _showAbout = false;

  @override
  void initState() {
    super.initState();
    _emergencyNameController = TextEditingController();
    _emergencyNumberController = TextEditingController();
    _emergencyRelationController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _allergiesController = TextEditingController();
    _loadUserSettings();
  }

  Future<void> _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('user_info')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _phoneNumberController.text = data['phoneNumber'] ?? '';
        _bloodGroupController.text = data['medicalRecords']?['bloodGroup'] ?? '';
        _emergencyNameController.text = 
            data['medicalRecords']?['emergencyContact']?['name'] ?? '';
        _emergencyNumberController.text = 
            data['medicalRecords']?['emergencyContact']?['number'] ?? '';
        _emergencyRelationController.text = 
            data['medicalRecords']?['emergencyContact']?['relation'] ?? '';
        _dateOfBirth = data['dateOfBirth']?.toDate();
        _allergies = List<String>.from(data['medicalRecords']?['allergies'] ?? []);
        _allergiesController.text = _allergies.join(', ');
        
        _loadAppSettings(user.uid);
      });
    }
  }

  Future<void> _loadAppSettings(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _monitoringEnabled = data['settings']?['monitoringEnabled'] ?? true;
        _locationEnabled = data['settings']?['locationEnabled'] ?? true;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
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
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Personal Information Section
              _buildSectionHeader(
                title: 'Personal Information',
                icon: Icons.person,
                isExpanded: _showPersonalInfo,
                onTap: () =>
                    setState(() => _showPersonalInfo = !_showPersonalInfo),
              ),
              if (_showPersonalInfo) ...[
                SizedBox(height: 8),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dateOfBirth == null
                          ? 'Select Date'
                          : DateFormat('MMM dd, yyyy').format(_dateOfBirth!),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Medical Information Section
              _buildSectionHeader(
                title: 'Medical Information',
                icon: Icons.medical_services,
                isExpanded: _showMedicalInfo,
                onTap: () => setState(() => _showMedicalInfo = !_showMedicalInfo),
              ),
              if (_showMedicalInfo) ...[
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _bloodGroupController.text.isNotEmpty ? _bloodGroupController.text : null,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bloodtype),
                  ),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((bloodType) => DropdownMenuItem(
                            value: bloodType,
                            child: Text(bloodType),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _bloodGroupController.text = value!),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _allergiesController,
                  decoration: InputDecoration(
                    labelText: 'Allergies (comma separated)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.health_and_safety),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        if (_allergiesController.text.isNotEmpty) {
                          setState(() {
                            _allergies.add(_allergiesController.text.trim());
                            _allergiesController.clear();
                          });
                        }
                      },
                    ),
                  ),
                  onChanged: (value) {
                    if (value.endsWith(',')) {
                      setState(() {
                        _allergies.add(value.replaceAll(',', '').trim());
                        _allergiesController.clear();
                      });
                    }
                  },
                ),
                SizedBox(height: 8),
                if (_allergies.isNotEmpty) ...[
                  Text('Current Allergies:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _allergies.map((allergy) => Chip(
                      label: Text(allergy),
                      deleteIcon: Icon(Icons.close, size: 18),
                      onDeleted: () => setState(() => _allergies.remove(allergy)),
                    )).toList(),
                  ),
                  SizedBox(height: 16),
                ],
              ],

              // Emergency Contact Section
              _buildSectionHeader(
                title: 'Emergency Contact',
                icon: Icons.emergency,
                isExpanded: _showEmergencyContact,
                onTap: () => setState(
                    () => _showEmergencyContact = !_showEmergencyContact),
              ),
              if (_showEmergencyContact) ...[
                SizedBox(height: 8),
                TextFormField(
                  controller: _emergencyNameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emergencyNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emergencyRelationController,
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
              ],

              // App Settings Section (always visible)
              _buildSectionHeader(
                title: 'App Settings',
                icon: Icons.settings,
                isExpanded: _showAppSettings,
                onTap: () =>
                    setState(() => _showAppSettings = !_showAppSettings),
              ),
              if (_showAppSettings) ...[
                SizedBox(height: 8),
                SwitchListTile(
                  title: Text('Enable Accident Monitoring'),
                  value: _monitoringEnabled,
                  onChanged: (value) =>
                      setState(() => _monitoringEnabled = value),
                ),
                SwitchListTile(
                  title: Text('Enable Location Sharing'),
                  value: _locationEnabled,
                  onChanged: (value) =>
                      setState(() => _locationEnabled = value),
                ),
                SizedBox(height: 16),
              ],

              // About Section
              _buildSectionHeader(
                title: 'About',
                icon: Icons.info,
                isExpanded: _showAbout,
                onTap: () => setState(() => _showAbout = !_showAbout),
              ),
              if (_showAbout) ...[
                SizedBox(height: 8),
                _buildAboutCard(),
                SizedBox(height: 16),
              ],

              // Save Button
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: Colors.blueAccent,
                ),
                child:
                    Text('SAVE CHANGES', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      leading: Icon(icon, color: Colors.blueAccent),
      trailing: Icon(
        isExpanded ? Icons.expand_less : Icons.expand_more,
        color: Colors.blueAccent,
      ),
      onTap: onTap,
    );
  }

  Widget _buildAboutCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Accident Alert System',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Version: 1.0.0', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('Developed by: our Team ',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            Text('Contact: support@accidentalertsystem.com',
                style: TextStyle(color: Colors.blueAccent)),
            SizedBox(height: 8),
            Text('© 2025 All Rights Reserved',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update user_info collection
      await FirebaseFirestore.instance
          .collection('user_info')
          .doc(user.uid)
          .update({
            'phoneNumber': _phoneNumberController.text,
            'dateOfBirth': _dateOfBirth,
            'medicalRecords': {
              'bloodGroup': _bloodGroupController.text,
              'allergies': _allergies,
              'emergencyContact': {
                'name': _emergencyNameController.text,
                'number': _emergencyNumberController.text,
                'relation': _emergencyRelationController.text,
              }
            }
          });

      // Update settings in users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'settings': {
              'monitoringEnabled': _monitoringEnabled,
              'locationEnabled': _locationEnabled,
            }
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ));
    }
  }

  @override
 void dispose() {
    _emergencyNameController.dispose();
    _emergencyNumberController.dispose();
    _emergencyRelationController.dispose();
    _phoneNumberController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }
}
