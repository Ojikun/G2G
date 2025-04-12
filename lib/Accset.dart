import 'package:flutter/material.dart';

void main() {
  runApp(AccsetApp());
}

class AccsetApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AccsetScreen(),
    );
  }
}

class AccsetScreen extends StatefulWidget {
  @override
  _AccsetScreenState createState() => _AccsetScreenState();
}

class _AccsetScreenState extends State<AccsetScreen> {
  bool _obscurePass = true;

  InputDecoration customInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(50),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
        borderRadius: BorderRadius.circular(50),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
    );
  }

  Widget settingsButton(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: () {},
                    ),
                  ),
                  Text(
                    "G2G",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Account Information Header
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Account Information",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Email Text Field
              TextField(
                decoration: customInputDecoration("Email Address", "here@email.com"),
              ),
              SizedBox(height: 30),
              TextField(
                decoration: customInputDecoration("Phone Number", "+639123456789"),
              ),
              SizedBox(height: 30),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 380),
              settingsButton("EDIT INFORMATION"),
            ],
          ),
        ),
      ),
    );
  }
}
