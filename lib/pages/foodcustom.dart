import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foodapp/service/database.dart';

class FoodCustomizationDialog extends StatefulWidget {
  final Map<String, dynamic> foodItem;
  final String id;
  final int quantity;
  final int total;
  final bool isSubscription;

  FoodCustomizationDialog({
    required this.foodItem,
    required this.id,
    required this.quantity,
    required this.total,
    this.isSubscription = false,
  });

  @override
  _FoodCustomizationDialogState createState() => _FoodCustomizationDialogState();
}

class _FoodCustomizationDialogState extends State<FoodCustomizationDialog> {
  List<String> selectedIngredients = [];
  String selectedSpiceLevel = "Mild";
  String customInstructions = "";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                "Customize ${widget.foodItem['name']}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),

              // Select Ingredients
              Text("Select Ingredients:", style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: (widget.foodItem['optionalIngredients'] as List).map<Widget>((ingredient) {
                  return CheckboxListTile(
                    title: Text(ingredient),
                    value: selectedIngredients.contains(ingredient),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedIngredients.add(ingredient);
                        } else {
                          selectedIngredients.remove(ingredient);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              SizedBox(height: 10),

              // Select Spice Level
              Text("Select Spice Level:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedSpiceLevel,
                onChanged: (newValue) {
                  setState(() {
                    selectedSpiceLevel = newValue!;
                  });
                },
                items: (widget.foodItem['spiceLevels'] as List).map<DropdownMenuItem<String>>((level) {
                  return DropdownMenuItem<String>(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
              ),

              SizedBox(height: 10),

              // Custom Instructions
              Text("Special Instructions:", style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                decoration: InputDecoration(hintText: "E.g. No onions, extra cheese..."),
                onChanged: (value) {
                  setState(() {
                    customInstructions = value;
                  });
                },
              ),

              SizedBox(height: 15),

              // Buttons: Cancel and Add to Cart
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: TextStyle(color: Colors.red)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Map<String, dynamic> addFoodtoCart = {
                        "Name": widget.foodItem['name'],
                        "Quantity": widget.quantity.toString(),
                        "Total": widget.total.toString(),
                        "Image": widget.foodItem['image'],
                        "kitchenname": widget.foodItem['kitchenname'],
                        "FoodCategory": widget.foodItem['FoodCategory'],
                        "Selected Ingredients": selectedIngredients,
                        "Spice Level": selectedSpiceLevel,
                        "Custom Instructions": customInstructions,
                      };

                      await DatabaseMethods().addFoodtoCart(widget.id, addFoodtoCart);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.orangeAccent,
                        content: Text("Food Item Added to Cart", style: TextStyle(fontSize: 18.0)),
                      ));

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: Text("Add to Cart",
                      style: TextStyle(color: Colors.white,)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
