import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<void> Registerss({
  required String FullName,
  required String EmailAddress,
  required String Password,
  required String ConfirmPassword,
  required BuildContext context,
}) async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
          email: EmailAddress,
          password: Password,
        );
    User? user = userCredential.user;
    await FirebaseFirestore.instance.collection("users").doc(user?.uid).set({
      "Full Name": FullName,
      "Email Address": EmailAddress,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("User created successfully"),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<void> loginPage({
  required String EmailAddress,
  required String Password,
  required BuildContext context,
}) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: EmailAddress,
      password: Password,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("User login successfully"),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

Future<void> forgotten({
  required String Email,

  required BuildContext context,
}) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: Email);
   ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Check your inbox"),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
