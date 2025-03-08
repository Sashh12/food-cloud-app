import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:foodapp/service/database.dart';
import 'package:foodapp/widget/widget_support.dart';

class Detail extends StatefulWidget {
  String image, name, detail, price, kitchenname, FoodCategory;
  List<dynamic> ingredients; // Ingredients is now a List<dynamic> to handle Firestore response

  Detail({
    required this.detail,
    required this.image,
    required this.name,
    required this.price,
    required this.kitchenname,
    required this.ingredients,
    required this.FoodCategory,// Changed to List<dynamic> for ingredients
  });

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  int a = 1, total = 0;
  String? id;
  bool showAllIngredients = false; // State to control showing all ingredients

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

  // Function to calculate the date for the given day of the current week
  DateTime getDateForDay(String dayOfWeek) {
    DateTime now = DateTime.now();
    int currentWeekday = now.weekday; // Monday = 1, ..., Sunday = 7

    Map<String, int> dayMapping = {
      'Sunday': 7,
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
    };

    int dayTarget = dayMapping[dayOfWeek]!;
    int difference = dayTarget - currentWeekday;

    // Get the date for the selected day
    DateTime selectedDate = now.add(Duration(days: difference));
    return selectedDate;
  }

  Future<void> showSubscribeDialog() async {
    List<String> daysOfWeek = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    String selectedDay = '';
    DateTime selectedDate = DateTime.now();
    TimeOfDay? selectedLunchTime;
    TimeOfDay? selectedDinnerTime;

    DateTime now = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Select a Day for Subscription'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    "Subscription Week: ${DateFormat('dd/MM/yy').format(DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)))} - "
                        "${DateFormat('dd/MM/yy').format(DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)))}"
                ),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedDay.isEmpty ? null : selectedDay,
                  hint: Text("Choose a Day"),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDay = newValue!;
                      selectedDate = getDateForDay(newValue);
                    });
                  },
                  items: daysOfWeek.map((String day) {
                    DateTime dayDate = getDateForDay(day);
                    bool isDisabled = dayDate.isBefore(now);

                    return DropdownMenuItem<String>(
                      value: day,
                      enabled: !isDisabled,
                      child: Text(
                        "$day - ${DateFormat('dd/MM/yy').format(dayDate)}",
                        style: isDisabled ? TextStyle(color: Colors.grey) : null,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                // Lunch time picker
                Row(
                  children: [
                    Text('Lunch Time: '),
                    TextButton(
                      onPressed: () async {
                        TimeOfDay initialTime = selectedDay == DateFormat('EEEE').format(now)
                            ? TimeOfDay(hour: now.hour, minute: now.minute)
                            : TimeOfDay.now();

                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );

                        if (pickedTime != null) {
                          // If it's today, check if the picked time is after the current time
                          if (selectedDay == DateFormat('EEEE').format(now)) {
                            final nowInMinutes = now.hour * 60 + now.minute;
                            final pickedTimeInMinutes = pickedTime.hour * 60 + pickedTime.minute;

                            if (pickedTimeInMinutes <= nowInMinutes) {
                              // Show a warning if the picked time is before or equal to the current time
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please select a time later than the current time."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              setState(() {
                                // Deselect dinner time if lunch is selected
                                selectedDinnerTime = null;
                                selectedLunchTime = pickedTime;
                              });
                            }
                          } else {
                            // For future days, allow any time to be selected
                            setState(() {
                              // Deselect dinner time if lunch is selected
                              selectedDinnerTime = null;
                              selectedLunchTime = pickedTime;
                            });
                          }
                        }
                      },
                      child: Text(selectedLunchTime == null
                          ? "Select Time"
                          : selectedLunchTime!.format(context)),
                    ),
                  ],
                ),
                // Dinner time picker
                Row(
                  children: [
                    Text('Dinner Time: '),
                    TextButton(
                      onPressed: () async {
                        TimeOfDay initialTime = selectedDay == DateFormat('EEEE').format(now)
                            ? TimeOfDay(hour: now.hour, minute: now.minute)
                            : TimeOfDay.now();

                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                        );

                        if (pickedTime != null) {
                          // If it's today, check if the picked time is after the current time
                          if (selectedDay == DateFormat('EEEE').format(now)) {
                            final nowInMinutes = now.hour * 60 + now.minute;
                            final pickedTimeInMinutes = pickedTime.hour * 60 + pickedTime.minute;

                            if (pickedTimeInMinutes <= nowInMinutes) {
                              // Show a warning if the picked time is before or equal to the current time
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Please select a time later than the current time."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else {
                              setState(() {
                                // Deselect lunch time if dinner is selected
                                selectedLunchTime = null;
                                selectedDinnerTime = pickedTime;
                              });
                            }
                          } else {
                            // For future days, allow any time to be selected
                            setState(() {
                              // Deselect lunch time if dinner is selected
                              selectedLunchTime = null;
                              selectedDinnerTime = pickedTime;
                            });
                          }
                        }
                      },
                      child: Text(selectedDinnerTime == null
                          ? "Select Time"
                          : selectedDinnerTime!.format(context)),
                    ),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  // Check that at least one meal time is selected
                  if (selectedDay.isNotEmpty && (selectedLunchTime != null || selectedDinnerTime != null)) {
                    // Save the subscription with the selected day, date, and times
                    await saveSubscription(
                      selectedDay,
                      selectedDate,
                      selectedLunchTime,
                      selectedDinnerTime,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Subscribed for $selectedDay (${DateFormat('dd/MM/yy').format(selectedDate)}) "
                          "${selectedLunchTime != null ? "Lunch: ${selectedLunchTime!.format(context)}" : ""} "
                          "${selectedDinnerTime != null ? "Dinner: ${selectedDinnerTime!.format(context)}" : ""}"),
                    ));
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("Please select a day and at least one meal time."),
                    ));
                  }
                },
                child: Text('Subscribe'),
              ),
            ],
          );
        });
      },
    );
  }

  // Function to save the subscription data to Firestore
  Future<void> saveSubscription(String dayOfWeek, DateTime date, TimeOfDay? lunchTime, TimeOfDay? dinnerTime) async {
    if (id != null) {
      // Structure the subscription data
      Map<String, dynamic> subscriptionData = {
        "productName": widget.name,
        "price": widget.price,
        "day": dayOfWeek,
        "date": DateFormat('dd/MM/yy').format(date), // Save the subscription date
        "lunchTime": lunchTime != null ? lunchTime.format(context) : "Not Set", // Handle null case
        "dinnerTime": dinnerTime != null ? dinnerTime.format(context) : "Not Set", // Handle null case
        "kitchenName": widget.kitchenname,
      };

      // Save to Firestore under 'subscribe' collection
      await FirebaseFirestore.instance
          .collection('subscribe')
          .doc(id)
          .collection('days')
          .doc(dayOfWeek)
          .set(subscriptionData);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert ingredients to List<String> if it is List<dynamic>
    List<String> ingredientsList = widget.ingredients.map((e) => e.toString()).toList();

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
                      SizedBox(height: 10.0),
                      Text(
                        widget.FoodCategory,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Column(
                    children: [
                      IconButton(
                        onPressed: showSubscribeDialog,
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
                  padding: EdgeInsets.all(10.0),
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
                        ingredientsList.take(showAllIngredients ? ingredientsList.length : 3)
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
                color: Colors.orangeAccent,
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
                    // Create the map with the food item details
                    Map<String, dynamic> addFoodtoCart = {
                      "Name": widget.name,
                      "Quantity": a.toString(),
                      "Total": total.toString(),
                      "Image": widget.image,
                      "kitchenname": widget.kitchenname,
                      "FoodCategory": widget.FoodCategory,
                    };

                    // Call the method to handle the database operation
                    await DatabaseMethods().addFoodtoCart(id!, addFoodtoCart);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.orangeAccent,
                      content: Text("Food Item Added to Cart", style: TextStyle(fontSize: 18.0)),
                    ));
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
