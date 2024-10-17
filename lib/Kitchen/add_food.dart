import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:foodapp/Kitchen/Kitchen_home.dart';
import 'package:foodapp/widget/widget_support.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFood extends StatefulWidget {
  final String kitchenId; // Add this line to define the parameter

  const AddFood({Key? key, required this.kitchenId}) : super(key: key); // Modify constructor

  @override
  State<AddFood> createState() => _AddFoodState();
}

class _AddFoodState extends State<AddFood> {
  final List<String> fooditems = []; // Empty list for food items
  String? value;
  bool isAddingCategory = false;

  TextEditingController namecontroller = TextEditingController();
  TextEditingController pricecontroller = TextEditingController();
  TextEditingController detailcontroller = TextEditingController();
  TextEditingController categoryController = TextEditingController();
  TextEditingController ingredientcontroller = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  String? currentKitchenname; // To store the current kitchen name

  @override
  void initState() {
    super.initState();
    fetchCurrentKitchenInfo();
  }

  Future<void> fetchCurrentKitchenInfo() async {
    try {
      // Instead of using user.uid, use widget.kitchenId if it's intended for a specific kitchen
      // User? user = FirebaseAuth.instance.currentUser;

      // Now, fetch the kitchen document associated with the kitchenId
      DocumentSnapshot kitchenSnapshot = await FirebaseFirestore.instance
          .collection('kitchens')
          .doc(widget.kitchenId) // Use kitchenId passed from the constructor
          .get();

      if (kitchenSnapshot.exists) {
        // Access the kitchen name from the fetched document
        currentKitchenname = kitchenSnapshot['kitchenname']; // Adjust field name as necessary
        print("Current Kitchen Name: $currentKitchenname"); // Print kitchen name

        // Fetch categories for the current kitchen
        fetchCategories(currentKitchenname!);
      } else {
        print("No kitchen found for this ID");
      }
    } catch (e) {
      print("Error fetching kitchen info: $e");
    }
  }


  Future<void> fetchCategories(String kitchenname) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('fooditem')
          .doc(kitchenname) // Use kitchen name as document ID
          .collection('categories')
          .get();

      setState(() {
        fooditems.clear();
        fooditems.addAll(snapshot.docs.map((doc) => doc['name'] as String));
      });
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<bool> uploadItem() async {
    try {
      if (selectedImage != null &&
          namecontroller.text.isNotEmpty &&
          pricecontroller.text.isNotEmpty &&
          detailcontroller.text.isNotEmpty &&
          ingredientcontroller.text.isNotEmpty) {

        String addId = randomAlphaNumeric(10);

        // Upload image to Firebase Storage
        Reference firebaseStorageRef = FirebaseStorage.instance
            .ref()
            .child("foodImages")
            .child(addId);
        UploadTask task = firebaseStorageRef.putFile(selectedImage!);
        var downloadUrl = await (await task).ref.getDownloadURL();

        // Create the food item map with ingredients
        Map<String, dynamic> addItem = {
          "Image": downloadUrl,
          "Name": namecontroller.text,
          "Price": pricecontroller.text,
          "Detail": detailcontroller.text,
          "Ingredients": ingredientcontroller.text.split(','), // Save ingredients as a list
          "Kitchenname": currentKitchenname,
        };

        String categoryToUse = isAddingCategory
            ? categoryController.text
            : value ?? fooditems.first;

        // If adding a new category, add it to Firestore under the specific kitchen
        if (isAddingCategory) {
          setState(() {
            fooditems.add(categoryController.text);
          });
          await FirebaseFirestore.instance
              .collection('fooditem')
              .doc(currentKitchenname) // Use the kitchen name as document ID
              .collection('categories')
              .doc(categoryController.text)
              .set({'name': categoryController.text});

          fetchCategories(currentKitchenname!); // Refresh categories
        }

        // Save the food item under the selected category for the kitchen
        await FirebaseFirestore.instance
            .collection('fooditem')
            .doc(currentKitchenname) // Use the kitchen name as document ID
            .collection('categories')
            .doc(categoryToUse)
            .collection('Items')
            .add(addItem);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.orangeAccent,
          content: Text(
            "Food Item has been added Successfully",
            style: TextStyle(fontSize: 18.0),
          ),
        ));

        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error while uploading item: $e");
      return false;
    }
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
        centerTitle: true,
        title: Text("Add Item", style: AppWidget.SemiBoldFieldStyle()),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Upload the Item Picture", style: AppWidget.SemiBoldFieldStyle2()),
              SizedBox(height: 20.0),
              selectedImage == null
                  ? GestureDetector(
                onTap: () {
                  getImage();
                },
                child: Center(
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.5),
                          borderRadius: BorderRadius.circular(20)),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              )
                  : Center(
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                        borderRadius: BorderRadius.circular(20)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.0),
              Text("Item Name", style: AppWidget.SemiBoldFieldStyle2()),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xFFececf8), borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: namecontroller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Item Name",
                    hintStyle: AppWidget.LightTextFieldStyle(),
                  ),
                ),
              ),
              SizedBox(height: 30.0),
              Text("Item Price", style: AppWidget.SemiBoldFieldStyle2()),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xFFececf8), borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: pricecontroller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Item Price",
                    hintStyle: AppWidget.LightTextFieldStyle(),
                  ),
                ),
              ),
              SizedBox(height: 25.0),
              Text("Item Detail", style: AppWidget.SemiBoldFieldStyle2()),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xFFececf8), borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  maxLines: 6,
                  controller: detailcontroller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Item Detail",
                    hintStyle: AppWidget.LightTextFieldStyle(),
                  ),
                ),
              ),
              SizedBox(height: 25.0),
              Text("Ingredients", style: AppWidget.SemiBoldFieldStyle2()),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xFFececf8), borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: ingredientcontroller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Ingredients (comma-separated)",
                    hintStyle: AppWidget.LightTextFieldStyle(),
                  ),
                ),
              ),
              SizedBox(height: 18.0),
              Text(
                "Select Category",
                style: AppWidget.SemiBoldFieldStyle2(),
              ),
              SizedBox(height: 18.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: Color(0xFFececf8), borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    items: [
                      ...fooditems.map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: TextStyle(fontSize: 18.0, color: Colors.black),
                          ))),
                      DropdownMenuItem<String>(
                        value: "Add new category",
                        child: Text(
                          "Add new category",
                          style: TextStyle(fontSize: 18.0, color: Colors.redAccent),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        if (value == "Add new category") {
                          isAddingCategory = true;
                          this.value = null;
                        } else {
                          this.value = value;
                          isAddingCategory = false;
                        }
                      });
                    },
                    dropdownColor: Colors.white,
                    hint: Text("Select Category"),
                    iconSize: 36,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black,
                    ),
                    value: value,
                  ),
                ),
              ),
              if (isAddingCategory) ...[
                SizedBox(height: 20.0),
                Text(
                  "New Category",
                  style: AppWidget.SemiBoldFieldStyle2(),
                ),
                SizedBox(height: 10.0),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      color: Color(0xFFececf8), borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter New Category",
                        hintStyle: AppWidget.LightTextFieldStyle()),
                  ),
                ),

              ],
              SizedBox(height: 20.0),
              GestureDetector(
                onTap: () async {
                  bool productAdded = await uploadItem(); // Ensure this returns a boolean
                  if (productAdded) {
                    // Navigate to VendorHome if the product is successfully added
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => VendorHome()),
                    );
                  } else {
                    // Handle error or failure to add product
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to add product")),
                    );
                  }
                },

                child: Center(
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 10.0), // Slightly increased vertical padding for better button feel
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text( "Add", style: TextStyle( color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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