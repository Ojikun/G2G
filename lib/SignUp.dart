import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'LogIn.dart';
import 'HomePage.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  Future<void> signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // Add default profile image URL
      const String defaultProfileImage =
          'https://res.cloudinary.com/dtgvivwfa/image/upload/v1746955399/n7zjcnuzmkgpw8spdpjx.png';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'profileImage': defaultProfileImage, // Save default profile image
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sign Up Successful!"),
          backgroundColor: Color(0xff238855),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> signUpWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user?.uid)
              .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
              'name': userCredential.user?.displayName,
              'email': userCredential.user?.email,
              'profileImage':
                  userCredential.user?.photoURL ??
                  'assets/default_avatar.png', // Save Google profile image or default
            });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In Successful!"),
          backgroundColor: Color(0xff238855),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google Sign-In Failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration customInputDecoration(
    String label,
    String hint, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelStyle: TextStyle(
        color: Color(0xff238855F), // Change focused label text color
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xff238855)),
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Logo and tagline at the top
            Column(
              children: [
                SizedBox(height: 10),
                Center(
                  child: Image.asset(
                    'assets/logo.png', // Replace with your logo asset path
                    width: 120,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  "Give what you can. Get what you need.",
                  style: TextStyle(color: Colors.black, fontSize: 19),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            // Bottom sheet-like container for fields and buttons
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: screenHeight * 0.75, // Adjust height as needed
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          "Create an Account",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff238855),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Name
                        TextField(
                          controller: _nameController,
                          cursorColor: Color(0xff238855),
                          decoration: customInputDecoration("Full Name", ""),
                        ),
                        SizedBox(height: 20),

                        // Email
                        TextField(
                          controller: _emailController,
                          cursorColor: Color(0xff238855),
                          decoration: customInputDecoration(
                            "Email Address",
                            "",
                          ),
                        ),
                        SizedBox(height: 20),

                        // Password
                        TextField(
                          controller: _passwordController,
                          cursorColor: Color(0xff238855),
                          obscureText: _obscurePass,
                          decoration: customInputDecoration(
                            "Password",
                            "",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePass = !_obscurePass;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Confirm Password
                        TextField(
                          controller: _confirmPasswordController,
                          cursorColor: Color(0xff238855),
                          obscureText: _obscureConfirm,
                          decoration: customInputDecoration(
                            "Confirm Password",
                            "",
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirm = !_obscureConfirm;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 30),

                        // Sign Up Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xfffd8536),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          onPressed: signUp,
                          child: Text(
                            "SIGN UP",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 25),

                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                "Or",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey)),
                          ],
                        ),
                        SizedBox(height: 25),

                        // Google Sign-In Button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            minimumSize: Size(double.infinity, 50),
                            side: BorderSide(color: Color(0xff238855)),
                          ),
                          onPressed: signUpWithGoogle,
                          icon: Image.asset(
                            "assets/google_logo.png",
                            height: 24,
                          ),
                          label: Text(
                            "Sign Up with Google",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(height: 30),

                        // Already have an account
                        Text.rich(
                          TextSpan(
                            text: "If you already have an account, ",
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: "Login Now",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xfffd8536),
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => LoginPage(),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
