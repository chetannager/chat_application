import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chat extends StatefulWidget {
  String userId;
  String fullName;
  Chat(this.userId, this.fullName);
  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  bool isLoggedIn;
  bool isLoading;
  final firestoreInstance = FirebaseFirestore.instance;
  final messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  String userId;

  sendMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userIdTemp = await prefs.getString("userId");
    userId = userIdTemp;
    bool tempLoggedIn = await prefs.getBool("isLoggedIn");
    firestoreInstance.collection("chatRoom").add({
      "message": messageController.text,
      "userId1": userId,
      "userId2": widget.userId,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    }).then((value) {
      messageController.text = "";
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    firestoreInstance.collection("chatRoom").snapshots().listen((event) async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String userIdTemp = await prefs.getString("userId");
      userId = userIdTemp;
      event.docChanges.forEach((element) {
        if (element.type == DocumentChangeType.added) {
          print(element.doc.data());
          if (element.doc.data()["userId1"] == userId &&
                  element.doc.data()["userId2"] == widget.userId ||
              element.doc.data()["userId2"] == userId &&
                  element.doc.data()["userId1"] == widget.userId) {
            setState(() {
              messages.add(element.doc.data());
              messages.sort((a, b) => a["timestamp"] - b["timestamp"]);
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.fullName),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
              margin: EdgeInsets.only(bottom: 50),
              child: Column(
                children: messages
                    .map((message) => Row(
                          mainAxisAlignment: message["userId1"] == userId
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: message["userId1"] == userId
                                    ? Colors.lightGreen.withOpacity(0.5)
                                    : Colors.orange.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              child: Text(
                                message["message"].toString(),
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                  ),
                  BoxShadow(
                    color: Colors.grey,
                  )
                ],
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.only(left: 15.0),
                      hintText: "Type a Message",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      if (messageController.text != "") {
                        sendMessage();
                      }
                    },
                  ),
                  Positioned(
                    right: 10,
                    child: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        if (messageController.text != "") {
                          sendMessage();
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
