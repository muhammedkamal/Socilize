import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String username,id,email,photoUrl,displayName,bio;
  User({this.username,this.id,this.email,this.displayName,this.photoUrl,this.bio});

  factory User.fromDocument(DocumentSnapshot doc)
  {
    return User(
      id: doc['id'],
      username: doc['username'],
      email: doc['email'],
      displayName: doc['displayName'],
      photoUrl: doc['photoURL'],
      bio: doc['bio']
    );
  }

}
