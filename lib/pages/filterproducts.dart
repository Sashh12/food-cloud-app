import 'package:flutter/material.dart';
import 'package:foodapp/pages/bottomnav.dart';
import 'package:foodapp/pages/details2.dart';

class FilteredProductsPage extends StatelessWidget {
  final List<Map<String, dynamic>> filteredProducts;

  const FilteredProductsPage({Key? key, required this.filteredProducts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Filtered Products"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to the BottomNav with Home as the active tab
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => BottomNav(initialTabIndex: 0)),
                  (route) => false, // Removes all previous routes
            );
          },
        ),
      ),
      body: filteredProducts.isEmpty
          ? Center(child: Text("No items found."))
          : ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> itemData = filteredProducts[index];
          return GestureDetector(
            onTap: () {
              // Navigate to the detail page for the selected item
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Detail(
                    detail: itemData["Detail"] ?? "",
                    name: itemData["Name"] ?? "No Name",
                    image: itemData["Image"] ?? "https://via.placeholder.com/180",
                    price: itemData["Price"] ?? "0",
                    kitchenname: itemData["kitchenname"] ?? "",
                    ingredients: itemData["Ingredients"] ?? "",
                    optionalIngredients: itemData["optionalIngredients"] ?? "",
                    spiceLevels: itemData["spiceLevels"] ?? "",
                    FoodCategory: itemData["FoodCategory"] ?? "",
                  ),
                ),
              );
            },
            child: buildProductCardFromMap(itemData),
          );
        },
      ),
    );
  }

  // Method to build product card from map of item data
  Widget buildProductCardFromMap(Map<String, dynamic> product) {
    String imageUrl = product["Image"] ?? "https://via.placeholder.com/180";
    String name = product["Name"] ?? "No Name";
    String price = product["Price"] ?? "0";

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Material(
        elevation: 5.0,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("₹$price", style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}