import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bcrypt/bcrypt.dart'; // Import bcrypt package

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers for creating accounts
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController contactEmailController =TextEditingController(); 
  final TextEditingController hospitalTypeController = TextEditingController();
  final TextEditingController hospitalAddressController =  TextEditingController();
  final TextEditingController geographicalAreaController =TextEditingController();
  final TextEditingController departmentAddressController =TextEditingController();
  final TextEditingController regionServedController = TextEditingController();
  final TextEditingController serviceAreaController = TextEditingController();

  String? selectedRole;
  bool _isPasswordVisible = false; 

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Create New Account',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),

                    // Role selection
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(labelText: 'Role  '),
                      items: ['Admin', 'Hospital', 'Police', 'Ambulance']
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

                    // Common fields for all roles
                    if (selectedRole != null) ...[
                      SizedBox(height: 10),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(labelText: 'Name  '),
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
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: phoneNumberController,
                        decoration:
                            InputDecoration(labelText: 'Phone Number  '),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Phone Number is required';
                          }
                          return null;
                        },
                      ),

                      // Contact email field for Hospital, Police, and Ambulance
                      if (selectedRole != 'Admin' &&
                          selectedRole != 'Police') ...[
                        SizedBox(height: 10),
                        TextFormField(
                          controller: contactEmailController,
                          decoration:
                              InputDecoration(labelText: 'Contact Email  '),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Contact Email is required';
                            }
                            return null;
                          },
                        ),
                      ],

                      // Role-specific fields
                      if (selectedRole == 'Hospital') ...[
                        SizedBox(height: 10),
                        TextFormField(
                          controller: hospitalTypeController,
                          decoration:
                              InputDecoration(labelText: 'Hospital Type  '),
                        ),
                        TextFormField(
                          controller: hospitalAddressController,
                          decoration:
                              InputDecoration(labelText: 'Hospital Address  '),
                        ),
                        TextFormField(
                          controller: geographicalAreaController,
                          decoration:
                              InputDecoration(labelText: 'Geographical Area  '),
                        ),
                      ] else if (selectedRole == 'Police') ...[
                        SizedBox(height: 10),
                        TextFormField(
                          controller: departmentAddressController,
                          decoration: InputDecoration(
                              labelText: 'Department Address  '),
                        ),
                        TextFormField(
                          controller: regionServedController,
                          decoration: InputDecoration(
                              labelText: 'Region/Area Served  '),
                        ),
                      ] else if (selectedRole == 'Ambulance') ...[
                        SizedBox(height: 10),
                        TextFormField(
                          controller: serviceAreaController,
                          decoration:
                              InputDecoration(labelText: 'Service Area  '),
                        ),
                      ],

                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => createAccount(context),
                        child: Text('Create Account'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Hospital Users List
            Text(
              'Hospital',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            HospitalUsersList(),
            Text(
              'Police',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            PoliceUsersList(),
            SizedBox(height: 10),

            Text(
              'Ambulance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            AmbulanceUsersList()
          ],
        ),
      ),
    );
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

      // Hash the password
      String hashedPassword =
          BCrypt.hashpw(passwordController.text.trim(), BCrypt.gensalt());

      // Prepare user data based on role
      Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(), // Login email
        'phoneNumber': phoneNumberController.text.trim(),
        'role': selectedRole,
        'password': hashedPassword,
        'createdAt': DateTime.now(),
      };

      // Add contact email for Hospital, Police, and Ambulance
      if (selectedRole != 'Admin') {
        userData['contactEmail'] = contactEmailController.text.trim();
      }

      // Add role-specific fields
      switch (selectedRole) {
        case 'Hospital':
          userData['hospitalType'] = hospitalTypeController.text.trim();
          userData['hospitalAddress'] = hospitalAddressController.text.trim();
          userData['geographicalArea'] = geographicalAreaController.text.trim();
          break;
        case 'Police':
          userData['departmentAddress'] =
              departmentAddressController.text.trim();
          userData['regionServed'] = regionServedController.text.trim();
          break;
        case 'Ambulance':
          userData['serviceArea'] = serviceAreaController.text.trim();
          break;
      }

      // Save user data to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully!')),
      );

      // Clear form fields
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      phoneNumberController.clear();
      contactEmailController.clear();
      hospitalTypeController.clear();
      hospitalAddressController.clear();
      geographicalAreaController.clear();
      departmentAddressController.clear();
      regionServedController.clear();
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
}

