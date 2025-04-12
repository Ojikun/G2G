import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:software_design/LogIn.dart';
import 'LogIn.dart';

void main() => runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignUpPage(),
    )
);

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 100),

            // Placeholder for image
            Container(
              height: 120,
              width: 280,
              color: Colors.white70,
              child: Icon(Icons.image, size: 50, color: Colors.grey),
            ),
            SizedBox(height: 20),

            Text(
              "Get what you need, Give what you can.",
              style: TextStyle(color: Colors.black, fontSize: 19),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),

            // Full Name
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Full Name",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            SizedBox(height: 30),

            // Email Input
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Email Address",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            SizedBox(height: 30),

            // Password Input with Toggle Visibility
            TextField(
              obscureText: _obscurePass,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Password",
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePass ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePass = !_obscurePass;
                    });
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
            SizedBox(height: 30),

            // Confirm Password
            TextField(
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Confirm Password",
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirm = !_obscureConfirm;
                    });
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey)),
              ),
            ),
            SizedBox(height: 40),

            // SignUp Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {},
              child: Text("SIGN UP", style: TextStyle(color: Colors.white)),
            ),

            SizedBox(height:40),

            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Colors.black)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text("Or", style: TextStyle(color: Colors.black)),
                ),
                Expanded(child: Divider(color: Colors.black)),
              ],
            ),

            SizedBox(height: 40),

            // Google Sign-In Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: Size(double.infinity, 50),
                side: BorderSide(color: Colors.teal),
              ),
              onPressed: () {},
              icon: Image.asset("assets/google_logo.png", height: 24),
              label: Text("Sign Up with Google", style: TextStyle(color: Colors.black)),
            ),

            Spacer(),

            // LogIn Link
            Text.rich(
              TextSpan(
                text: "If you already have an account, ",
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: "Login Now",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
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
    );
  }
}
