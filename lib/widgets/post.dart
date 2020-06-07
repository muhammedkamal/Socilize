import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialize/models/user.dart';
import 'package:socialize/pages/activity_feed.dart';
import 'package:socialize/pages/comments.dart';
import 'package:socialize/pages/home.dart';
import 'package:socialize/widgets/custom_image.dart';
import 'package:socialize/widgets/progress.dart';

class Post extends StatefulWidget {
  final String ownerId,postId,username,location,caption,mediaUrl;
  final dynamic likes;
  Post({
    this.username,
    this.location,
    this.mediaUrl,
    this.postId,
    this.caption,
    this.likes,
    this.ownerId,
});
  factory Post.fromDocument(DocumentSnapshot doc)
  {
    return Post(
      ownerId: doc['ownerId'],
      postId: doc['postId'],
      username: doc['username'],
      location: doc['location'],
      mediaUrl: doc['mediaUrl'],
      caption: doc['caption'],
      likes: doc['likes'],
    );
  }
  int getLikesCount(likes)
  {
    if(likes==null)
      return 0;
    int likesCount =0;
    likes.values.forEach((val){
      if (val==true)
        likesCount++;
    });
    return likesCount;
  }
  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    username: this.username,
    ownerId: this.ownerId,
    mediaUrl: this.mediaUrl,
    location: this.location,
    caption: this.caption,
    likes: this.likes,
    likesCount: getLikesCount(this.likes),
  );
}

class _PostState extends State<Post> {
  final String ownerId,postId,username,location,caption,mediaUrl;
  final String currentUserId= currentUser?.id;
  Map likes;
  int likesCount;
  bool isLiked;
  bool showHeart=false;
  _PostState({
    this.username,
    this.location,
    this.mediaUrl,
    this.postId,
    this.caption,
    this.likes,
    this.ownerId,
    this.likesCount
  });
  buildPostHeader()
  {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder:(context,snapshot){
       if (!snapshot.hasData)
         return circularProgress();
       User user = User.fromDocument(snapshot.data);
       return ListTile(
         leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(user.photoUrl),backgroundColor: Colors.teal,),
         title: Text(user.username,style: TextStyle(fontWeight: FontWeight.bold),),
         onTap: ()=>showProfile(context,profileId: ownerId),
         subtitle: Text(location),
         trailing: IconButton(
           onPressed: (){},
           icon: Icon(Icons.more_vert),
         ),
       );
      },
    );
  }
  addLikeToActivityFeed(){
    if (currentUserId!=ownerId) {
      activityFeedRef.document(ownerId).collection('feedItems').document(postId)
          .setData({
        'type': 'like',
        'username':currentUser.username,
        'userId':currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId':postId,
        'mediaUrl':mediaUrl,
        'timestamp':timeStamp,
      });
    }
  }
  removeLikeFromFeed(){
    if (currentUserId!=ownerId) {
      activityFeedRef.document(ownerId).collection('feedItems').document(postId)
          .get().then((doc) {
        if (doc.exists)
          doc.reference.delete();
      });
    }
  }
  handleLikePost()
  {
    bool _isLiked = likes[currentUserId]==true;
    if (_isLiked)
      {
        postsRef.document(ownerId)
            .collection('usersPosts')
            .document(postId)
            .updateData({'likes.$currentUserId':false});
        removeLikeFromFeed();
        setState(() {
          likesCount-=1;
          isLiked =false;
          likes[currentUserId]=false;
        });

      }
    else if (!_isLiked)
    {
      postsRef.document(ownerId)
          .collection('usersPosts')
          .document(postId)
          .updateData({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likesCount+=1;
        isLiked =true;
        likes[currentUserId]=true;
        showHeart =true;
      });
      Timer(Duration(milliseconds: 500),(){
        setState(() {
          showHeart=false;
        });
      });
    }
  }

  buildPostImage()
  {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showHeart ? Animator(
            duration: Duration(milliseconds: 300),
            tween: Tween(begin: .8,end: 1.6),
            curve: Curves.elasticOut,
            cycles: 0,
            builder: (context, anim, child )=>Transform.scale(
              scale: anim.value,
              child: Icon(
                Icons.favorite,size: 120.0,color: Colors.red,
              ),
            ),
          ):Text(""),
        ],
      ),
    );
  }
  showComments(BuildContext context,{String postId,String ownerId,String mediaUrl})
  {
    Navigator.push(context, MaterialPageRoute(
      builder: (context)
          {
            return Comments(
              postId :postId,
              postOwnerId:ownerId,
              mediaUrl:mediaUrl,
            );
          }
    ));
  }
  buildPostFooter()
  {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 40,left: 20),
            ),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(isLiked?Icons.favorite:Icons.favorite_border
                ,size: 28,color: Colors.pink,),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
            ),
            GestureDetector(
              onTap: ()=>showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(Icons.chat,size: 28,color: Colors.blue[900],),
            ),
          ],
        ),
        Row(

          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text('$likesCount likes',style: TextStyle(fontWeight: FontWeight.bold),),
            ),
          ],
        ),
        Row(

          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text('$username ',style: TextStyle(fontWeight: FontWeight.bold),),
            ),
            Expanded(child: Text(caption),),
          ],
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId]==true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}
