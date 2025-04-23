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
  title: Text(
    'Settings',
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 22,
      color: Colors.black,
    ),
  ),
  backgroundColor: Colors.transparent,
  elevation: 0,
  centerTitle: true, // This centers the title
  actions: [
    IconButton(
      icon: Icon(Icons.logout, size: 24, color: Colors.black),
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushReplacementNamed('/login');
      },
    ),
  ],
),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personal Information Section
              _buildSectionHeader(
                title: 'Personal Information',
                icon: Icons.person_outline,
                isExpanded: _showPersonalInfo,
                onTap: () =>
                    setState(() => _showPersonalInfo = !_showPersonalInfo),
              ),
              if (_showPersonalInfo) ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                    prefixIcon: Icon(Icons.phone_outlined),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    child: Text(
                      _dateOfBirth == null
                          ? 'Select Date'
                          : DateFormat('MMM dd, yyyy').format(_dateOfBirth!),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],

              // Medical Information Section
              _buildSectionHeader(
                title: 'Medical Information',
                icon: Icons.medical_information_outlined,
                isExpanded: _showMedicalInfo,
                onTap: () => setState(() => _showMedicalInfo = !_showMedicalInfo),
              ),
              if (_showMedicalInfo) ...[
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _bloodGroupController.text.isNotEmpty ? _bloodGroupController.text : null,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                    prefixIcon: Icon(Icons.bloodtype_outlined),
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  ),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((bloodType) => DropdownMenuItem(
                            value: bloodType,
                            child: Text(bloodType),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _bloodGroupController.text = value!),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 2,
                  icon: Icon(Icons.arrow_drop_down_outlined),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _allergiesController,
                  decoration: InputDecoration(
                    labelText: 'Allergies (comma separated)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                    prefixIcon: Icon(Icons.health_and_safety_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add_circle_outline),
                      onPressed: () {
                        if (_allergiesController.text.isNotEmpty) {
                          setState(() {
                            _allergies.add(_allergiesController.text.trim());
                            _allergiesController.clear();
                          });
                        }
                      },
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                SizedBox(height: 12),
                if (_allergies.isNotEmpty) ...[
                  Text('Current Allergies:', 
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                  ),
                  SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _allergies.map((allergy) => Chip(
                      label: Text(allergy),
                      deleteIcon: Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _allergies.remove(allergy)),
                      shape: StadiumBorder(),
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      labelStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface),
                    )).toList(),
                  ),
                  SizedBox(height: 16),
                ],
              ],

              // Emergency Contact Section
              _buildSectionHeader(
                title: 'Emergency Contact',
                icon: Icons.emergency_outlined,
                isExpanded: _showEmergencyContact,
                onTap: () => setState(
                    () => _showEmergencyContact = !_showEmergencyContact),
              ),
              if (_showEmergencyContact) ...[
                SizedBox(height: 12),
                TextFormField(
                  controller: _emergencyNameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                    prefixIcon: Icon(Icons.person_outline),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emergencyNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                    prefixIcon: Icon(Icons.phone_outlined),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emergencyRelationController,
                  decoration: InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                    prefixIcon: Icon(Icons.people_outline),
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
              ],

              // App Settings Section (always visible)
              _buildSectionHeader(
                title: 'App Settings',
                icon: Icons.settings_outlined,
                isExpanded: _showAppSettings,
                onTap: () =>
                    setState(() => _showAppSettings = !_showAppSettings),
              ),
              if (_showAppSettings) ...[
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Enable Accident Monitoring',
                          style: TextStyle(fontSize: 16),
                        ),
                        value: _monitoringEnabled,
                        onChanged: (value) =>
                            setState(() => _monitoringEnabled = value),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Divider(height: 0, indent: 16),
                      SwitchListTile(
                        title: Text(
                          'Enable Location Sharing',
                          style: TextStyle(fontSize: 16),
                        ),
                        value: _locationEnabled,
                        onChanged: (value) =>
                            setState(() => _locationEnabled = value),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
              ],

              // About Section
              _buildSectionHeader(
                title: 'About',
                icon: Icons.info_outline,
                isExpanded: _showAbout,
                onTap: () => setState(() => _showAbout = !_showAbout),
              ),
              if (_showAbout) ...[
                SizedBox(height: 12),
                _buildAboutCard(),
                SizedBox(height: 16),
              ],

              // Save Button
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 24,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accident Alert System',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          _buildAboutItem(Icons.apps_outlined, 'Version: 1.0.0'),
          SizedBox(height: 8),
          _buildAboutItem(Icons.people_outline, 'Developed by: our Team'),
          SizedBox(height: 8),
          _buildAboutItem(
            Icons.email_outlined,
            'Contact: support@accidentalertsystem.com',
          ),
          SizedBox(height: 8),
          _buildAboutItem(
            Icons.copyright_outlined,
            '© 2025 All Rights Reserved',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
      ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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