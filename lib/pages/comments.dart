import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialize/pages/home.dart';
import 'package:socialize/widgets/header.dart';
import 'package:socialize/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class Comments extends StatefulWidget {
  final String postId, postOwnerId,mediaUrl;
  Comments({this.postId,this.mediaUrl,this.postOwnerId});
  @override
  CommentsState createState() => CommentsState(
    postId: this.postId,
    postOwnerId: this.postOwnerId,
    mediaUrl: this.mediaUrl
  );
}

class CommentsState extends State<Comments> {
  final String postId, postOwnerId,mediaUrl;
  TextEditingController commentController = TextEditingController();
  CommentsState({this.postId,this.mediaUrl,this.postOwnerId});
  addComment()
  {
    commentsRef.document(postId).collection('comment')
        .add({
      "username":currentUser.username,
      "comment":commentController.text,
      "timeStamp":timeStamp,
      "avatarUrl":currentUser.photoUrl,
      "userId":currentUser.id,
    });
    if (currentUser.id!=postOwnerId) {
      activityFeedRef.document(postOwnerId).collection('feedItems').add({
        'type': 'comment',
        'commentData': commentController.text,
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timeStamp,
      });
    }
    commentController.clear();
  }
  buildComments(){
    return StreamBuilder(
      stream: commentsRef.document(postId).collection('comment')
      .orderBy('timeStamp',descending: true).snapshots(),
      builder: (context,snapShot){
        if (!snapShot.hasData)
          {
            return circularProgress();
          }
        List<Comment> comments=[];
        snapShot.data.documents.forEach((doc){
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,pageTitle: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments(),),
          Divider(),
          ListTile(
            title: TextFormField(controller: commentController,
            decoration: InputDecoration(labelText: "Write a comment ..."),),
            trailing: OutlineButton(
              onPressed: addComment,
              borderSide: BorderSide.none,
              child: Text("Comment"),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username,userId,avatarUrl,comment;
  final Timestamp timestamp;
  Comment({
   this.username, this.userId, this.avatarUrl, this.comment, this.timestamp,
  });
  factory Comment.fromDocument(DocumentSnapshot doc){
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timeStamp'],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(avatarUrl),),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(),
      ],
    );
  }
}
