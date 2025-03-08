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
        data['lunchTime'] = data['lunchTime'];
        data['dinnerTime'] = data['dinnerTime'];
        data['kitchenName'] = data['kitchenName'];
        return data;
      }).toList();

      setState(() {});
    }
  }

  Future<void> clearPastWeekSubscriptions() async {
    if (id != null) {
      DateTime startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

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

      QuerySnapshot orderDocs = await FirebaseFirestore.instance
          .collection('subscription_Orders')
          .where('userId', isEqualTo: id)
          .get();

      for (var doc in orderDocs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime subscriptionDate = (data['date'] as Timestamp).toDate();

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
        DocumentSnapshot subscriptionDoc = await FirebaseFirestore.instance
            .collection('subscribe')
            .doc(id)
            .collection('days')
            .doc(subscriptionId)
            .get();

        String kitchenName = subscriptionDoc['kitchenName'] ?? "Unknown";

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
          "lunchTime": lunchTime,
          "dinnerTime": dinnerTime,
          "kitchenName": kitchenName,
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
          String kitchenName = subscription['kitchenName'];
          String subscriptionDate = subscription['date'];
          String productName = subscription['productName'];
          String price = subscription['price'];
          bool isPaid = subscription['isPaid'] ?? false;
          String subscriptionId = subscription['id'];

          String lunchTime = subscription['lunchTime'] ?? "N/A";
          String dinnerTime = subscription['dinnerTime'] ?? "N/A";

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
                  Text("Kitchen: $kitchenName"),
                ],
              ),
              trailing: isPaid
                  ? Text("Paid", style: TextStyle(color: Colors.green, fontSize: 18.0))
                  : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      placeSubscriptionOrder(
                        day,
                        productName,
                        price,
                        subscriptionId,
                        subscriptionDate,
                        lunchTime,
                        dinnerTime,
                      );
                    },
                    child: Text("Pay"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      bool? confirmCancel = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Cancel Subscription"),
                          content: Text("Are you sure you want to cancel this subscription?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text("No"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text("Yes"),
                            ),
                          ],
                        ),
                      );

                      if (confirmCancel == true) {
                        await FirebaseFirestore.instance
                            .collection('subscribe')
                            .doc(id)
                            .collection('days')
                            .doc(subscriptionId)
                            .delete();

                        QuerySnapshot orderDocs = await FirebaseFirestore.instance
                            .collection('subscription_Orders')
                            .where('userId', isEqualTo: id)
                            .where('subscriptionId', isEqualTo: subscriptionId)
                            .get();

                        for (var orderDoc in orderDocs.docs) {
                          await FirebaseFirestore.instance
                              .collection('subscription_Orders')
                              .doc(orderDoc.id)
                              .delete();
                        }

                        await fetchSubscriptions();

                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Subscription canceled successfully"),
                        ));
                      }
                    },
                    child: Text("Cancel"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
