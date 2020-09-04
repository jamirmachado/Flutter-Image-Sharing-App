import 'package:flutter/material.dart';

AppBar header(context, {bool isAppTitle = false, String titleText}) {
  return AppBar(
    title: Text(
      isAppTitle ? "savepoint" : titleText,
      style: TextStyle(
        color: Colors.pink[300],
        fontFamily: isAppTitle ? "NanoTech" : "",
        fontSize: isAppTitle ? 30 : 20,
      ),
    ),
    centerTitle: true,
    backgroundColor: Color.fromRGBO(16, 0, 22, 1),
  );
}
