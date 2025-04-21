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
    // Create user
    final cred = await _auth.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
    final uid = cred.user!.uid;

    // Hash password
    final hashedPassword = BCrypt.hashpw(
      passwordController.text.trim(),
      BCrypt.gensalt(),
    );

    // Add to 'users' collection
    await _firestore.collection('users').doc(uid).set({
      'email': emailController.text.trim(),
      'role': selectedRole,
      'password': hashedPassword,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add role-specific info with userId field included
    final baseData = {
      'userId': uid,
      'name': nameController.text.trim(),
      'contactEmail': contactEmailController.text.trim(),
      'phoneNumber': phoneNumberController.text.trim(),
    };

    switch (selectedRole) {
      case 'Hospital':
        await _firestore.collection('hospital_info').doc(uid).set({
          ...baseData,
          'hospitalType': hospitalTypeController.text.trim(),
          'hospitalAddress': hospitalAddressController.text.trim(),
          'geographicalArea': geographicalAreaController.text.trim(),
        });
        break;

      case 'Police':
        await _firestore.collection('police_info').doc(uid).set({
          ...baseData,
          'departmentAddress': departmentAddressController.text.trim(),
          'regionServed': regionServedController.text.trim(),
        });
        break;

      case 'Ambulance':
        await _firestore.collection('ambulance_info').doc(uid).set({
          ...baseData,
          'serviceArea': serviceAreaController.text.trim(),
        });
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Account created successfully!')),
    );

    // Clear form
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
    setState(() => selectedRole = null);

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to create account: $e')),
    );
  }
}
}

