import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accident_alert_system/auth/register_page.dart';
import 'package:accident_alert_system/user/user_home_page.dart';
import 'package:accident_alert_system/police/police_home_page.dart';
import 'package:accident_alert_system/hospital/hospital_home_page.dart';
import 'package:accident_alert_system/ambulance/ambulance_home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true; // To toggle password visibility

  void loginUser(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      try {
        // Firebase Authentication
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        if (userCredential.user == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Authentication failed. Please try again."),
          ));
          return;
        }

        // Fetch user role from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc.data()?['role'];
          if (role == 'user') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => UserHomePage()));
          } else if (role == 'police') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => PoliceHomePage()));
          } else if (role == 'hospital') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => HospitalHomePage()));
          } else if (role == 'ambulance') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => AmbulanceHomePage()));
          } else if (role == 'admin') {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => AmbulanceHomePage()));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Role not recognized"),
            ));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("User document not found"),
          ));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Incorrect email/password. Please try again."),
        ));
      }
    }
  }

  // Forgot Password Functionality
  void forgotPassword(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Forgot Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter your email address to reset your password."),
              SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final email = emailController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Please enter your email address."),
                  ));
                  return;
                }

                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Password reset email sent to $email."),
                  ));
                  Navigator.pop(context); // Close the dialog
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Error: ${e.message}"),
                  ));
                  print("FirebaseAuthException: ${e.code} - ${e.message}");
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Failed to send password reset email. Please try again."),
                  ));
                  print("Unexpected error: $e");
                }
              },
              child: Text("Send"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back! Please login to your account.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 30),
              // Form widget
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email TextFormField
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                        prefixIcon: Icon(Icons.email, color: Colors.blueAccent),
                      ),
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Password TextFormField with Toggleable Eye Icon
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword, // Toggle password visibility
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.blueAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.blueAccent),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword; // Toggle visibility
                            });
                          },
                        ),
                      ),
                      style: TextStyle(color: Colors.black),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Login Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => loginUser(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Forgot Password Button
                    Center(
                      child: TextButton(
                        onPressed: () => forgotPassword(context),
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ),

                    // Don't have an account? Register Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                              context, MaterialPageRoute(builder: (_) => RegisterPage()));
                        },
                        child: Text(
                          'Don\'t have an account? Register here',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}