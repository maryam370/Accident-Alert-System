import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHomePage extends StatefulWidget {
  @override
  _AdminHomePageState createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for creating accounts
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController hospitalNameController = TextEditingController();
  final TextEditingController hospitalTypeController = TextEditingController();
  final TextEditingController hospitalAddressController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();
  final TextEditingController geographicalAreaController = TextEditingController();
  final TextEditingController policeDepartmentNameController = TextEditingController();
  final TextEditingController officerInChargeController = TextEditingController();
  final TextEditingController departmentAddressController = TextEditingController();
  final TextEditingController regionServedController = TextEditingController();
  final TextEditingController emsNameController = TextEditingController();
  final TextEditingController serviceAreaController = TextEditingController();

  String? selectedRole;

  // Fetch all users from Firestore
  Future<List<QueryDocumentSnapshot>> fetchUsers() async {
    final querySnapshot = await _firestore.collection('users').get();
    return querySnapshot.docs;
  }

  // Create a new account
  Future<void> createAccount(BuildContext context) async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      // Create user in Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Prepare user data based on role
      Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phoneNumber': phoneNumberController.text.trim(), // Optional
        'role': selectedRole,
        'createdAt': DateTime.now(),
      };

      // Add role-specific fields
      switch (selectedRole) {
        case 'Admin':
          // No additional fields for Admin
          break;
        case 'Hospital':
          userData['hospitalName'] = hospitalNameController.text.trim();
          userData['hospitalType'] = hospitalTypeController.text.trim();
          userData['hospitalAddress'] = hospitalAddressController.text.trim();
          userData['emergencyContactNumber'] = emergencyContactController.text.trim();
          userData['geographicalArea'] = geographicalAreaController.text.trim();
          break;
        case 'Police':
          userData['policeDepartmentName'] = policeDepartmentNameController.text.trim();
          userData['officerInCharge'] = officerInChargeController.text.trim();
          userData['departmentAddress'] = departmentAddressController.text.trim();
          userData['regionServed'] = regionServedController.text.trim();
          break;
        case 'Ambulance/EMS':
          userData['emsName'] = emsNameController.text.trim();
          userData['serviceArea'] = serviceAreaController.text.trim();
          break;
      }

      // Save user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully!')),
      );

      // Clear form fields
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      phoneNumberController.clear();
      hospitalNameController.clear();
      hospitalTypeController.clear();
      hospitalAddressController.clear();
      emergencyContactController.clear();
      geographicalAreaController.clear();
      policeDepartmentNameController.clear();
      officerInChargeController.clear();
      departmentAddressController.clear();
      regionServedController.clear();
      emsNameController.clear();
      serviceAreaController.clear();
      setState(() {
        selectedRole = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create account: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Home Page'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Form to create a new account
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Create New Account',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
        
                      // Common fields for all roles
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Full Name  '),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(labelText: 'Email  '),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email is required';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(labelText: 'Password '),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: phoneNumberController,
                        decoration: InputDecoration(labelText: 'Phone Number (Optional)'),
                      ),
        
                      // Role selection
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(labelText: 'Role  '),
                        items: ['Admin', 'Hospital', 'Police', 'Ambulance/EMS']
                            .map((role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Role is required';
                          }
                          return null;
                        },
                      ),
        
                      // Role-specific fields
                      if (selectedRole == 'Hospital') ...[
                        SizedBox(height: 10),
                        TextFormField(
                          controller: hospitalNameController,
                          decoration: InputDecoration(labelText: 'Hospital Name  '),
                        ),
                        TextFormField(
                          controller: hospitalTypeController,
                          decoration: InputDecoration(labelText: 'Hospital Type  '),
                        ),
                        TextFormField(
                          controller: hospitalAddressController,
                          decoration: InputDecoration(labelText: 'Hospital Address  '),
                        ),
                        TextFormField(
                          controller: emergencyContactController,
                          decoration: InputDecoration(labelText: 'Emergency Contact Number  '),
                        ),
                        TextFormField(
                          controller: geographicalAreaController,
                          decoration: InputDecoration(labelText: 'Geographical Area  '),
                        ),
                      ] else if (selectedRole == 'Police') ...[
                        SizedBox(height: 10),
                        TextFormField(
                          controller: policeDepartmentNameController,
                          decoration: InputDecoration(labelText: 'Police Department Name  '),
                        ),
                        TextFormField(
                          controller: officerInChargeController,
                          decoration: InputDecoration(labelText: 'Officer in Charge  '),
                        ),
                        TextFormField(
                          controller: departmentAddressController,
                          decoration: InputDecoration(labelText: 'Department Address  '),
                        ),
                        TextFormField(
                          controller: regionServedController,
                          decoration: InputDecoration(labelText: 'Region/Area Served  '),
                        ),
                      ] else if (selectedRole == 'Ambulance/EMS') ...[
                        SizedBox(height: 10),
                        TextFormField(
                          controller: emsNameController,
                          decoration: InputDecoration(labelText: 'EMS Name  '),
                        ),
                        TextFormField(
                          controller: serviceAreaController,
                          decoration: InputDecoration(labelText: 'Service Area  '),
                        ),
                      ],
        
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => createAccount(context),
                        child: Text('Create Account'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),      
            ],
          ),
        ),
      ),
    );
  }
}