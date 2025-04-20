import 'package:accident_alert_system/user/user_home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InfoInputPage extends StatefulWidget {
  @override
  _InfoInputPageState createState() => _InfoInputPageState();
}

class _InfoInputPageState extends State<InfoInputPage> {
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
        'userId': user.uid,  // Reference to the main users collection
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
        // Save to the new user_info collection
        await FirebaseFirestore.instance
            .collection('user_info')
            .doc(user.uid)  // Same document ID as users collection
            .set(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User information saved successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserHomePage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save user information. Please try again.")),
        );
        print("Error saving user info: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Enter Your Info"),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name field
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Gender dropdown
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.transgender),
                  ),
                  items: ['Male', 'Female', 'Other']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => gender = value),
                  validator: (value) => value == null ? 'Please select gender' : null,
                ),
                SizedBox(height: 20),

                // Date picker
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      dateOfBirth == null
                          ? 'Select Date'
                          : '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}',
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Phone number
                TextFormField(
                  controller: phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Social status
                DropdownButtonFormField<String>(
                  value: socialStatus,
                  decoration: InputDecoration(
                    labelText: 'Social Status',
                    prefixIcon: Icon(Icons.people),
                  ),
                  items: ['Single', 'Married', 'Divorced', 'Widowed']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => socialStatus = value),
                  validator: (value) => value == null ? 'Please select status' : null,
                ),
                SizedBox(height: 20),

                // Blood type (optional)
                DropdownButtonFormField<String>(
                  value: bloodType,
                  decoration: InputDecoration(
                    labelText: 'Blood Type (Optional)',
                    prefixIcon: Icon(Icons.bloodtype),
                  ),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => bloodType = value),
                ),
                SizedBox(height: 20),

                // Allergies (optional)
                TextFormField(
                  controller: allergiesController,
                  decoration: InputDecoration(
                    labelText: 'Allergies (Optional, comma-separated)',
                    prefixIcon: Icon(Icons.health_and_safety),
                  ),
                  onChanged: (value) => setState(() {
                    allergies = value.split(',').map((e) => e.trim()).toList();
                  }),
                ),
                SizedBox(height: 20),

                // Emergency contact section
                Text('Emergency Contact', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                TextFormField(
                  controller: emergencyNameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emergencyNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emergencyRelationController,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    prefixIcon: Icon(Icons.people),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter relationship';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => saveUserInfo(context),
                    child: Text('Save Information'),
                  ),
                ),
              ],
            ),
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
    super.dispose();
  }
}