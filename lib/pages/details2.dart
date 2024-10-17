import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:foodapp/service/database.dart';
import 'package:foodapp/widget/widget_support.dart';

class Detail extends StatefulWidget {
  String image, name, detail, price;
  Detail({required this.detail, required this.image, required this.name, required this.price});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  int a = 1, total = 0;
  String? id;

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

  // Function to show the subscribe dialog
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
                // Display the subscription week range
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
                      selectedDate = getDateForDay(newValue); // Get the selected date
                    });
                  },
                  items: daysOfWeek.map((String day) {
                    DateTime dayDate = getDateForDay(day);
                    bool isDisabled = dayDate.isBefore(now); // Disable past days

                    return DropdownMenuItem<String>(
                      value: day,
                      enabled: !isDisabled, // Disable if it's in the past
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
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedLunchTime ?? TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            // Deselect dinner time if lunch is selected
                            selectedDinnerTime = null;
                            selectedLunchTime = pickedTime;
                          });
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
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedDinnerTime ?? TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            // Deselect lunch time if dinner is selected
                            selectedLunchTime = null;
                            selectedDinnerTime = pickedTime;
                          });
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
                  if (selectedDay.isNotEmpty && (selectedLunchTime!= null || selectedDinnerTime != null)) {
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
    return Scaffold(
      body: Container(
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
                    Text(widget.name, style: AppWidget.FoodNameText()),
                  ],
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    if (a > 1) {
                      --a;
                      total = total - int.parse(widget.price);
                    }
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(
                      Icons.remove,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 20.0),
                Text(a.toString(), style: AppWidget.SemiBoldFieldStyle()),
                SizedBox(width: 20.0),
                GestureDetector(
                  onTap: () {
                    if (a < 10) {
                      ++a;
                      total = total + int.parse(widget.price);
                    }
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.0),
            Text(
              widget.detail,
              maxLines: 4,
              style: AppWidget.LightTextFieldStyle2(),
            ),
            SizedBox(height: 30.0),
            Row(
              children: [
                Text("Delivery Time", style: AppWidget.NormalText()),
                SizedBox(width: 25.0),
                Icon(Icons.alarm, color: Colors.black54),
                SizedBox(width: 5.0),
                Text("30 mins", style: AppWidget.NormalText()),
              ],
            ),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Price", style: AppWidget.SemiBoldFieldStyle2()),
                      Text("\₹ " + total.toString(),
                          style: AppWidget.SemiBoldFieldStyle()),
                    ],
                  ),
                  Column(
                    children: [
                      // Add the "Subscribe" button below "Add to Cart"
                      GestureDetector(
                        onTap: () {
                          showSubscribeDialog();
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              color: Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Subscribe", style: TextStyle( color: Colors.white, fontSize: 16.0, fontFamily: 'Poppins'), ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          if (id != null) {
                            Map<String, dynamic> addFoodtoCart = {
                              "Name": widget.name,
                              "Quantity": a.toString(),
                              "Total": total.toString(),
                              "Image": widget.image,
                            };
                            await DatabaseMethods().addFoodtoCart(id!, addFoodtoCart);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                backgroundColor: Colors.orangeAccent,
                                content: Text("Food Item Added to Cart",  style: TextStyle(fontSize: 18.0),)));
                          }
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 2,
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration( color: Colors.black,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Add to Cart", style: TextStyle( color: Colors.white, fontSize: 16.0, fontFamily: 'Poppins'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
