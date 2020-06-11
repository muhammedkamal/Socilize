import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialize/models/user.dart';
import 'package:socialize/widgets/header.dart';
import 'package:socialize/widgets/post.dart';
import 'package:socialize/widgets/progress.dart';
import 'home.dart';

class Timeline extends StatefulWidget {
  final User currentUser;
  Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection("timelinePosts")
        .orderBy("timeStamp", descending: true)
        .getDocuments();
    List<Post> posts =
        snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Text("");
    }else
    return ListView(children: posts,);
  }

  @override
  void initState() {
    getTimeline();
    super.initState(); 
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isTimeLine: true),
      body: RefreshIndicator(
          child: buildTimeline(), 
          onRefresh: () => getTimeline()),
    );
  }
}
