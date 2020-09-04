import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../widgets/header.dart';
import '../widgets/progress.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<dynamic> users = [];

  @override
  void initState() {
    //getUsers();
    //getUserByID();
    super.initState();
  }

  createUser() async {}

  /*  getUsers() async {
    //await usersRef.where("isAdmin", isEqualTo: true).getDocuments();

    final QuerySnapshot snapshot = await usersRef.getDocuments();
    setState(() {
      users = snapshot.documents;
    });
    /* snapshot.documents.forEach((DocumentSnapshot doc) {

	}); */
  } */

/*   getUserByID() async {
    final String id = "57rXnq0aB67xvZXh7zCI";
    final DocumentSnapshot doc = await usersRef.document(id).get();
    print(doc.data);
  }
 */
  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          final List<Text> children = snapshot.data.documents
              .map((doc) => Text(doc['username']))
              .toList();
          return Container(
            child: ListView(
              children: children,
            ),
          );
        },
      ),
    );
  }
}
