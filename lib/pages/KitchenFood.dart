import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/pages/details2.dart';

class FoodItemsPage extends StatelessWidget {
  final String kitchenname; // Store the kitchen name

  const FoodItemsPage({Key? key, required this.kitchenname}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$kitchenname Food Items'), // Display the kitchen name in the app bar
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fooditem')
            .doc(kitchenname) // Use kitchen name as document ID
            .collection('categories')
            .snapshots(), // Listen for changes in categories
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No food items found for this kitchen.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot categoryDoc = snapshot.data!.docs[index];

              return ExpansionTile(
                title: Text(categoryDoc['name'] ?? 'No Category'),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('fooditem')
                        .doc(kitchenname) // Use kitchen name as document ID
                        .collection('categories')
                        .doc(categoryDoc.id) // Current category ID
                        .collection('Items')
                        .snapshots(), // Listen for changes in food items
                    builder: (context, itemSnapshot) {
                      if (itemSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (itemSnapshot.hasError) {
                        return Center(child: Text('Error: ${itemSnapshot.error}'));
                      }

                      if (!itemSnapshot.hasData || itemSnapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No items found in this category.'));
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Two items per row
                          childAspectRatio: 0.8, // Adjust the aspect ratio to fit your design
                        ),
                        itemCount: itemSnapshot.data!.docs.length,
                        itemBuilder: (context, itemIndex) {
                          DocumentSnapshot foodItemDoc = itemSnapshot.data!.docs[itemIndex];

                          // Assuming ingredients are stored as a list or comma-separated string in Firestore
                          return GestureDetector(
                            onTap: () {
                              // Navigate to Detail page and pass the ingredients
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Detail(
                                    detail: foodItemDoc["Detail"] ?? "",
                                    name: foodItemDoc["Name"] ?? "No Name",
                                    image: foodItemDoc["Image"] ?? "https://via.placeholder.com/180",
                                    price: foodItemDoc["Price"] ?? "0",
                                    kitchenname: foodItemDoc["kitchenname"] ?? "",
                                    ingredients: foodItemDoc['Ingredients'] ?? "", // Pass ingredients here
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.all(8.0),
                              elevation: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                                    child: Image.network(
                                      foodItemDoc['Image'],
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          foodItemDoc['Name'] ?? 'No Name',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Price: ₹${foodItemDoc['Price']}',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                        Text(
                                          'Kitchen: $kitchenname',
                                          style: TextStyle(color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
