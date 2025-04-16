import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyDeliveriesPage extends StatelessWidget {
  final String deliveryGuyId;

  MyDeliveriesPage({required this.deliveryGuyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Deliveries")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Orders')
            .where('assignedDeliveryGuy', isEqualTo: deliveryGuyId)
            .where('KitchenorderStatus', isEqualTo: 'Out for Delivery')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No deliveries assigned yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final orderId = doc.id;
              final orderData = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text("Order ID: $orderId"),
                subtitle: Text("Status: ${orderData['deliveryStatus']}"),
              );
            },
          );
        },
      ),
    );
  }
}
