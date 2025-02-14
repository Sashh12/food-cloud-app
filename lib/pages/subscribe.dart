import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:intl/intl.dart';

class SubscribePage extends StatefulWidget {
  @override
  _SubscribePageState createState() => _SubscribePageState();
}

class _SubscribePageState extends State<SubscribePage> {
  String? id;
  String? wallet;
  List<dynamic> subscriptions = [];

  @override
  void initState() {
    super.initState();
    getUserData();
    fetchSubscriptions();
    clearPastWeekSubscriptions();
  }

  Future<void> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    id = user?.uid;

    if (id != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(id)
          .get();
      wallet = userDoc["Wallet"];
    }

    setState(() {});
  }

  Future<void> fetchSubscriptions() async {
    if (id != null) {
      QuerySnapshot subDocs = await FirebaseFirestore.instance
          .collection('subscribe')
          .doc(id)
          .collection('days')
          .get();

      DateTime startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

      subscriptions = subDocs.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime subscriptionDate = DateFormat('dd/MM/yy').parse(data['date']);
        return subscriptionDate.isAfter(startOfWeek) &&
            subscriptionDate.isBefore(endOfWeek.add(Duration(days: 1)));
      }).map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // Add lunchTime and dinnerTime to the subscription data
        data['lunchTime'] = data['lunchTime']; // Assuming lunchTime is stored as a String
        data['dinnerTime'] = data['dinnerTime']; // Assuming dinnerTime is stored as a String

        return data;
      }).toList();

      setState(() {});
    }
  }

  Future<void> clearPastWeekSubscriptions() async {
    if (id != null) {
      // Define the start of the current week
      DateTime startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

      // Clear past subscriptions from 'subscribe' collection
      QuerySnapshot subDocs = await FirebaseFirestore.instance
          .collection('subscribe')
          .doc(id)
          .collection('days')
          .get();

      for (var doc in subDocs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime subscriptionDate = DateFormat('dd/MM/yy').parse(data['date']);

        if (subscriptionDate.isBefore(startOfWeek)) {
          await FirebaseFirestore.instance
              .collection('subscribe')
              .doc(id)
              .collection('days')
              .doc(doc.id)
              .delete();
        }
      }

      // Clear past subscriptions from 'subscription_Orders' collection
      QuerySnapshot orderDocs = await FirebaseFirestore.instance
          .collection('subscription_Orders')
          .where('userId', isEqualTo: id)
          .get();

      for (var doc in orderDocs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime subscriptionDate = (data['date'] as Timestamp).toDate(); // Ensure proper date parsing

        if (subscriptionDate.isBefore(startOfWeek)) {
          await FirebaseFirestore.instance
              .collection('subscription_Orders')
              .doc(doc.id)
              .delete();
        }
      }

      setState(() {});
    }
  }

  Future<void> placeSubscriptionOrder(
      String day,
      String productName,
      String price,
      String subscriptionId,
      String subscriptionDate,
      String lunchTime,
      String dinnerTime) async {
    if (id != null && wallet != null) {
      try {
        int currentWalletAmount = int.parse(wallet!);
        int priceToPay = int.parse(price);

        if (currentWalletAmount < priceToPay) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Insufficient balance in wallet")));
          return;
        }

        int newWalletAmount = currentWalletAmount - priceToPay;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .update({"Wallet": newWalletAmount.toString()});

        String subscribeOrderId = FirebaseFirestore.instance.collection("subscription_Orders").doc().id;

        await FirebaseFirestore.instance
            .collection("subscription_Orders")
            .doc(subscribeOrderId)
            .set({
          "userId": id,
          "day": day,
          "productName": productName,
          "price": price,
          "orderDate": Timestamp.now(),
          "date": subscriptionDate,
          "lunchTime": lunchTime,   // Directly use the string lunchTime
          "dinnerTime": dinnerTime, // Directly use the string dinnerTime
        });

        await FirebaseFirestore.instance
            .collection('subscribe')
            .doc(id)
            .collection('days')
            .doc(subscriptionId)
            .update({"isPaid": true});

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Order placed for $day: $productName")));

        await fetchSubscriptions();
      } catch (e) {
        print("Error placing subscription order: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error placing order: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => BottomNav()));
          },
        ),
        title: Text("Subscribe & Save"),
        centerTitle: true,
      ),
      body: subscriptions.isEmpty
          ? Center(child: Text("No subscriptions yet for the week"))
          : ListView.builder(
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          var subscription = subscriptions[index];
          String day = subscription['day'];
          String subscriptionDate = subscription['date'];
          String productName = subscription['productName'];
          String price = subscription['price'];
          bool isPaid = subscription['isPaid'] ?? false;
          String subscriptionId = subscription['id'];

          // Get the lunch and dinner times from the subscription
          String lunchTime = subscription['lunchTime'] ?? "N/A"; // Default to "N/A" if not found
          String dinnerTime = subscription['dinnerTime'] ?? "N/A"; // Default to "N/A" if not found

          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text("$day - $productName"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Date: $subscriptionDate"),
                  Text("Lunch Time: $lunchTime"),
                  Text("Dinner Time: $dinnerTime"),
                  Text("Price: ₹$price"),
                ],
              ),
              trailing: isPaid? Text("Paid", style: TextStyle(color: Colors.green, fontSize: 18.0)) : ElevatedButton(onPressed: () {
                placeSubscriptionOrder(day, productName, price, subscriptionId, subscriptionDate, lunchTime, dinnerTime);},
                child: Text("Pay"),
              ),
            ),
          );
        },
      ),
    );
  }
}
