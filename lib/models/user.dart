import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String avatar;
  final String displayName;
  final String bio;

  User({
    this.id,
    this.username,
    this.email,
    this.avatar,
    this.displayName,
    this.bio,
  });

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      username: doc['username'],
      email: doc['email'],
      avatar: doc['avatar'],
      displayName: doc['displayName'],
      bio: doc['bio'],
    );
  }
}
