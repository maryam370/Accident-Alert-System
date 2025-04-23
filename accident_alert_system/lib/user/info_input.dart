import 'package:accident_alert_system/user/user_home_page.dart';
import 'package:accident_alert_system/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InfoInputPage extends StatefulWidget {
  @override
  _InfoInputPageState createState() => _InfoInputPageState();
}

class _InfoInputPageState extends State<InfoInputPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyNumberController = TextEditingController();
  final TextEditingController emergencyRelationController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();

  String? gender;
  String? socialStatus;
  String? bloodType;
  DateTime? dateOfBirth;
  List<String> allergies = [];

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _offsetAnimation = Tween<Offset>(begin: Offset(0.0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != dateOfBirth) {
      setState(() {
        dateOfBirth = picked;
      });
    }
  }

  void saveUserInfo(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in. Please log in again.")),
        );
        return;
      }

      final userData = {
        'userId': user.uid,
        'name': nameController.text.trim(),
        'phoneNumber': phoneNumberController.text.trim(),
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'socialStatus': socialStatus,
        'medicalRecords': {
          'bloodGroup': bloodType,
          'allergies': allergies,
          'emergencyContact': {
            'name': emergencyNameController.text.trim(),
            'number': emergencyNumberController.text.trim(),
            'relation': emergencyRelationController.text.trim(),
          },
        },
        'createdAt': DateTime.now(),
      };

      try {
        await FirebaseFirestore.instance.collection('user_info').doc(user.uid).set(userData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User information saved successfully!")));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserHomePage()));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save user information.")));
        print("Error saving user info: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Colors.blue.shade900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: themeColor),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: SlideTransition(
              position: _offsetAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text("Personal Information",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.black)),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(nameController, 'Full Name', Icons.person),
                    _buildDropdown(gender, 'Gender', ['Male', 'Female', 'Other'], Icons.transgender,
                        (value) => setState(() => gender = value)),
                    _buildDatePicker(context),
                    _buildTextField(phoneNumberController, 'Phone Number', Icons.phone),
                    _buildDropdown(socialStatus, 'Social Status',
                        ['Single', 'Married', 'Divorced', 'Widowed'], Icons.people, (value) => setState(() => socialStatus = value)),
                    _buildDropdown(bloodType, 'Blood Type (Optional)',
                        ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], Icons.bloodtype, (value) => setState(() => bloodType = value)),
                    _buildTextField(allergiesController, 'Allergies (comma separated)', Icons.medical_services,
                        onChanged: (val) => setState(() => allergies = val.split(',').map((e) => e.trim()).toList())),
                    SizedBox(height: 30),
                    Center(
                      child: Text('Emergency Contact 🚨',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(emergencyNameController, 'Name', Icons.person),
                    _buildTextField(emergencyNumberController, 'Phone Number', Icons.phone),
                    _buildTextField(emergencyRelationController, 'Relation', Icons.group),
                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => saveUserInfo(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                          elevation: 5,
                        ),
                        child: const Text("Save Info", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade900),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade900),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade100),
          ),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildDropdown(String? value, String label, List<String> options, IconData icon,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade900),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: InkWell(
        onTap: () => _selectDate(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade900),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            dateOfBirth == null
                ? 'Select Date'
                : '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneNumberController.dispose();
    emergencyNameController.dispose();
    emergencyNumberController.dispose();
    emergencyRelationController.dispose();
    allergiesController.dispose();
    _controller.dispose();
    super.dispose();
  }
}