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

  // Method to show date picker
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

  // Method to save user info to Firestore
  void saveUserInfo(BuildContext context) async {
  if (_formKey.currentState!.validate()) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in. Please log in again.")),
      );
      return;
    }

    // Prepare the data to be saved
    final userData = {
      'name': nameController.text.trim(),
      'email': user.email,
      'phoneNumber': phoneNumberController.text.trim(),
      'gender': gender, // Add gender
      'dateOfBirth': dateOfBirth, // Add date of birth
      'socialStatus': socialStatus, // Add social status
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
      // Save user data to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User information saved successfully!")),
      );

      // Navigate to UserHomePage after successful save
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
                  ),
                  style: TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Gender
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.transgender, color: Colors.blueAccent),
                  ),
                  items: ['Male', 'Female']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      gender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Date of Birth
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      labelStyle: TextStyle(color: Colors.blueAccent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.blueAccent),
                    ),
                    child: Text(
                      dateOfBirth == null
                          ? 'Select Date'
                          : '${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Phone Number
                TextFormField(
                  controller: phoneNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.phone, color: Colors.blueAccent),
                  ),
                  style: TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Social Status
                DropdownButtonFormField<String>(
                  value: socialStatus,
                  decoration: InputDecoration(
                    labelText: 'Social Status',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.people, color: Colors.blueAccent),
                  ),
                  items: ['Single', 'Married', 'Divorced', 'Widowed']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      socialStatus = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your social status';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Blood Type (Optional)
                DropdownButtonFormField<String>(
                  value: bloodType,
                  decoration: InputDecoration(
                    labelText: 'Blood Type (Optional)',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.bloodtype, color: Colors.blueAccent),
                  ),
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      bloodType = value;
                    });
                  },
                ),
                SizedBox(height: 20),

                // Allergies (Optional)
                TextFormField(
                  controller: allergiesController,
                  decoration: InputDecoration(
                    labelText: 'Allergies (Optional, comma-separated)',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.health_and_safety, color: Colors.blueAccent),
                  ),
                  style: TextStyle(color: Colors.black),
                  onChanged: (value) {
                    setState(() {
                      allergies = value.split(',').map((e) => e.trim()).toList();
                    });
                  },
                ),
                SizedBox(height: 20),

                // Emergency Contact
                Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emergencyNameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.blueAccent),
                  ),
                  style: TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the emergency contact name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emergencyNumberController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.phone, color: Colors.blueAccent),
                  ),
                  style: TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the emergency contact number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: emergencyRelationController,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.people, color: Colors.blueAccent),
                  ),
                  style: TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the relation to the emergency contact';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Save Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => saveUserInfo(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Save Information',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}