import 'package:firebase_auth/firebase_auth.dart';


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
  Future deleteUser() async {
    User? user = await FirebaseAuth.instance.currentUser;
    user?.delete();
  }
}


