import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/pages/C_Customerview.dart';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/pages/orderTrackingPage.dart';
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
          .where('KitchenorderStatus', whereIn: ['Pending', 'Preparing','Out for Delivery'])
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
        print("❌ Order does not exist");
        return;
      }

      int totalAmount = orderDoc['totalAmount'];
      int orderLoyalty = orderDoc['loyalty'] ?? 0; // Fetch loyalty from the order
      final userId = _auth.currentUser?.uid;

      if (userId != null) {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          int walletAmount = int.tryParse(userDoc['Wallet'] ?? "0") ?? 0;
          int userLoyalty = userDoc['Loyalty'] ?? 0;

          // Refund Wallet Amount
          int updatedWallet = walletAmount + totalAmount;

          // Deduct Loyalty Points, ensuring it doesn't go negative
          int updatedLoyalty = (userLoyalty - orderLoyalty).clamp(0, userLoyalty);

          await _firestore.collection('users').doc(userId).update({
            "Wallet": updatedWallet.toString(),
            "Loyalty": updatedLoyalty,
          });

          print("✅ Wallet Refunded: $totalAmount");
          print("🏆 Loyalty Deducted: $orderLoyalty (Updated: $updatedLoyalty)");
        }
      }

      // Delete the order from Firestore
      await _firestore.collection('Orders').doc(orderId).delete();
      print("✅ Order Cancelled and Deleted");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Order Cancelled. Amount Refunded. Loyalty Deducted."),
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
      print("❌ Error cancelling order: $e");
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
          return Center(child: Text('No current orders available'));
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
            final orderstatus = ds['KitchenorderStatus'];
            final items = ds['items'] as List<dynamic>;

            double progress = _getOrderProgress(orderstatus);

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
                      SizedBox(height: 10,),
                      // Progress Bar for Order Status
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.grey[300], // Background color for the line
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: progress, // Fill percentage based on status
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green, // You can modify this color
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Order Status: $orderstatus',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

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
                      orderstatus == "Out for Delivery"
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Reorder button on the left
                          ElevatedButton(
                            onPressed: () => _reorderItems(items),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                            ),
                            child: Text("Reorder", style: TextStyle(color: Colors.black)),
                          ),
                          // Order Tracking button on the right
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderTrackingPage(orderId: orderId),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: Text("Order Tracking", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                          : Column(
                        children: [
                          // Cancel + Tracking Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () => _cancelOrder(orderId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                child: Text("Cancel Order", style: TextStyle(color: Colors.white)),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderTrackingPage(orderId: orderId),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                child: Text("Order Tracking", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            child: Text('Watch Live (Customer)'),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerViewPage(orderId: orderId)));
                            },
                          ),
                          SizedBox(height: 10),
                          // Centered Reorder
                          Center(
                            child: ElevatedButton(
                              onPressed: () => _reorderItems(items),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                              ),
                              child: Text("Reorder", style: TextStyle(color: Colors.black)),
                            ),
                          ),
                        ],
                      )


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


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange; // Pending is orange
      case 'preparing':
        return Colors.blue; // Confirmed is blue
      case 'out for delivery':
        return Colors.green; // Delivered is green
      case 'cancelled':
        return Colors.red; // Cancelled is red
      default:
        return Colors.grey; // Default is gray for unknown status
    }
  }
  double _getOrderProgress(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0.1; // 10% filled
      case 'preparing':
        return 0.2; // 20% filled
      case 'out for delivery':
        return 0.4; // 40% filled
      case 'Completed':
        return 1.0; // 100% filled
      case 'cancelled':
        return 0.0; // 0% filled (optional)
      default:
        return 0.0; // Default to 0% if status is unknown
    }
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
          itemCount: orders.length,
          itemBuilder: (context, index) {
            DocumentSnapshot ds = orders[index];
            final orderId = ds.id;
            final orderDate = (ds['orderDate'] as Timestamp).toDate();
            final totalAmount = ds['totalAmount'];
            final orderstatus = ds['KitchenorderStatus'];
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

                      // Styled Order Status Chip
                      Row(
                        children: [
                          Text('Order Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Chip(
                            label: Text(
                              orderstatus,
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _getStatusColor(orderstatus),
                          ),
                        ],
                      ),

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
                        child: Text("Reorder"),
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
