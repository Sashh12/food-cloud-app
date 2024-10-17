// ignore_for_file: prefer_const_constructors

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/pages/forgotpasssword.dart';
import 'package:foodapp/pages/home.dart';
import 'package:foodapp/pages/signup.dart';
import 'package:foodapp/widget/widget_support.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  String email = "", password = "";
  final _formkey = GlobalKey<FormState>();

  TextEditingController usermailcontroller = new TextEditingController();
  TextEditingController userpasswordcontroller = new TextEditingController();

  userLogin()async{
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      Navigator.push(context, MaterialPageRoute(builder: (context) => BottomNav()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              "No User Found for that Email",
              style: TextStyle(fontSize: 20.0),
        )));
       } else if (e.code == "wrong-password") {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(
              "Wrong password Provided by User",
              style: TextStyle(fontSize: 20.0),
        )));
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
                      Color(0xFFFFDAB9),
                      Color(0xFFe74b1a),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.height / 3),
                height: MediaQuery.of(context).size.height /3,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                ),
                child: Text(" "),
              ),
              SingleChildScrollView(  // Added SingleChildScrollView
                child: Container(
                  margin: EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
                  child: Column(
                    children: [
                      Center(
                        child: Image.asset("images/Logo.png", width: MediaQuery.of(context).size.width / 1.5, fit: BoxFit.cover),
                      ),
                      SizedBox(height: 50.0),
                      GestureDetector(
                        onTap: () {
                          if (_formkey.currentState!.validate()) {
                            setState(() {
                              email = usermailcontroller.text;
                              password = userpasswordcontroller.text;
                            });
                          }
                          userLogin();
                        },
                        child: Material(
                          elevation: 5.0,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: EdgeInsets.only(left: 20.0, right: 20.0),
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height /2 ,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                            child: Form(
                              key: _formkey,
                              child: Column(
                                children: [
                                  SizedBox(height: 30.0),
                                  Text("Login", style: AppWidget.HeaderLineTextFieldStyle()),
                                  SizedBox(height: 30.0),
                                  TextFormField(
                                    controller: usermailcontroller,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please Enter Email';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(hintText: "Email",  prefixIcon: Icon(Icons.email_outlined)),
                                  ),
                                  SizedBox(height: 30.0),
                                  TextFormField(
                                    controller: userpasswordcontroller,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please Enter Password';
                                      }
                                      return null;
                                    },
                                    decoration: InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.password_outlined)),
                                  ),
                                  SizedBox(height: 20.0),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => ForgotPassword()));
                                    },
                                    child: Container(
                                      alignment: Alignment.topRight,
                                      child: Text("Forgot Password?", style: AppWidget.SemiBoldFieldStyle()),
                                    ),
                                  ),
                                  SizedBox(height: 60.0),
                                  Material(
                                    elevation: 5.0,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 8.0),
                                      width: 200,
                                      decoration: BoxDecoration(color: Color(0Xffff5722), borderRadius: BorderRadius.circular(20)),
                                      child: Center(
                                        child: Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 18.0, fontFamily: 'Poppins1', fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 70.0),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SignUp()));
                        },
                        child: Text("Don't have an account? Sign up", style: AppWidget.SemiBoldFieldStyle2()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
