// ignore_for_file: prefer_const_constructors

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/Delivery%20boy/Dashboard.dart';
import 'package:foodapp/Delivery%20boy/delivery_signup.dart';
import 'package:foodapp/pages/forgotpasssword.dart';
import 'package:foodapp/widget/widget_support.dart';

class DeliveryBoyLogin extends StatefulWidget {
  const DeliveryBoyLogin({super.key});

  @override
  State<DeliveryBoyLogin> createState() => _DeliveryBoyLoginState();
}

class _DeliveryBoyLoginState extends State<DeliveryBoyLogin> {
  String email = "", password = "";
  final _formKey = GlobalKey<FormState>();

  TextEditingController deliveryMailController = TextEditingController();
  TextEditingController deliveryPasswordController = TextEditingController();

  userLogin() async {
    try {
      // Sign in the user with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      // Query Firestore for a delivery boy with a matching email
      QuerySnapshot<Map<String, dynamic>> deliverySnapshot =
      await FirebaseFirestore.instance
          .collection("delivery_boys")
          .where('Email', isEqualTo: email)
          .limit(1)
          .get();

      // Check if any document is returned
      if (deliverySnapshot.docs.isNotEmpty) {
        // If delivery boy document exists, navigate to DeliveryHome page
        Navigator.push(context,MaterialPageRoute(builder: (context) => DeliveryHome()),);
      } else {
        // If no delivery boy is found with the provided email
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "No Delivery Boy found for this Email",
            style: TextStyle(fontSize: 20.0),
          ),
        ));
      }
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth errors
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "No User Found for that Email",
            style: TextStyle(fontSize: 20.0),
          ),
        ));
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "Wrong Password Provided by User",
            style: TextStyle(fontSize: 20.0),
          ),
        ));
      }
    } catch (e) {
      // Catch any other errors
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.orangeAccent,
        content: Text(
          "An error occurred. Please try again.",
          style: TextStyle(fontSize: 20.0),
        ),
      ));
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
                height: MediaQuery.of(context).size.height /2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFDAB9),
                      Color(0xFFe74b1a),
                    ],
                  ),),
              ),
              Container(
                margin: EdgeInsets.only(top: MediaQuery.of(context).size.height/3),
                height: MediaQuery.of(context).size.height /3,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(40),topRight: Radius.circular(40))),
                child: Text(" "),
              ),
              Container(
                margin: EdgeInsets.only(top: 60.0,left: 20.0,right: 20.0,),
                child: Column(children: [
                  Center(child: Image.asset("images/Logo.png", width: MediaQuery.of(context).size.width/1.5,fit: BoxFit.cover,)),
                  SizedBox(height: 50.0,),
                  GestureDetector(
                    onTap: (){
                      if(_formKey.currentState!.validate()){
                        setState(() {
                          email= deliveryMailController.text;
                          password= deliveryPasswordController.text;
                        });
                      }
                      userLogin();
                    },
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.only(left: 20.0,right: 20.0,),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height /2,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Form(
                          key: _formKey,
                          child: Column(children: [
                            SizedBox(height: 30.0,),
                            Text("Login as Delivery Boy", style: AppWidget.SemiBoldFieldStyle(),),
                            SizedBox(height: 30.0,),
                            TextFormField(
                              controller: deliveryMailController,
                              validator: (value){
                                if(value==null || value.isEmpty){
                                  return 'Please Enter Email';
                                }
                                return null;
                              },
                              decoration: InputDecoration(hintText:"Email",  prefixIcon: Icon(Icons.email_outlined) ),
                            ),
                            SizedBox(height: 30.0,),
                            TextFormField(
                              controller: deliveryPasswordController,
                              validator: (value){
                                if(value==null || value.isEmpty){
                                  return 'Please Enter Password';
                                }
                                return null;
                              },
                              decoration: InputDecoration(hintText:"Password",  prefixIcon: Icon(Icons.password_outlined) ),
                            ),
                            SizedBox(height: 20.0,),
                            GestureDetector(
                              onTap: (){
                                // Navigator.push(context, MaterialPageRoute(builder: (context)=>ForgotPasswordKitchen()));
                              },
                              child: Container(
                                  alignment: Alignment.topRight,
                                  child: Text("Forgot Password?", style: AppWidget.SemiBoldFieldStyle(),)),
                            ),
                            SizedBox(height: 40.0,),
                            Material(
                              elevation: 5.0,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                width: 200,
                                decoration: BoxDecoration(color: Color(0Xffff5722), borderRadius: BorderRadius.circular(20)),
                                child: Center(child: Text("LOGIN", style: TextStyle(color: Colors.white, fontSize: 18.0,
                                    fontFamily: 'Poppins1', fontWeight: FontWeight.bold),)
                                ),),
                            ),
                          ],),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50.0,),
                  GestureDetector(
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=> DeliveryBoySignUp()));
                      },
                      child: Text("Don't have an account? Sign up", style: AppWidget.SemiBoldFieldStyle2(),)),
                  SizedBox(height: 20.0,),
                  // GestureDetector(
                  //   onTap: () {
                  //     Navigator.push(context, MaterialPageRoute(builder: (context) => LogIn()),);
                  //   },
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.center,
                  //     children: [
                  //       Text("Back to Customer login", style: TextStyle( color: Color(0xFF2E2D2E), fontSize: 20.0, fontWeight: FontWeight.w200, fontFamily: 'Poppins',),),
                  //       SizedBox(width: 8.0), // Adds spacing between the text and the icon
                  //       Icon(Icons.arrow_forward, color: Colors.black54,),
                  //     ],
                  //   ),
                  // )

                ],),
              )
            ],
          ),
        ),
      ),
    );
  }
}
