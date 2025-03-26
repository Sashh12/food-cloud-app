import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodapp/pages/foodcustom.dart';
import 'package:foodapp/pages/subfoodcustom.dart';
import 'package:intl/intl.dart';
import 'package:foodapp/service/database.dart';
import 'package:foodapp/widget/widget_support.dart';

class Detail extends StatefulWidget {
  String image, name, detail, price, kitchenname, FoodCategory;
  List<dynamic> ingredients, optionalIngredients, spiceLevels;

  Detail({
    required this.detail,
    required this.image,
    required this.name,
    required this.price,
    required this.kitchenname,
    required this.ingredients,
    required this.optionalIngredients,
    required this.spiceLevels,
    required this.FoodCategory,// Changed to List<dynamic> for ingredients
  });

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  int a = 1, total = 0;
  String? id;
  bool showAllIngredients = false;


  @override
  void initState() {
    super.initState();
    getUserId();
    total = int.parse(widget.price);
  }

  getUserId() {
    id = FirebaseAuth.instance.currentUser?.uid;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Convert ingredients to List<String> if it is List<dynamic>
    List<String> ingredientsList = widget.ingredients.map((e) => e.toString()).toList();
    List<String> optionalIngredients = widget.optionalIngredients.map((e) => e.toString()).toList();
    List<String> spiceLevels = widget.spiceLevels.map((e) => e.toString()).toList();

    return Scaffold(
      body: SingleChildScrollView(  // Wrap the content inside SingleChildScrollView
        child: Container(
          margin: EdgeInsets.only(top: 50.0, left: 20.0, right: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black),
              ),
              Image.network(
                widget.image,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 2.5,
                fit: BoxFit.fill,
              ),
              SizedBox(height: 15.0),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30.0,
                          color: Colors.black,
                        ),
                      ),
                      // SizedBox(height: 10.0),
                      Text(
                        widget.FoodCategory,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        widget.kitchenname,
                        style: TextStyle(
                          fontSize: 18.0,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        '₹${widget.price}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                          color: Colors.green,
                        ),
                      ),

                    ],
                  ),
                  Spacer(),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () {
                          // Create the foodItem object with all necessary details
                          Map<String, dynamic> foodItem = {
                            "name": widget.name,
                            "kitchenName": widget.kitchenname,
                            "FoodCategory": widget.FoodCategory,
                            "image": widget.image,
                            "price": widget.price,
                            "ingredients": widget.ingredients.map((e) => e.toString()).toList(),
                            "optionalIngredients": widget.optionalIngredients.map((e) => e.toString()).toList(),
                            "spiceLevels": widget.spiceLevels.map((e) => e.toString()).toList(),
                          };

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return SubCustomizationDialog(
                                foodItem: foodItem,  // ✅ Pass the created foodItem object
                                id: id,
                                a: a,
                                total: total,
                              );
                            },
                          );
                        },
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Colors.green,
                          size: 40.0,
                        ),
                      ),
                      Text("Subscribe", style: TextStyle(fontSize: 15.0)),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (a > 1) {
                        setState(() {
                          a--;
                          total -= int.parse(widget.price);
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.remove, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 20.0),
                  Text(a.toString(), style: TextStyle(fontSize: 18.0)),
                  SizedBox(width: 20.0),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        a++;
                        total += int.parse(widget.price);
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.0),
              GestureDetector(
                onTap: () {
                  setState(() {
                    showAllIngredients = !showAllIngredients;
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                  ),
                  width: MediaQuery.of(context).size.width, // Ensure the container fits the screen width
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Ingredients",
                        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 3.0),
                      Text(
                        ingredientsList.take(showAllIngredients ? ingredientsList.length : 4)
                            .join(', '),
                        style: TextStyle(fontSize: 16.0),
                      ),
                      if (ingredientsList.length > 3)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showAllIngredients = !showAllIngredients;
                            });
                          },
                          child: Text(
                            showAllIngredients ? "Show Less" : "Show All",
                            style: TextStyle(fontSize: 14.0, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                )
              ),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                width: double.infinity,
                color: Color(0xFFF6AD58),
                child: Center(
                  child: Text("Total: "
                    "₹$total",
                    style: TextStyle(color: Colors.white, fontSize: 18.0),
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              GestureDetector(
                onTap: () async {
                  if (id != null) {
                    // Open the customization screen and wait for the result
                    final customization = await showDialog(
                      context: context,
                      builder: (context) => FoodCustomizationDialog(
                        foodItem: {
                          "name": widget.name,
                          "optionalIngredients": widget.optionalIngredients,
                          "spiceLevels": widget.spiceLevels,
                          "image": widget.image, // Include image
                          "kitchenname": widget.kitchenname, // Include kitchen name
                          "FoodCategory": widget.FoodCategory,
                        },
                        id: id!, // Ensure you have userId defined
                        quantity: a, // Default quantity
                        total: total // Example total price (adjust dynamically)
                      ),
                    );

                    if (customization != null) {
                      // Merge customization with food details and add to cart
                      Map<String, dynamic> addFoodtoCart = {
                        "Name": widget.name,
                        "Quantity": a.toString(),
                        "Total": total.toString(),
                        "Image": widget.image,
                        "kitchenname": widget.kitchenname,
                        "FoodCategory": widget.FoodCategory,
                        "Selected Ingredients": customization["selectedIngredients"],
                        "Spice Level": customization["spiceLevel"],
                        "Custom Instructions": customization["customInstructions"],
                      };

                      await DatabaseMethods().addFoodtoCart(id!, addFoodtoCart);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: Colors.orangeAccent,
                        content: Text("Food Item Added to Cart", style: TextStyle(fontSize: 18.0)),
                      ));
                    }
                  }
                },
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width / 3,
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Add to Cart',
                          style: TextStyle(color: Colors.white, fontSize: 18.0),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
