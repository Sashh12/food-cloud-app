import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/pages/details2.dart';
import 'package:foodapp/service/database.dart';

class HealthyItems extends StatefulWidget {
  const HealthyItems({super.key});

  @override
  State<HealthyItems> createState() => _HealthyItemsState();
}

class _HealthyItemsState extends State<HealthyItems> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHealthyItems();
  }

  /// Optimized Query: Fetch all healthy food items directly in one query
  Future<void> fetchHealthyItems() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collectionGroup('Items') // Query all 'Items' subcollections
          .where('FoodCategory', isEqualTo: 'Healthy')
          .get();

      List<Map<String, dynamic>> healthyItems = snapshot.docs.map((doc) {
        return doc.data();
      }).toList();

      if (mounted) {
        setState(() {
          products = healthyItems;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading healthy items: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: Text("Healthy Items")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? Center(child: Text("No healthy items available"))
          : Padding(
        padding: EdgeInsets.all(10),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> itemData = products[index];
            return GestureDetector(
              onTap: () {
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Detail(
                        detail: itemData["Detail"] ?? "",
                        name: itemData["Name"] ?? "No Name",
                        image: itemData["Image"] ??
                            "https://via.placeholder.com/180",
                        price: itemData["Price"] ?? "0",
                        kitchenname: itemData["kitchenname"] ?? "",
                        ingredients: itemData["Ingredients"] ?? "",
                        FoodCategory: itemData["FoodCategory"] ?? "",
                      ),
                    ),
                  );
                }
              },
              child: buildProductCardFromMap(itemData),
            );
          },
        ),
      ),
    );
  }

  Widget buildProductCardFromMap(Map<String, dynamic> product) {
    String imageUrl = product["Image"] ?? "https://via.placeholder.com/180";
    String name = product["Name"] ?? "No Name";
    String price = product["Price"] ?? "0";

    return Material(
      elevation: 5.0,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 10),
            Text(
              name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 5),
            Text(
              "₹$price",
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
