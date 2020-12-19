import 'package:chat_app/account.dart';
import 'package:chat_app/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isLoggedIn;
  bool isLoading;
  final firestoreInstance = FirebaseFirestore.instance;
  List<Map<String, dynamic>> Users = [];

  checkLoggedIn() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool tempLoggedIn = await prefs.getBool("isLoggedIn");
    String userId = await prefs.getString("userId");
    print(tempLoggedIn);
    if (tempLoggedIn != null) {
      firestoreInstance
          .collection("users")
          .doc(userId)
          .update({"online": true}).then((_) {
        print("Success");
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
    }
  }

  getAllUsers() async {
    // setState(() {
    //   Users = [];
    // });
    // firestoreInstance.collection("users").get().then((querySnapshot) async {
    //   querySnapshot.docs.forEach((element) {
    //     Users.add(element.data());
    //   });
    //   print(Users);
    // });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    firestoreInstance
        .collection("users")
        .snapshots()
        .listen((querySnapshot) async {
      setState(() {
        Users = [];
      });
      querySnapshot.docs.forEach((element) {
        Map<String, dynamic> d = {
          "fullName": element.data()["fullName"],
          "mobileNumber": element.data()["mobileNumber"],
          "online": element.data()["online"],
          "userId": element.id,
        };
        Users.add(d);
      });
      print(Users);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userId = await prefs.getString("userId");
      Users.forEach((element) {
        if (element["userId"] == userId) {
          print(Users.indexOf(element));
          Users.removeAt(Users.indexOf(element));
        }
      });
    });
    checkLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat App"),
        actions: [
          isLoading
              ? Container()
              : isLoggedIn
                  ? IconButton(
                      icon: Icon(Icons.account_circle),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext) => Account()));
                      })
                  : Container()
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : isLoggedIn
                ? ListView.builder(
                    itemBuilder: (BuildContext, index) => ListTile(
                      leading: Icon(Icons.person),
                      title: Text(Users[index]["fullName"]),
                      subtitle: Text(Users[index]["mobileNumber"]),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext) => Chat(
                                    Users[index]["userId"],
                                    Users[index]["fullName"])));
                      },
                      trailing: Users[index]["online"]
                          ? Text(
                              "Online",
                              style: TextStyle(
                                color: Colors.green,
                              ),
                            )
                          : Text(""),
                    ),
                    itemCount: Users.length,
                  )
                : Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          child: Text(
                            "You have not Setup your Profile for Chat!",
                            style: TextStyle(
                              fontSize: 23.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          child: Text(
                            "Once you setup your profile. you will able to chat with others.",
                            style: TextStyle(
                              fontSize: 15.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        RaisedButton(
                          onPressed: () async {
                            final d = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext) => Account()));
                            if (d == "hello") {
                              checkLoggedIn();
                            }
                          },
                          child: Text("Setup Profile"),
                        )
                      ],
                    ),
                  ),
      ),
    );
  }
}
