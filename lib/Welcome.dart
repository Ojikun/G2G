import 'package:flutter/material.dart';
import 'LogIn.dart';
import 'SignUp.dart';

void main() => runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomePage(),
    )
);

class WelcomePage extends StatefulWidget {
  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {

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
            SizedBox(height: 60),

            // Placeholder for image
            Container(
              height: 450,
              width: 400,
              color: Colors.white12,
              child: Icon(Icons.image, size: 50, color: Colors.grey),
            ),
            SizedBox(height: 40),

            Text(
              "Welcome to G2G.",
              style: TextStyle(color: Colors.teal[800], fontSize: 25),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),

            Text(
              "Get what you need, Give what you can.",
              style: TextStyle(color: Colors.black, fontSize: 19),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 60),


            // Sign Up Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: Text("SIGN UP", style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 20),


            // LogIn Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                minimumSize: Size(double.infinity, 50),
                side: BorderSide(color: Colors.teal),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (Context) => LoginPage()),
                );
              },
              label: Text("LOGIN", style: TextStyle(color: Colors.black)),
            ),

            Spacer(),

            // T&C Link
            Text.rich(
              TextSpan(
                text: "By Sign Up or Login, you have agreed to these ",
                style: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 2),

            Text.rich(
                TextSpan(
                  text: "Terms and Conditions",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[700]),
                )
            ),
            SizedBox(height: 30)
          ],
        ),
      ),
    );
  }
}
