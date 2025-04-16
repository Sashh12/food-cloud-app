import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/pages/onboard.dart';


class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  // Function to get the current user
  getCurrentUser() async {
    return await auth.currentUser;
  }

  // Function to sign out the user
  Future SignOut() async {
    await FirebaseAuth.instance.signOut();

  }

  // Function to delete the current user
  // Future deleteUser() async {
  //   User? user = await FirebaseAuth.instance.currentUser;
  //   user?.delete();
  // }
  Future<void> deleteUser(BuildContext context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

        // Delete user from FirebaseAuth
        await user.delete();

        // Navigate to Onboard screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Onboard()),
        );
      }
    } catch (e) {
      print("Error deleting user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting account: $e")),
      );
    }
  }
}


