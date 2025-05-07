import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Center(
        child: Image.asset(
          'assets/logo.png',
          width: 80,
          height: 50,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
