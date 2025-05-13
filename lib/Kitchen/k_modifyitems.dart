import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/Kitchen/Kitchen_home.dart';

class KModifyitems extends StatefulWidget {
  final String kitchenId; // Kitchen ID passed to the page

  const KModifyitems({Key? key, required this.kitchenId}) : super(key: key);

  @override
  _KModifyitemsState createState() => _KModifyitemsState();
}

class _KModifyitemsState extends State<KModifyitems> {
  String? currentKitchenname;
  List<Map<String, dynamic>> itemsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKitchenItems();
  }

  // Fetch items for the current kitchen from Firestore
  Future<void> fetchKitchenItems() async {
    try {
      DocumentSnapshot kitchenSnapshot = await FirebaseFirestore.instance
          .collection('kitchens')
          .doc(widget.kitchenId)
          .get();

      if (kitchenSnapshot.exists) {
        setState(() {
          currentKitchenname = kitchenSnapshot['kitchenname'];
        });

        // Fetch food items under each category
        await FirebaseFirestore.instance
            .collection('fooditem')
            .doc(currentKitchenname)
            .collection('categories')
            .get()
            .then((categorySnapshot) async {
          List<Map<String, dynamic>> allItems = [];
          for (var category in categorySnapshot.docs) {
            var categoryName = category['name'];

            // Fetch items under the category
            var itemsSnapshot = await FirebaseFirestore.instance
                .collection('fooditem')
                .doc(currentKitchenname)
                .collection('categories')
                .doc(categoryName)
                .collection('Items')
                .get();

            for (var item in itemsSnapshot.docs) {
              allItems.add({
                'category': categoryName,
                'itemId': item.id,
                'name': item['Name'],
                'price': item['Price'],
                'detail': item['Detail'],
                'ingredients': item['Ingredients'],
              });
            }
          }
          setState(() {
            itemsList = allItems;
            isLoading = false;
          });
        });
      } else {
        print("Kitchen not found");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching kitchen items: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Modify an existing food item in Firestore
  // Modify an existing food item in Firestore
  Future<void> modifyItem(Map<String, dynamic> item) async {
    TextEditingController nameController = TextEditingController(text: item['name']);
    TextEditingController priceController = TextEditingController(text: item['price'].toString());
    TextEditingController detailController = TextEditingController(text: item['detail']);
    TextEditingController ingredientController = TextEditingController(text: item['ingredients'].join(','));

    // Track the current availability status
    bool isUnavailable = item['isUnavailable'] ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(  // Use StatefulBuilder to manage the state inside the AlertDialog
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Modify Item'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Item Name'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: detailController,
                      decoration: InputDecoration(labelText: 'Detail'),
                    ),
                    TextField(
                      controller: ingredientController,
                      decoration: InputDecoration(labelText: 'Ingredients (comma separated)'),
                    ),
                    // Add a Switch to toggle item availability
                    SwitchListTile(
                      title: Text('Unavailable'),
                      value: isUnavailable,
                      onChanged: (bool value) {
                        setState(() {
                          isUnavailable = value;  // Update the local state
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Validate and update the food item in Firestore
                    if (nameController.text.isNotEmpty &&
                        priceController.text.isNotEmpty &&
                        detailController.text.isNotEmpty &&
                        ingredientController.text.isNotEmpty) {
                      try {
                        Map<String, dynamic> updatedItem = {
                          'Name': nameController.text,
                          'Price': priceController.text,
                          'Detail': detailController.text,
                          'Ingredients': ingredientController.text.split(','),
                          'isUnavailable': isUnavailable,  // Update the availability status
                        };

                        await FirebaseFirestore.instance
                            .collection('fooditem')
                            .doc(currentKitchenname)
                            .collection('categories')
                            .doc(item['category'])
                            .collection('Items')
                            .doc(item['itemId'])
                            .update(updatedItem);

                        Navigator.of(context).pop();
                        fetchKitchenItems(); // Refresh item list
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text("Item updated successfully!"),
                        ));
                      } catch (e) {
                        print("Error updating item: $e");
                      }
                    }
                  },
                  child: Text('Update'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
              ],
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
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back_rounded, color: Color(0xFF373866)),
        ),
        title: Text('View & Modify Items', style: TextStyle(fontSize: 20)),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : itemsList.isEmpty
          ? Center(child: Text('No items available'))
          : ListView.builder(
        itemCount: itemsList.length,
        itemBuilder: (context, index) {
          var item = itemsList[index];
          return Container(
            margin: EdgeInsets.symmetric(vertical: 8.0), // Add vertical margin for spacing
            padding: EdgeInsets.all(10.0), // Add padding inside the box
            decoration: BoxDecoration(
              color: Colors.white, // White background for the box
              borderRadius: BorderRadius.circular(8.0), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5.0,
                  offset: Offset(0, 3), // Shadow position
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                item['name'],
                style: TextStyle(fontWeight: FontWeight.bold), // Bold title for better visibility
              ),
              subtitle: Text('Price: ₹${item['price']}'),
              onTap: () => modifyItem(item), // Modify item when tapped
            ),
          );
        },
      ),
    );
  }
}
