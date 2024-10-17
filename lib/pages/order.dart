import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/pages/home.dart';
import 'package:foodapp/service/database.dart';
import 'package:foodapp/widget/widget_support.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  String? id, wallet;
  int total = 0, amount2 = 0;

  Stream? foodStream;

  @override
  void initState() {
    super.initState();
    ontheload();
    startTimer();
  }

  void startTimer() {
    Timer(Duration(seconds: 2), () {
      amount2 = total;
      setState(() {});
    });
  }

  // Fetch the user ID and wallet directly from Firebase
  Future<void> getUserData() async {
    // Fetch the current user's ID from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;
    id = user?.uid;

    if (id != null) {
      // Fetch the wallet from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();
      wallet = userDoc["Wallet"];
    }

    setState(() {});
  }

  ontheload() async {
    await getUserData();
    if (id != null) {
      foodStream = await DatabaseMethods().getFoodCart(id!);
      setState(() {});
    }
  }

  Widget foodCart() {
    return StreamBuilder(
      stream: foodStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: snapshot.data.docs.length,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snapshot.data.docs[index];
                total = total + int.parse(ds["Total"]);
                return Container(
                  margin: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration( borderRadius: BorderRadius.circular(20),),
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Container( height: 50.0, width: 40.0,
                            decoration: BoxDecoration(
                              border: Border.all(), borderRadius: BorderRadius.circular(10),),
                            child: Center(child: Text(ds["Quantity"])),
                          ),
                          SizedBox(width: 10.0),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.network( ds["Image"], height: 90, width: 90, fit: BoxFit.cover,),
                          ),
                          SizedBox(width: 10.0),
                          Expanded( // Make the Column take available space
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                              children: [
                                Text(ds["Name"], style: AppWidget.NormalText(), maxLines: 2, // Allow two lines
                                  overflow: TextOverflow.ellipsis,),
                                Text( "₹ " + ds["Total"], style: AppWidget.NormalText(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              });
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<void> placeOrder() async {
    // Ensure id and wallet are not null
    if (id != null && wallet != null) {
      int amount = int.parse(wallet!) - amount2;

      // Update the user's wallet in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .update({"wallet": amount.toString()});

      // Fetch cart items from Firestore
      var cartItems = await FirebaseFirestore.instance
          .collection("users")
          .doc(id)
          .collection("Cart")
          .get();

      // Create an order document in Firestore
      String orderId = FirebaseFirestore.instance.collection("orders").doc().id;
      await FirebaseFirestore.instance.collection("orders").doc(orderId).set({
        "userId": id,
        "totalAmount": total,
        "orderDate": Timestamp.now(),
        "items": cartItems.docs.map((doc) => doc.data()).toList(),
      });

      // Clear cart items after placing the order
      for (var doc in cartItems.docs) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(id)
            .collection("Cart")
            .doc(doc.id)
            .delete();
      }

      // Display confirmation message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          "Order placed successfully!",
          style: TextStyle(fontSize: 18.0),
        ),
        duration: Duration(seconds: 2),
      ));

      // Wait for 2 seconds and navigate to the home page
      await Future.delayed(Duration(seconds: 2));

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Home()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 2.0,
              child: Container(
                padding: EdgeInsets.only(bottom: 10.0),
                child: Center(child: Text("Food Cart")),
              ),
            ),
            SizedBox(height: 20.0),
            Container(
              height: MediaQuery.of(context).size.height / 2,
              child: foodCart(),
            ),
            Spacer(),
            Divider(),
            Padding(
              padding: EdgeInsets.only(left: 10.0, right: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Price", style: AppWidget.BoldTextFieldStyle()),
                  Text("\₹ " + total.toString(),
                      style: AppWidget.SemiBoldFieldStyle()),
                ],
              ),
            ),
            SizedBox(height: 20.0),
            GestureDetector(
              onTap: () async {
                await placeOrder();
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10)),
                margin:
                EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
                child: Center(
                    child: Text("Checkout", style: TextStyle( color: Colors.white, fontSize: 20.0,
                            fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
