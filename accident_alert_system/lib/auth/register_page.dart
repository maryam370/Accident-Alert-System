import 'package:accident_alert_system/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:accident_alert_system/user/info_input.dart';
import 'package:crypto/crypto.dart'; // for SHA256
import 'dart:convert'; // for utf8.encode

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool _isLoading = false; // To show loading state during registration
  bool _obscurePassword = true; // To toggle password visibility
  bool _obscureConfirmPassword = true; // To toggle confirm password visibility

  // Method to check if the email is already in use
  Future<bool> checkIfEmailExists(String email) async {
    try {
      final signInMethods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      print("Error checking email: $e");
      return false;
    }
  }

void registerUser(BuildContext context) async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final name = nameController.text.trim();

    // Check if passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      return;
    }

    // Check if email is already in use
    bool emailExists = await checkIfEmailExists(email);
    if (emailExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email is already in use.')),
      );
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
      return;
    }

    try {
      // Firebase Authentication: Create user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Hash the password before saving it to Firestore
      final bytes = utf8.encode(password); // Convert password to bytes
      final digest = sha256.convert(bytes); // Hash the password using SHA-256

      // Save additional user data to Firestore (excluding the password)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'userName': name,
        'password': digest.toString(),
        'role': 'user', // Save the hashed password
        'createdAt': DateTime.now(), // Optional: Add a timestamp
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );

      // Navigate to InfoInputPage after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => InfoInputPage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed.')),
      );
      print("FirebaseAuthException: ${e.code} - ${e.message}");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
      print("Unexpected error: $e");
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create an Account'),
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
                Text(
                  'Welcome! Create your account to get started.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 30),

                // Name TextFormField
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
                    }
                    if (!RegExp(
                            r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                        .hasMatch(value)) {
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
                      return 'Please enter a password';
                    }
                    String pattern =
                        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#_-])[A-Za-z\d@$!%*?&#_-]{8,}$';
                    RegExp regExp = RegExp(pattern);
                    if (!regExp.hasMatch(value)) {
                      return 'Password must be at least 8 characters long, contain an uppercase letter, a number, and a special character';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Confirm Password TextFormField with Toggleable Eye Icon
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirmPassword, // Toggle confirm password visibility
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword; // Toggle visibility
                        });
                      },
                    ),
                  ),
                  style: TextStyle(color: Colors.black),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),

                // Register Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => registerUser(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Register',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                SizedBox(height: 20),

                // Already have an account?
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Text(
                      'Already have an account? Login here',
                      style: TextStyle(color: Colors.blueAccent),
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