// Hospital Users List Widget
class HospitalUsersList extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'Hospital')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No hospitals found.'));
        }

        final hospitals = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: hospitals.length,
          itemBuilder: (context, index) {
            final hospital = hospitals[index].data() as Map<String, dynamic>;
            final hospitalId =
                hospitals[index].id; // Document ID for editing/deleting
            final name = hospital['name'];
            final phoneNumber = hospital['phoneNumber'];
            final email = hospital['email'];
            final geographicalArea = hospital['geographicalArea'];

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: $name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Phone Number: $phoneNumber'),
                    Text('Email: $email'),
                    Text('Geographical Area: $geographicalArea'),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        // Edit Button
                        ElevatedButton(
                          onPressed: () =>
                              _editHospital(context, hospitalId, hospital),
                          child: Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 8),
                        // Delete Button
                        ElevatedButton(
                          onPressed: () => _deleteHospital(context, hospitalId),
                          child: Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Function to delete a hospital user
  Future<void> _deleteHospital(BuildContext context, String hospitalId) async {
    try {
      await _firestore.collection('users').doc(hospitalId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hospital deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete hospital: ${e.toString()}')),
      );
    }
  }

  // Function to edit a hospital user
  Future<void> _editHospital(BuildContext context, String hospitalId,
      Map<String, dynamic> hospitalData) async {
    final TextEditingController nameController =
        TextEditingController(text: hospitalData['name']);
    final TextEditingController phoneNumberController =
        TextEditingController(text: hospitalData['phoneNumber']);
    final TextEditingController emailController =
        TextEditingController(text: hospitalData['email']);
    final TextEditingController geographicalAreaController =
        TextEditingController(text: hospitalData['geographicalArea']);
    final TextEditingController hospitalTypeController =
        TextEditingController(text: hospitalData['hospitalType']);
    final TextEditingController hospitalAddressController =
        TextEditingController(text: hospitalData['hospitalAddress']);
    final TextEditingController contactEmailController =
        TextEditingController(text: hospitalData['contactEmail']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Hospital'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                ),
                TextFormField(
                  controller: phoneNumberController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  controller: geographicalAreaController,
                  decoration: InputDecoration(labelText: 'Geographical Area'),
                ),
                TextFormField(
                  controller: hospitalTypeController,
                  decoration: InputDecoration(labelText: 'Hospital Type'),
                ),
                TextFormField(
                  controller: hospitalAddressController,
                  decoration: InputDecoration(labelText: 'Hospital Address'),
                ),
                TextFormField(
                  controller: contactEmailController,
                  decoration: InputDecoration(labelText: 'Contact Email'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update the hospital data in Firestore
                await _firestore.collection('users').doc(hospitalId).update({
                  'name': nameController.text.trim(),
                  'phoneNumber': phoneNumberController.text.trim(),
                  'email': emailController.text.trim(),
                  'geographicalArea': geographicalAreaController.text.trim(),
                  'hospitalType': hospitalTypeController.text.trim(),
                  'hospitalAddress': hospitalAddressController.text.trim(),
                  'contactEmail': contactEmailController.text.trim(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hospital updated successfully!')),
                );

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

// Police Users List Widget
class PoliceUsersList extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'Police')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No police departments found.'));
        }

        final policeDepartments = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: policeDepartments.length,
          itemBuilder: (context, index) {
            final police =
                policeDepartments[index].data() as Map<String, dynamic>;
            final policeId =
                policeDepartments[index].id; // Document ID for editing/deleting
            final name = police['name'];
            final phoneNumber = police['phoneNumber'];
            final email = police['email'];
            final regionServed = police['regionServed'];

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: $name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Phone Number: $phoneNumber'),
                    Text('Email: $email'),
                    Text('Region Served: $regionServed'),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        // Edit Button
                        ElevatedButton(
                          onPressed: () =>
                              _editPolice(context, policeId, police),
                          child: Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 8),
                        // Delete Button
                        ElevatedButton(
                          onPressed: () => _deletePolice(context, policeId),
                          child: Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Function to delete a police department user
  Future<void> _deletePolice(BuildContext context, String policeId) async {
    try {
      await _firestore.collection('users').doc(policeId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Police department deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to delete police department: ${e.toString()}')),
      );
    }
  }

  // Function to edit a police department user
  Future<void> _editPolice(BuildContext context, String policeId,
      Map<String, dynamic> policeData) async {
    final TextEditingController nameController =
        TextEditingController(text: policeData['name']);
    final TextEditingController phoneNumberController =
        TextEditingController(text: policeData['phoneNumber']);
    final TextEditingController emailController =
        TextEditingController(text: policeData['email']);
    final TextEditingController regionServedController =
        TextEditingController(text: policeData['regionServed']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Police Department'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextFormField(
                  controller: phoneNumberController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  controller: regionServedController,
                  decoration: InputDecoration(labelText: 'Region Served'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the data in Firestore
                    _firestore.collection('users').doc(policeId).update({
                      'name': nameController.text,
                      'phoneNumber': phoneNumberController.text,
                      'email': emailController.text,
                      'regionServed': regionServedController.text,
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Ambulance Users List Widget
class AmbulanceUsersList extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'Ambulance')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No ambulance services found.'));
        }

        final ambulances = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: ambulances.length,
          itemBuilder: (context, index) {
            final ambulance = ambulances[index].data() as Map<String, dynamic>;
            final ambulanceId =
                ambulances[index].id; // Document ID for editing/deleting
            final name = ambulance['name'];
            final phoneNumber = ambulance['phoneNumber'];
            final email = ambulance['email'];
            final serviceArea = ambulance['serviceArea'];

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: $name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Phone Number: $phoneNumber'),
                    Text('Email: $email'),
                    Text('Service Area: $serviceArea'),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        // Edit Button
                        ElevatedButton(
                          onPressed: () =>
                              _editAmbulance(context, ambulanceId, ambulance),
                          child: Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 8),
                        // Delete Button
                        ElevatedButton(
                          onPressed: () =>
                              _deleteAmbulance(context, ambulanceId),
                          child: Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Function to delete an ambulance user
  Future<void> _deleteAmbulance(
      BuildContext context, String ambulanceId) async {
    try {
      await _firestore.collection('users').doc(ambulanceId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ambulance service deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to delete ambulance service: ${e.toString()}')),
      );
    }
  }

  // Function to edit an ambulance user
  Future<void> _editAmbulance(BuildContext context, String ambulanceId,
      Map<String, dynamic> ambulanceData) async {
    final TextEditingController nameController =
        TextEditingController(text: ambulanceData['name']);
    final TextEditingController phoneNumberController =
        TextEditingController(text: ambulanceData['phoneNumber']);
    final TextEditingController emailController =
        TextEditingController(text: ambulanceData['email']);
    final TextEditingController serviceAreaController =
        TextEditingController(text: ambulanceData['serviceArea']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Ambulance Service'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextFormField(
                  controller: phoneNumberController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  controller: serviceAreaController,
                  decoration: InputDecoration(labelText: 'Service Area'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the data in Firestore
                    _firestore.collection('users').doc(ambulanceId).update({
                      'name': nameController.text,
                      'phoneNumber': phoneNumberController.text,
                      'email': emailController.text,
                      'serviceArea': serviceAreaController.text,
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
