import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Account extends StatefulWidget {
  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  bool isLoggedIn;
  bool isLoading;
  bool isUpdating = false;
  final firestoreInstance = FirebaseFirestore.instance;
  final fullNameController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  submitCustomerData() async {
    setState(() {
      isUpdating = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userId = await prefs.getString("userId");
    bool tempLoggedIn = await prefs.getBool("isLoggedIn");
    if (tempLoggedIn != null) {
      firestoreInstance.collection("users").doc(userId).update({
        "fullName": fullNameController.text,
        "mobileNumber": mobileNumberController.text,
        "online": true,
      }).then((_) {
        firestoreInstance
            .collection("users")
            .doc(userId)
            .get()
            .then((querySnapshot) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString("userId", querySnapshot.id);
          prefs.setString("fullName", querySnapshot.data()["fullName"]);
          prefs.setString("mobileNumber", querySnapshot.data()["mobileNumber"]);
          Navigator.pop(context, "hello");
          setState(() {
            isUpdating = false;
          });
        });
      });
    } else {
      firestoreInstance.collection("users").add({
        "fullName": fullNameController.text,
        "mobileNumber": mobileNumberController.text
      }).then((value) {
        firestoreInstance
            .collection("users")
            .doc(value.id)
            .get()
            .then((querySnapshot) async {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setBool("isLoggedIn", true);
          prefs.setString("userId", querySnapshot.id);
          prefs.setString("fullName", querySnapshot.data()["fullName"]);
          prefs.setString("mobileNumber", querySnapshot.data()["mobileNumber"]);
          Navigator.pop(context, "hello");
          setState(() {
            isUpdating = false;
          });
        });
      });
    }
  }

  checkLoggedIn() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool tempLoggedIn = await prefs.getBool("isLoggedIn");
    String userId = await prefs.getString("userId");
    print(tempLoggedIn);
    if (tempLoggedIn != null) {
      await firestoreInstance
          .collection("users")
          .doc(userId)
          .get()
          .then((querySnapshot) async {
        fullNameController.text = querySnapshot.data()["fullName"];
        mobileNumberController.text = querySnapshot.data()["mobileNumber"];
      });
      setState(() {
        isLoggedIn = true;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
      fullNameController.text = "";
      mobileNumberController.text = "";
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Account Setup"),
      ),
      body: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.only(top: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Full Name"),
                  Container(
                    margin: EdgeInsets.only(top: 20, bottom: 30),
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: TextField(
                      controller: fullNameController,
                      enabled: isUpdating ? false : true,
                      decoration: InputDecoration(
                          labelText: "Enter full name",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          )),
                    ),
                  ),
                  Text("Mobile Number"),
                  Container(
                    margin: EdgeInsets.only(top: 20, bottom: 20),
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: TextField(
                      controller: mobileNumberController,
                      enabled: isUpdating ? false : true,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: InputDecoration(
                          counter: Offstage(),
                          labelText: "Enter mobile number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          )),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: RaisedButton(
                      padding: EdgeInsets.only(top: 15, bottom: 15),
                      child: isUpdating
                          ? Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Text("Submit"),
                      onPressed: isUpdating
                          ? null
                          : () {
                              if (fullNameController.text == "") {
                                _scaffoldKey.currentState.showSnackBar(SnackBar(
                                    content: Text("Please enter full name!")));
                              } else if (mobileNumberController.text.length !=
                                  10) {
                                _scaffoldKey.currentState.showSnackBar(SnackBar(
                                    content: Text(
                                        "Please enter 10 digit mobile number!")));
                              } else {
                                submitCustomerData();
                              }
                            },
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
