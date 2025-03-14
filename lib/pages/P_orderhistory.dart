import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/service/database.dart';

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<QuerySnapshot>? _userOrderHistoryStream;
  Stream<QuerySnapshot>? _userCurrentOrderStream;

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
    _fetchCurrentOrders();
  }

  // Fetch all past orders (Completed within the last week)
  void _fetchOrderHistory() {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      DateTime oneWeekAgo = DateTime.now().subtract(Duration(days: 7));

      _userOrderHistoryStream = _firestore
          .collection('order_history')
          .where('userId', isEqualTo: userId) // Filter orders for the current user
          .where('KitchenorderStatus', isEqualTo: 'Completed') // Fetch only completed orders
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo)) // Ensure orderDate is within last week
          .orderBy('orderDate', descending: true) // Sort orders by latest first
          .snapshots();
    }
  }

  // Fetch Current Orders (Pending or Preparing)
  void _fetchCurrentOrders() {
    final userId = _auth.currentUser ?.uid;

    if (userId != null) {
      _userCurrentOrderStream = _firestore
          .collection('Orders')
          .where('userId', isEqualTo: userId)
          .where('KitchenorderStatus', whereIn: ['Pending', 'Preparing'])
          .orderBy('orderDate', descending: true)
          .snapshots();
    } else {
      print('No user is logged in');
    }
  }

  Future<void> _addFoodToCart(String userId, Map<String, dynamic> item) async {
    try {
      await DatabaseMethods().addFoodtoCart(userId, item); // Use DatabaseMethods
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "Food Item Added to Cart",
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      );
    } catch (e) {
      print("Error adding to cart: $e");
    }
  }

  void _reorderItems(List<dynamic> items) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    for (var item in items) {
      await _addFoodToCart(userId, item);
    }
  }

  // Cancel Order and Refund Amount
  Future<void> _cancelOrder(String orderId) async {
    try {
      DocumentSnapshot orderDoc =
      await _firestore.collection('Orders').doc(orderId).get();
      if (!orderDoc.exists) {
        print("Order does not exist");
        return;
      }

      int totalAmount = orderDoc['totalAmount'];
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          int walletAmount = int.parse(userDoc['Wallet']);
          int updatedWallet = walletAmount + totalAmount;

          await _firestore
              .collection('users')
              .doc(userId)
              .update({"Wallet": updatedWallet.toString()});
        }
      }

      await _firestore.collection('Orders').doc(orderId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Order Cancelled and Amount Refunded"),
          backgroundColor: Colors.redAccent,
        ));
      }

      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => BottomNav()));
        }
      });
    } catch (e) {
      print("Error cancelling order: $e");
    }
  }

  Widget currentOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _userCurrentOrderStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No order history available'));
        }

        final userId = _auth.currentUser?.uid;

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data!.docs[index];
            final orderId = ds.id;
            final orderDate = (ds['orderDate'] as Timestamp).toDate();
            final totalAmount = ds['totalAmount'];
            final items = ds['items'] as List<dynamic>;

            return Container(
              margin: EdgeInsets.all(8),
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black54, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ID: $orderId', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Order Date: ${orderDate.toLocal()}'),
                      Text('Total Amount: ₹$totalAmount', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10.0),
                      Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...items.map((item) {
                        return ListTile(
                          leading: Image.network(item['Image'], width: 50, height: 50, fit: BoxFit.cover),
                          title: Text(item['Name']),
                          subtitle: Text('Quantity: ${item['Quantity']}, Total: ₹${item['Total']}'),
                        );
                      }).toList(),
                      SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () => _reorderItems(items),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                        ),
                        child: Text("Reorder",style: TextStyle(color: Colors.black)),
                      ),
                      ElevatedButton(
                        onPressed: () => _cancelOrder(orderId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                        child: Text("Cancel Order", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget pastOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _userOrderHistoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No order history available'));
        }

        var orders = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = snapshot.data!.docs[index];
            final orderId = ds.id;
            final orderDate = (ds['orderDate'] as Timestamp).toDate();
            final totalAmount = ds['totalAmount'];
            final items = ds['items'] as List<dynamic>;

            return Container(
              margin: EdgeInsets.all(8),
              child: Material(
                elevation: 5.0,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black54, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order ID: $orderId', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Order Date: ${orderDate.toLocal()}'),
                      Text('Total Amount: ₹$totalAmount', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 10.0),
                      Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...items.map((item) {
                        return ListTile(
                          leading: Image.network(item['Image'], width: 50, height: 50, fit: BoxFit.cover),
                          title: Text(item['Name']),
                          subtitle: Text('Quantity: ${item['Quantity']}, Total: ₹${item['Total']}'),
                        );
                      }).toList(),
                      SizedBox(height: 10.0),
                      ElevatedButton(
                        onPressed: () => _reorderItems(items),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                        ),
                        child: Text("Reorder", ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order History'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Back arrow icon
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BottomNav())); // Navigates one page back
          },
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(tabs: [
              Tab(text: "Current Orders"),
              Tab(text: "Past Orders"),
            ]),
            Expanded(
              child: TabBarView(
                children: [
                  currentOrdersList(),
                  pastOrdersList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
