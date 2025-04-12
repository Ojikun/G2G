import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:software_design/SignUp.dart';
import 'SignUp.dart';

void main() => runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    )
);

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;

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
              height: 150,
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
            SizedBox(height: 60),

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
              obscureText: _obscureText,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Password",
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),

            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Forgot Password?",
                style: TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),

            SizedBox(height: 40),

            // Login Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {},
              child: Text("LOGIN", style: TextStyle(color: Colors.white)),
            ),

            SizedBox(height: 40),

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

            // Google Sign-In Button (White Background, Black Text)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: Size(double.infinity, 50),
                side: BorderSide(color: Colors.teal),
              ),
              onPressed: () {},
              icon: Image.asset("assets/google_logo.png", height: 24),
              label: Text("Login with Google", style: TextStyle(color: Colors.black)),
            ),

            Spacer(),

            // Sign Up Link
            Text.rich(
              TextSpan(
                text: "If you don't have an account, ",
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: "Sign Up Now",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpPage()),
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
