import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/pages/login.dart';
import 'package:foodapp/service/database.dart';
import 'package:foodapp/Kitchen/Kitchen_login.dart';
import 'package:foodapp/widget/widget_support.dart';
import 'package:random_string/random_string.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = "", password = "", name = "";
  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  registration() async {
    if (password.isNotEmpty && namecontroller.text.isNotEmpty && mailcontroller.text.isNotEmpty) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        User? user = userCredential.user;

        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Registered Successfully", style: TextStyle(fontSize: 20.0),)));

          // Use the UID from Firebase Auth
          String uid = user.uid;

          // Create the user document with UID as document ID
          Map<String, dynamic> addUserInfo = {
            "Name": namecontroller.text,
            "Email": mailcontroller.text,
            "Wallet": "0",
            "Loyalty": 0,
            "Id": uid, // Store UID instead of random ID
          };

          // Store user details in Firestore
          await FirebaseFirestore.instance.collection('users').doc(uid).set(addUserInfo);

          // Navigate to BottomNav after successful registration
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNav()));
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text("Password provided is too weak", style: TextStyle(fontSize: 18.0),)));
        } else if (e.code == "email-already-in-use") {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orangeAccent,
              content: Text("Account already exists", style: TextStyle(fontSize: 18.0),)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFD5C5),
                      Color(0xFFFA7474),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
                height: MediaQuery.of(context).size.height / 2.5,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40))),
              ),
              Container(
                margin: EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
                child: Column(children: [
                  Center(child: Image.asset("images/Logo.png", width: MediaQuery.of(context).size.width / 1.5, fit: BoxFit.cover)),
                  SizedBox(height: 50.0),
                  Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.only(left: 20.0, right: 20.0),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height / 1.9,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Form(
                        key: _formkey,
                        child: Column(children: [
                          SizedBox(height: 30.0),
                          Text("Sign Up", style: AppWidget.HeaderLineTextFieldStyle()),
                          SizedBox(height: 30.0),
                          TextFormField(
                            controller: namecontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter name';
                              }
                              return null;
                            },
                            decoration: InputDecoration(hintText: "Name",  prefixIcon: Icon(Icons.person_outline)),
                          ),
                          SizedBox(height: 30.0),
                          TextFormField(
                            controller: mailcontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email';
                              }
                              return null;
                            },
                            decoration: InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email_outlined)),
                          ),
                          SizedBox(height: 30.0),
                          TextFormField(
                            controller: passwordcontroller,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              return null;
                            },
                            obscureText: true,
                            decoration: InputDecoration(hintText: "Password",  prefixIcon: Icon(Icons.password_outlined)),
                          ),
                          SizedBox(height: 40.0),
                          GestureDetector(
                            onTap: () async {
                              if (_formkey.currentState!.validate()) {
                                setState(() {
                                  email = mailcontroller.text;
                                  name = namecontroller.text;
                                  password = passwordcontroller.text;
                                });
                                registration();
                              }
                            },
                            child: Material(
                              elevation: 5.0,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                width: 200,
                                decoration: BoxDecoration(color: Color(0xFFFF4444), borderRadius: BorderRadius.circular(20)),
                                child: Center(child: Text("SIGNUP", style: TextStyle(color: Colors.white, fontSize: 18.0, fontFamily: 'Poppins1', fontWeight: FontWeight.bold))),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  SizedBox(height: 50.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => LogIn()));
                    },
                    child: Text("Already have an account? Login", style: AppWidget.SemiBoldFieldStyle2()),
                  ),
                  SizedBox(height: 20.0),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => VendorLogin()));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Login as Cloud Kitchen", style: TextStyle(color: Color(0xFF2E2D2E), fontSize: 20.0, fontWeight: FontWeight.w200, fontFamily: 'Poppins')),
                        SizedBox(width: 8.0),
                        Icon(Icons.arrow_forward, color: Colors.black54),
                      ],
                    ),
                  ),
                ]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
