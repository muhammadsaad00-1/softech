
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:soft/Login/profilecreation.dart';
import '../auth/auth_view_model.dart';
import '../auth/customTextField.dart';
import 'forgotpassword.dart';

class LoginViewUser extends StatefulWidget {
  LoginViewUser({super.key});

  @override
  _LoginViewUserState createState() => _LoginViewUserState();
}

class _LoginViewUserState extends State<LoginViewUser> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: h,
            width: w,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: h * 0.05),
                  Center(
                    child: Image.asset('assets/images/logo.png', height: 200),
                  ),
                  SizedBox(height: h * 0.01),
                  Text('Login',
                      style: GoogleFonts.roboto(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: h * 0.03),
                  Text('Email address',
                      style: GoogleFonts.poppins(
                          color: Colors.black54, fontSize: 12)),
                  SizedBox(height: h * 0.01),
                  TextField(
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: Colors.black54, size: 35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: "User@gmail.com",
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.black54, fontSize: 15),
                    ),
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  SizedBox(height: h * 0.02),
                  Text('Password',
                      style: GoogleFonts.poppins(
                          color: Colors.black54, fontSize: 12)),
                  SizedBox(height: h * 0.01),
                  customTextFields.defaultTextField(
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return "Kindly enter password";
                      }
                      return null;
                    },
                    obs: true,
                    hintText: "**********",
                    controller: passController,
                  ),
                  SizedBox(height: h * 0.01),
                  InkWell(
                    splashColor: Colors.transparent,
                    overlayColor: WidgetStatePropertyAll(Colors.transparent),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordView()));
                      // Handle Forgot Password
                    },
                    child: const Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        "Forgot password?",
                        style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor:  Colors.orange,
                            color:  Colors.orange,
                            fontSize: 15,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.04),
                  Align(
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: () async {
                        final email = emailController.text.trim();
                        final password = passController.text.trim();

                        if (email.contains("@bhc")) {
                          Fluttertoast.showToast(
                            msg: "This email belongs to an Admin",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                          return;
                        }

                        if (_formKey.currentState!.validate()) {
                          await authViewModel.login(email, password, context);
                        }
                      },
                      child: Container(
                        height: 60,
                        width: w * 0.9,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            "Log in",
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?",
                          style: TextStyle(
                              color:  Colors.orange,
                              fontSize: 15,
                              fontWeight: FontWeight.w400)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const ProfileCreationView()),
                          );
                        },
                        child: const Text("Sign up",
                            style: TextStyle(
                                color:  Colors.orange,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  SizedBox(height: h * 0.15),
                  Align(
                    alignment: Alignment.center,
                    child: Text('Privacy policy',
                        style: GoogleFonts.poppins(
                            decoration: TextDecoration.underline,
                            decorationColor:  Colors.orange,
                            color:  Colors.orange,
                            fontSize: 10)),
                  ),
                  SizedBox(height: h * 0.01),
                  Align(
                    alignment: Alignment.center,
                    child: Text('Terms of service',
                        style: GoogleFonts.poppins(
                            decoration: TextDecoration.underline,
                            decorationColor:  Colors.orange,
                            color:  Colors.orange,
                            fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
