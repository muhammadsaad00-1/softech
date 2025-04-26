import 'signUp_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'loginviewuser.dart';

class InitialPage extends StatefulWidget {
  const InitialPage({super.key});

  @override
  State<InitialPage> createState() => _InitialPageState();
}

class _InitialPageState extends State<InitialPage> {
  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          SystemNavigator.pop(); // Closes the app smoothly
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 200,
              ),
              SizedBox(height: h * 0.05),
              // Sign Up Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.1),
                child: InkWell(
                  onTap: () async {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupOptionsView()));
                  },
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: h * 0.02),
              // Login Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.1),
                child: InkWell(
                  onTap: () async {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => LoginViewUser()));
                    // Add login logic here
                  },
                  child: Container(
                    height: 60,
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: h * 0.15),
              // Privacy Policy
              Text(
                'Privacy policy',
                style: GoogleFonts.poppins(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.orange,
                  color:  Colors.orange,
                  fontSize: 10,
                ),
              ),
              SizedBox(height: h * 0.01),
              // Terms of Service
              Text(
                'Terms of service',
                style: GoogleFonts.poppins(
                  decoration: TextDecoration.underline,
                  decorationColor:  Colors.orange,
                  color:  Colors.orange,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
