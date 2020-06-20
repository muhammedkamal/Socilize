import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:socialize/models/user.dart';
import 'package:socialize/pages/create_account.dart';
import 'package:socialize/pages/activity_feed.dart';
import 'package:socialize/pages/profile.dart';
import 'package:socialize/pages/search.dart';
import 'package:socialize/pages/timeline.dart';
import 'package:socialize/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignIn googleSignIn = GoogleSignIn();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final StorageReference storageRef = FirebaseStorage.instance.ref();
final DateTime timeStamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;
  int pageIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  onTap(int pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  login() {
    googleSignIn.signIn();
  } //sign in and sign out functions

  logout() {
    googleSignIn.signOut();
  }

  handleSignIn(GoogleSignInAccount account) async{
    if (account != null) {
      await createUserInFireStore();
      setState(() {
        isAuth = true;
      });
      configurePushNotifications();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }
  configurePushNotifications(){
    final GoogleSignInAccount user = googleSignIn.currentUser;
    if (Platform.isIOS) getIosPermissions();

    _firebaseMessaging.getToken().then((token) {
     // print("Firebase Messaging Token: $token\n");
      usersRef
          .document(user.id)
          .updateData({"androidNotificationToken": token});
    });

    _firebaseMessaging.configure(
      // onLaunch: (Map<String, dynamic> message) async {},
      // onResume: (Map<String, dynamic> message) async {},
      onMessage: (Map<String, dynamic> message) async {
        //print("on message: $message\n");
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if (recipientId == user.id) {
          //print("Notification shown!");
          SnackBar snackbar = SnackBar(
              content: Text(
                body,
                overflow: TextOverflow.ellipsis,
              ));
          _scaffoldKey.currentState.showSnackBar(snackbar);
        }
        print("Notification NOT shown");
      },
    );
  }
  getIosPermissions(){
    _firebaseMessaging.requestNotificationPermissions(IosNotificationSettings(alert: true,badge: true,sound: true,));
    _firebaseMessaging.onIosSettingsRegistered.listen((settings) {
      //print("settings registered : $settings");
    });
  }
  createUserInFireStore() async {
    // check if the user is on our database
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.document(user.id).get();
    // if not create new user
    if (!doc.exists) {
      final username = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateAccount(),
        ),
      );
      usersRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoURL": user.photoUrl,
        "displayName": user.displayName,
        "email": user.email,
        "bio": "",
        "timeStamp": timeStamp,
      });
      //add user to his own followers
      followersRef.document(user.id).collection('userFollowers').document(user.id).setData({});
      doc = await usersRef.document(user.id).get();
    }
    currentUser =User.fromDocument(doc);
   // print(currentUser.email);

  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Scaffold buildAuthScreen() // will be the timeline screen soon isa
  {
    return Scaffold(
      key : _scaffoldKey,
      body: PageView(
        children: <Widget>[
          Timeline(currentUser : currentUser),
          ActivityFeed(),
          Upload(currentUser : currentUser),
          Search(),
          Profile(profileId: currentUser?.id,),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        activeColor: Theme.of(context).accentColor,
        currentIndex: pageIndex,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(
              icon: Icon(
            Icons.photo_camera,
            size: 35.0,
          )),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle)),
        ],
      ),
    );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).accentColor,
              Theme.of(context).primaryColorLight,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              'Socialize!',
              style: TextStyle(
                fontFamily: 'Signatra',
                fontSize: 90.0,
                color: Colors.white,
              ),
            ), //title
            GestureDetector(
              onTap: login,
              child: Image.asset('assets/images/google_signin_button.png'),
            ), // i was able to use flat button also ?google sign in
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    // recognizeing loging in and out
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (err) {
     // print(err);
    });
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
     // print(err);
    });
    pageController = PageController(); //can change initital page
    //followersRef.document(currentUser.id).collection('userFollowers').document(currentUser.id).setData({});

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
