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

  @override
  void initState() {
    super.initState();
    _fetchOrderHistory();
  }

  void _fetchOrderHistory() {
    final userId = _auth.currentUser?.uid;

    if (userId != null) {
      _userOrderHistoryStream = _firestore
          .collection('orderHistory')
          .doc(userId)
          .collection('orders')
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

  Widget orderHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _userOrderHistoryStream,
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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => BottomNav()),
            );
          },
        ),
        title: Text('Order History'),
        centerTitle: true,
      ),
      body: orderHistoryList(),
    );
  }
}
