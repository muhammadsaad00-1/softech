
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Login/initialpage.dart';
import '../homeview.dart';
import 'authRepo.dart';
import 'utils.dart';

class AuthViewModel with ChangeNotifier {
  final repo = AuthRepository();
  final auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? _user;
  int currentTab = 0;

  User? get user => _user;

  AuthViewModel() {
    auth.authStateChanges().listen((User? user) async {
      _user = user;
      notifyListeners();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', user != null);
    });
  }
  Future<void> sendPasswordResetLink(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e);
    }
  }

  Future<UserCredential?> loginwithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        Utils.snackBar('Google Sign-In canceled', context);
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        _user = userCredential.user;
        notifyListeners();

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        // Save user to Firestore
        DocumentReference userRef =
            _firestore.collection('users').doc(_user!.uid);
        DocumentSnapshot userDoc = await userRef.get();

        if (!userDoc.exists) {
          await userRef.set({
            'uid': _user!.uid,
            'name': _user!.displayName ?? "Unknown",
            'email': _user!.email ?? "",
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Navigate to Home after successful login
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomeView(emotion: "Normal")));

        return userCredential;
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
      Utils.snackBar('Google Sign-In failed: ${e.toString()}', context);
    }
    return null;
  }

  bool get isLoggedIn => _user != null;

  /// **Sign Up and Create User Document in Firestore**
  Future<void> signup(String email, String password, String name,
      String contact, BuildContext context) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty || contact.isEmpty) {
      Utils.snackBar('Please fill in all fields', context);
      return;
    }

    try {
      UserCredential userCredential =
          await repo.signUp(email, password, name, context);

      if (userCredential.user != null) {
        _user = userCredential.user;
        await _createUserInFirestore(_user!.uid, name, email, contact);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        notifyListeners();
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) =>  HomeView(emotion: "Normal")));
      }
    } catch (e) {
      Utils.snackBar('Signup failed: ${e.toString()}', context);
    }
  }

  /// **Create User Document in Firestore**
  Future<void> _createUserInFirestore(
      String userId, String name, String email, String contact) async {
    DocumentReference userDoc = _firestore.collection('users').doc(userId);

    try {
      DocumentSnapshot snapshot = await userDoc.get();
      if (!snapshot.exists) {
        await userDoc.set({
          'userId': userId,
          'name': name,
          'email': email,
          'contact': contact,
          'createdAt': FieldValue.serverTimestamp(),
          'projects': [],
        });
      }
    } catch (e) {
      print("Error creating user in Firestore: $e");
    }
  }

  /// **Login and Fetch User Data**
  Future<void> login(
      String email, String password, BuildContext context) async {
    if (email.isEmpty || password.isEmpty) {
      Utils.snackBar('Please fill in all fields', context);
      return;
    }

    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (userCredential.user != null) {
        _user = userCredential.user;

        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(_user!.uid).get();
        if (!userDoc.exists) {
          await _createUserInFirestore(_user!.uid, "Unknown", email, "");
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        notifyListeners();

        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const HomeView(emotion: "Normal"),
              ));
          Utils.snackBar('Logged in successfully', context);
        });
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Utils.snackBar('No user found for that email.', context);
      } else if (e.code == 'wrong-password') {
        Utils.snackBar('Wrong password provided.', context);
      } else {
        Utils.snackBar(e.message ?? 'An error occurred', context);
      }
    } catch (e) {
      Utils.snackBar('An error occurred. Please try again.', context);
    }
  }

  /// **Logout and Clear Login State**
  Future<void> logout(BuildContext context) async {
    try {
      await auth.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      _user = null;
      notifyListeners();
      Navigator.push(context, MaterialPageRoute(builder: (context)=> InitialPage()));
    } catch (e) {
      Utils.snackBar('Logout failed: ${e.toString()}', context);
    }
  }

  void changeActiveTab(int index) {
    currentTab = index;
    notifyListeners();
  }
}
