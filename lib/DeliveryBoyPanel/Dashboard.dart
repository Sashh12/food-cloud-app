import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/DeliveryBoyPanel/delivery_signup.dart';
import 'package:foodapp/DeliveryBoyPanel/deliveryorders.dart';
import 'package:foodapp/service/auth.dart';

class DeliveryHome extends StatefulWidget {
  @override
  _DeliveryHomeState createState() => _DeliveryHomeState();
}

class _DeliveryHomeState extends State<DeliveryHome> {
  int totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    fetchEarnings();
  }

  Future<void> fetchEarnings() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      print('Logged-in delivery boy UID: $uid');
      final doc = await FirebaseFirestore.instance
          .collection('delivery_boys')
          .doc(uid)
          .get();

      if (doc.exists) {
        final earningsRaw = doc.data()?['earnings'] ?? '0';
        setState(() {
          totalEarnings = int.tryParse(earningsRaw.toString()) ?? 0;
        });
      } else {
        print('Document not found for delivery boy.');
      }
    } catch (e) {
      print('Error fetching earnings: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Boy Panel'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              AuthMethods().SignOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DeliveryBoySignUp(),
                ), // Replace 'SignUpPage' with your actual signup widget
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Dashboard
            Container(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  // Add dashboard widgets here (e.g., metrics, summary)
                ],
              ),
            ),
            // Order Management
            GestureDetector(
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryOrders()));
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.0),
                child: Material(
                  borderRadius: BorderRadius.circular(10),
                  elevation: 2.0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0,),
                    decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.restaurant_menu, color: Colors.black,),
                        SizedBox(width: 20.0,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Orders",style: TextStyle(color: Colors.black,
                                fontSize: 20.0,fontWeight: FontWeight.w600),)
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            //Profile Management
            SizedBox(height: 30.0,),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 2.0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0,),
                  decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.black,),
                      SizedBox(width: 20.0,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Profile",style: TextStyle(color: Colors.black,
                                fontSize: 20.0,fontWeight: FontWeight.w600),)
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.0,),
            // Earnings & Payments
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              child: Material(
                borderRadius: BorderRadius.circular(10),
                elevation: 2.0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0,),
                  decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(Icons.money_rounded, color: Colors.black,),
                      SizedBox(width: 20.0,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Earnings: ₹$totalEarnings", style: TextStyle(
                              color: Colors.black, fontSize: 20.0, fontWeight: FontWeight.w600)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
