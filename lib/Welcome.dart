import 'package:flutter/material.dart';
import 'LogIn.dart';
import 'SignUp.dart';

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 30),

                      // Flexible image placeholder
                      Container(
                        height: screenHeight * 0.42, // 35% of screen height
                        width: double.infinity,
                        color: Colors.white12,
                        child: Image.asset(
                          'assets/welcome.png',
                          width: 150, // You can adjust size
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 10),

                      Container(
                        height: screenHeight * 0.08, // 35% of screen height
                        width: double.infinity,
                        color: Colors.white12,
                        child: Image.asset(
                          'assets/logo.png',
                          width: 150, // You can adjust size
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 10),

                      Text(
                        "Give what you can. Get what you need.",
                        style: TextStyle(color: Colors.black, fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 50),

                      // Sign Up Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xfffd8536),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpPage(),
                            ),
                          );
                        },
                        child: Text(
                          "SIGN UP",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 25),

                      // LogIn Button
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: Size(double.infinity, 50),
                          side: BorderSide(color: Color(0xff238855)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ),
                          );
                        },
                        child: Text(
                          "LOGIN",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 25),

              // T&C Text moved at the bottom
              Text.rich(
                TextSpan(
                  text: "By Signing Up or Logging in, you agree to our ",
                  style: TextStyle(color: Colors.black, fontSize: 12),
                  children: [
                    TextSpan(
                      text: "Terms and Conditions.",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xfffd8536),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