class HospitalUsersList extends StatefulWidget {
  @override
  _HospitalUsersListState createState() => _HospitalUsersListState();
}
class _HospitalUsersListState extends State<HospitalUsersList>  {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'Hospital')
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
          return Center(child: Text('No hospitals found.'));
        }

        final hospitalUsers = userSnapshot.data!.docs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchHospitalsWithDetails(hospitalUsers),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final hospitals = snapshot.data!;

            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: hospitals.length,
              itemBuilder: (context, index) {
                final hospital = hospitals[index];
                final hospitalId = hospital['uid']; // from users doc

                return Card(
                  margin: EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Name: ${hospital['name']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Phone Number: ${hospital['phoneNumber']}'),
                        Text('Email: ${hospital['email']}'),
                        Text('Geographical Area: ${hospital['geographicalArea']}'),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _editHospital(context, hospitalId, hospital),
                              child: Text('Edit'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _deleteHospital(context, hospitalId),
                              child: Text('Delete'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchHospitalsWithDetails(List<QueryDocumentSnapshot> users) async {
    List<Map<String, dynamic>> hospitalList = [];

    for (var userDoc in users) {
      final uid = userDoc.id;
      final email = userDoc['email'];

      final infoDoc = await _firestore.collection('hospital_info').doc(uid).get();
      if (infoDoc.exists) {
        final data = infoDoc.data()!;
        hospitalList.add({
          'uid': uid,
          'email': email,
          'name': data['name'],
          'phoneNumber': data['phoneNumber'],
          'geographicalArea': data['geographicalArea'],
          'hospitalType': data['hospitalType'],
          'hospitalAddress': data['hospitalAddress'],
          'contactEmail': data['contactEmail'],
        });
      }
    }

    return hospitalList;
  }

  Future<void> _deleteHospital(BuildContext context, String hospitalId) async {
    try {
      await _firestore.collection('users').doc(hospitalId).delete();
      await _firestore.collection('hospital_info').doc(hospitalId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hospital deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete hospital: ${e.toString()}')),
      );
    }
  }

  Future<void> _editHospital(BuildContext context, String hospitalId, Map<String, dynamic> hospitalData) async {
    final nameController = TextEditingController(text: hospitalData['name']);
    final phoneNumberController = TextEditingController(text: hospitalData['phoneNumber']);
    final emailController = TextEditingController(text: hospitalData['email']);
    final geographicalAreaController = TextEditingController(text: hospitalData['geographicalArea']);
    final hospitalTypeController = TextEditingController(text: hospitalData['hospitalType']);
    final hospitalAddressController = TextEditingController(text: hospitalData['hospitalAddress']);
    final contactEmailController = TextEditingController(text: hospitalData['contactEmail']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Hospital'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
              TextFormField(controller: phoneNumberController, decoration: InputDecoration(labelText: 'Phone Number')),
              TextFormField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
              TextFormField(controller: geographicalAreaController, decoration: InputDecoration(labelText: 'Geographical Area')),
              TextFormField(controller: hospitalTypeController, decoration: InputDecoration(labelText: 'Hospital Type')),
              TextFormField(controller: hospitalAddressController, decoration: InputDecoration(labelText: 'Hospital Address')),
              TextFormField(controller: contactEmailController, decoration: InputDecoration(labelText: 'Contact Email')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              // Update both collections
              await _firestore.collection('hospital_info').doc(hospitalId).update({
                'name': nameController.text.trim(),
                'phoneNumber': phoneNumberController.text.trim(),
                'hospitalType': hospitalTypeController.text.trim(),
                'geographicalArea': geographicalAreaController.text.trim(),
                'hospitalAddress': hospitalAddressController.text.trim(),
                'contactEmail': contactEmailController.text.trim(),
              });

              await _firestore.collection('users').doc(hospitalId).update({
                'email': emailController.text.trim(),
              });

              Navigator.pop(context);
              setState(() {
                
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Hospital updated successfully!')),
              );
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }
}

class PoliceUsersList extends StatefulWidget {
  @override
  _PoliceUsersListState createState() => _PoliceUsersListState();
}

class _PoliceUsersListState extends State<PoliceUsersList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('police_info').snapshots(),
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
            final police = policeDepartments[index].data() as Map<String, dynamic>;
            final policeId = policeDepartments[index].id;

            final name = police['name'] ?? '';
            final phoneNumber = police['phoneNumber'] ?? '';
            final email = police['contactEmail'] ?? '';
            final regionServed = police['regionServed'] ?? '';

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: $name',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Phone Number: $phoneNumber'),
                    Text('Email: $email'),
                    Text('Region Served: $regionServed'),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _editPolice(context, policeId, police),
                          child: Text('Edit'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _deletePolice(context, policeId),
                          child: Text('Delete'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  Future<void> _deletePolice(BuildContext context, String policeId) async {
    try {
      await _firestore.collection('police_info').doc(policeId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Police department deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete police department: $e')),
      );
    }
  }

  Future<void> _editPolice(
      BuildContext context, String policeId, Map<String, dynamic> policeData) async {
    final nameController = TextEditingController(text: policeData['name']);
    final phoneController = TextEditingController(text: policeData['phoneNumber']);
    final emailController = TextEditingController(text: policeData['contactEmail']);
    final regionController = TextEditingController(text: policeData['regionServed']);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Police Department'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Contact Email'),
                ),
                TextField(
                  controller: regionController,
                  decoration: InputDecoration(labelText: 'Region Served'),
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
                await _firestore.collection('police_info').doc(policeId).update({
                  'name': nameController.text.trim(),
                  'phoneNumber': phoneController.text.trim(),
                  'contactEmail': emailController.text.trim(),
                  'regionServed': regionController.text.trim(),
                });

                setState(() {}); // Refresh UI immediately
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Police department updated successfully!')),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class AmbulanceUsersList extends StatefulWidget {
  @override
  _AmbulanceUsersListState createState() => _AmbulanceUsersListState();
}

class _AmbulanceUsersListState extends State<AmbulanceUsersList> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('ambulance_info').snapshots(),
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
            final ambulanceId = ambulances[index].id;

            final name = ambulance['name'] ?? '';
            final phoneNumber = ambulance['phoneNumber'] ?? '';
            final email = ambulance['contactEmail'] ?? '';
            final serviceArea = ambulance['serviceArea'] ?? '';

            return Card(
              margin: EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Name: $name',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Phone Number: $phoneNumber'),
                    Text('Email: $email'),
                    Text('Service Area: $serviceArea'),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _editAmbulance(context, ambulanceId, ambulance),
                          child: Text('Edit'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _deleteAmbulance(context, ambulanceId),
                          child: Text('Delete'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  Future<void> _deleteAmbulance(BuildContext context, String ambulanceId) async {
    try {
      await _firestore.collection('ambulance_info').doc(ambulanceId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ambulance service deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete ambulance service: $e')),
      );
    }
  }

  Future<void> _editAmbulance(
    BuildContext context,
    String ambulanceId,
    Map<String, dynamic> ambulanceData,
  ) async {
    final nameController = TextEditingController(text: ambulanceData['name']);
    final phoneController = TextEditingController(text: ambulanceData['phoneNumber']);
    final emailController = TextEditingController(text: ambulanceData['contactEmail']);
    final serviceAreaController = TextEditingController(text: ambulanceData['serviceArea']);

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
                  controller: phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Contact Email'),
                ),
                TextFormField(
                  controller: serviceAreaController,
                  decoration: InputDecoration(labelText: 'Service Area'),
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
                await _firestore.collection('ambulance_info').doc(ambulanceId).update({
                  'name': nameController.text.trim(),
                  'phoneNumber': phoneController.text.trim(),
                  'contactEmail': emailController.text.trim(),
                  'serviceArea': serviceAreaController.text.trim(),
                });

                setState(() {}); // Refresh the widget
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ambulance service updated successfully!')),
                );
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
