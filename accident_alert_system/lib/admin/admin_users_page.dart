import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bcrypt/bcrypt.dart'; // Import bcrypt package

class UsersPage extends StatefulWidget {
  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final Color _primaryColor = const Color(0xFF0D5D9F); // Deep blue
  final Color _cardColor = const Color(0xFFE6F2FF); 
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
    return Scaffold(
    appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Aler',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D5D9F),
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.blue.shade100,
        toolbarHeight: kToolbarHeight + MediaQuery.of(context).padding.top + 30,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5D9F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Color(0xFF0D5D9F),
                  size: 24,
                ),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ),
        ],
      ),
    body:SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              color: Colors.lightBlue[50],
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
    ),);
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
          return const Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No hospitals found.',
              style: TextStyle(fontSize: 16),
            ),
          );
        }

        final hospitalUsers = userSnapshot.data!.docs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchHospitalsWithDetails(hospitalUsers),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final hospitals = snapshot.data!;

            return ListView.builder(
              itemCount: hospitals.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              itemBuilder: (context, index) {
                final hospital = hospitals[index];
                final hospitalId = hospital['uid'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue[50],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital['name'] ?? 'Unnamed Hospital',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(hospital['phoneNumber'] ?? 'N/A'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(hospital['email'] ?? 'N/A'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(hospital['geographicalArea'] ?? 'N/A'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _editHospital(context, hospitalId, hospital),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _deleteHospital(context, hospitalId),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text('Delete'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
  SnackBar(
    content: const Text(
      'Hospital updated successfully!',
      style: TextStyle(
        color: Colors.white, // White text color for better contrast
        fontWeight: FontWeight.bold, // Bold text for emphasis
      ),
    ),
    backgroundColor: Colors.green, // Green background for success message
    duration: const Duration(seconds: 3), // Duration of the snack bar
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10), // Rounded corners for the snack bar
    ),
    behavior: SnackBarBehavior.floating, // Floating snack bar with some elevation
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Custom margins
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Custom padding inside the snack bar
  ),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: const Text(
      'Edit Hospital',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInputField(controller: nameController, label: 'Name'),
          _buildInputField(controller: phoneNumberController, label: 'Phone Number', inputType: TextInputType.phone),
          _buildInputField(controller: emailController, label: 'Email', inputType: TextInputType.emailAddress),
          _buildInputField(controller: geographicalAreaController, label: 'Geographical Area'),
          _buildInputField(controller: hospitalTypeController, label: 'Hospital Type'),
          _buildInputField(controller: hospitalAddressController, label: 'Hospital Address'),
          _buildInputField(controller: contactEmailController, label: 'Contact Email', inputType: TextInputType.emailAddress),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
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
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hospital updated successfully!')),
          );
        },
        child: const Text('Save'),
      ),
    ],
  ),
);

    
  }
  Widget _buildInputField({
  required TextEditingController controller,
  required String label,
  TextInputType inputType = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
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
