import 'package:flutter/material.dart';

class AppWidget{
  static TextStyle  BoldTextFieldStyle(){
    return TextStyle( color: Colors.black, fontSize: 30.0,
    fontWeight: FontWeight.bold, fontFamily: 'Poppins');
  }

  static TextStyle  HeaderLineTextFieldStyle(){
    return TextStyle( color: Colors.black, fontSize: 32.0,
        fontWeight: FontWeight.bold, fontFamily: 'Poppins');
  }

  static TextStyle  LightTextFieldStyle(){
    return TextStyle( color: Colors.black45, fontSize: 18.0,
        fontWeight: FontWeight.w300, fontFamily: 'Poppins');
  }

  static TextStyle  LightTextFieldStyle2(){
    return TextStyle( color: Colors.black45, fontSize: 15.0,
        fontWeight: FontWeight.w100, fontFamily: 'Poppins');
  }

  static TextStyle  SemiBoldFieldStyle(){
    return TextStyle( color: Colors.black, fontSize: 25.0,
        fontWeight: FontWeight.w500, fontFamily: 'Poppins');
  }
  static TextStyle  SemiBoldFieldStyle2(){
    return TextStyle( color: Colors.black, fontSize: 20.0,
        fontWeight: FontWeight.w200, fontFamily: 'Poppins');
  }

  static TextStyle  FoodNameText(){
    return TextStyle( color: Colors.black, fontSize: 17.0,
        fontWeight: FontWeight.w100, fontFamily: 'Poppins');
  }

  static TextStyle  NormalText(){
    return TextStyle( color: Colors.black, fontSize: 18.0,
        fontWeight: FontWeight.w100, fontFamily: 'Poppins');
  }

  static TextStyle normalText() {
    return TextStyle( color: Colors.black, fontSize: 18.0,
      fontFamily: 'Vollkorn');
  }

}