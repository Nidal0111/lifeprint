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
        .createUserWithEmailAndPassword(email: EmailAddress, password: Password);
    User? user = userCredential.user;
    await FirebaseFirestore.instance.collection("users").doc(user?.uid).set({
      "Full Name": FullName,
      "Email Address": EmailAddress,
    });ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("User created successfully ")));
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
