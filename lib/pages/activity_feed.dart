import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialize/pages/home.dart';
import 'package:socialize/pages/post_screen.dart';
import 'package:socialize/pages/profile.dart';
import 'package:socialize/widgets/header.dart';
import 'package:socialize/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;


class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}
Widget mediaPreview;
String activityItemText;
class _ActivityFeedState extends State<ActivityFeed> {
  getActivityFeed ()async
  {
    QuerySnapshot snapshot = await activityFeedRef.document(currentUser.id)
        .collection('feedItems').orderBy('timestamp',descending: true).limit(50)
        .getDocuments();
    List<ActivityFeedItem> feedItems=[];
    snapshot.documents.forEach((doc){
      feedItems.add(ActivityFeedItem.fromDocument(doc));
    });
    return feedItems;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context,pageTitle: "Activity Feed"),
      body: FutureBuilder(
        future: getActivityFeed(),
        builder: (context,snapshot){
          if (!snapshot.hasData)
            return circularProgress();
          return ListView(
            children: snapshot.data,
          );
        },
      ),
    );
  }
}

class ActivityFeedItem extends StatelessWidget {
  final String username,userId,type,commentData,mediaUrl,userProfileImg,postId;
  final Timestamp timestamp;
  ActivityFeedItem ({this.username, this.userId, this.type, this.commentData, this.mediaUrl, this.userProfileImg, this.postId, this.timestamp});
  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc){
    return ActivityFeedItem(
      username : doc['username'],
      userId : doc['userId'],
      type: doc['type'],
      userProfileImg :doc['userProfileImg'],
      commentData : doc['commentData'],
      postId :doc['postId'],
      timestamp: doc['timestamp'],
      mediaUrl: doc['mediaUrl'],
    );
  }
  showPost(context){
    Navigator.push(context, MaterialPageRoute(builder: (context)=>PostScreen(userId: userId,postId: postId,),),);
  }
  configureMediaPreview(BuildContext context)
  {
    if (type=='like'||type=='comment')
      {
        mediaPreview = GestureDetector(
          onTap: ()=>showPost(context),
          child: Container(
            height: 50.0,
            width: 50.0,
            child: AspectRatio(
              aspectRatio: 16/9,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(mediaUrl),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    else{
      print("follow");
    }
    if(type=='like')
      activityItemText = "liked your post";
    else if(type=='comment')
      activityItemText = "commented: '$commentData'";
    else if(type=='follow')
      activityItemText = "start following you";
    else
      activityItemText = "Error: Unknown type $type";
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Container(
        color: Colors.black,
        child: ListTile(
          title: GestureDetector(
            onTap: ()=>showProfile(context,profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(fontSize: 14.0),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:' $activityItemText',
                  ),
                ],
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: mediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context,{String profileId})
{
  Navigator.push(context, MaterialPageRoute(builder: (context)=>Profile(profileId: profileId,),),);
}