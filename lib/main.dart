import 'package:flutter/material.dart';

import 'pages/home.dart';

void main() {
  runApp(SavepointApp());
}

class SavepointApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savepoint',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
