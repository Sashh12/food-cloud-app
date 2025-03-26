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
    print("🚀 Starting Order Status Listener...");
    startOrderStatusListener();
  }

  Future<void> getUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    id = user?.uid;

    if (id != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(id).get();
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

      DateTime startOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

      subscriptions = subDocs.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime subscriptionDate =
        DateFormat('dd/MM/yy').parse(data['date']);

        if (subscriptionDate.isAfter(startOfWeek) &&
            subscriptionDate.isBefore(endOfWeek.add(Duration(days: 1)))) {
          data['id'] = doc.id;
          return data;
        }
        return null;
      }).where((data) => data != null).toList();

      setState(() {});
    }
  }

  Future<void> clearPastWeekSubscriptions() async {
    if (id != null) {
      DateTime startOfWeek =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

      QuerySnapshot subDocs = await FirebaseFirestore.instance
          .collection('subscribe')
          .doc(id)
          .collection('days')
          .get();

      for (var doc in subDocs.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime subscriptionDate =
        DateFormat('dd/MM/yy').parse(data['date']);

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
      String foodCategory,
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

        String subscribeOrderId =
            FirebaseFirestore.instance.collection("subscription_Orders").doc().id;

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
          "FoodCategory": foodCategory,  // ✅ FoodCategory is correctly saved
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error placing order: $e")));
      }
    }
  }

  void startOrderStatusListener() {
    FirebaseFirestore.instance.collection("subscription_Orders").snapshots().listen((snapshot) {
      print("🔄 Checking for active orders...");

      if (snapshot.docs.isEmpty) {
        print("🚫 No orders found.");
        return;
      }

      print("📦 Found ${snapshot.docs.length} orders.");

      for (var order in snapshot.docs) {
        String orderId = order.id;
        String orderStatus = order["orderStatus"];

        print("🔍 Checking Order ID: $orderId, Status: $orderStatus");

        if (orderStatus == "Completed") {
          print("✅ Order $orderId is completed. Moving to history...");

          moveToOrderHistory(orderId, order["userId"], order.data()).catchError((e) {
            print("❌ Error moving order $orderId to history: $e");
          });
        }
      }
    }, onError: (error) {
      print("❌ Firestore Listener Error: $error");
    });
  }

  Future<void> moveToOrderHistory(String orderId, String userId, Map<String, dynamic> orderData) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Reference to the order document
    DocumentReference orderRef = firestore.collection('subscription_Orders').doc(orderId);

    // Reference to order history collection
    CollectionReference orderHistoryRef = firestore.collection('order_history');

    print("🚚 Moving Order to History Immediately: $orderId");

    try {
      // Log the order data being moved
      print("📜 Order Data: ${orderData.toString()}");

      // Move order to history
      await orderHistoryRef.doc(orderId).set(orderData);
      print("✅ Order successfully moved to Order History!");

      // Remove order from the 'orders' collection immediately
      await orderRef.delete();
      print("🗑️ Order deleted from Active Orders!");

    } catch (e) {
      print("❌ Error moving order to history: $e");
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
          String foodCategory = subscription['FoodCategory'] ?? "Unknown";

          return Card(
            margin: EdgeInsets.all(8),
            child: SizedBox(
              height: 220, // Increased height to prevent overflow
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$day - $productName", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Date: $subscriptionDate"),
                    Text("Lunch Time: $lunchTime"),
                    Text("Dinner Time: $dinnerTime"),
                    Text("Price: ₹$price"),
                    Text("Kitchen: $kitchenName"),
                    Text("Category: $foodCategory"),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        isPaid
                            ? Text("Paid", style: TextStyle(color: Colors.green, fontSize: 18.0))
                            : ElevatedButton(
                          onPressed: () {
                            placeSubscriptionOrder(
                              day,
                              productName,
                              price,
                              subscriptionId,
                              subscriptionDate,
                              lunchTime,
                              foodCategory,
                              dinnerTime,
                            );
                          },
                          child: Text("Pay"),
                        ),
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
                          child: Text("Cancel",style: TextStyle(color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );

        },
      ),
    );
  }
}
