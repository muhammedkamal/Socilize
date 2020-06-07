import 'package:cloud_firestore/cloud_firestore.dart';
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

  handleSignIn(GoogleSignInAccount account) {
    if (account != null) {
      createUserInFireStore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
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
      doc = await usersRef.document(user.id).get();
    }
    currentUser =User.fromDocument(doc);
    print(currentUser.email);

  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Scaffold buildAuthScreen() // will be the timeline screen soon isa
  {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          //Timeline(),
          RaisedButton(
            onPressed: logout,
            child: Text('logout'),
          ),
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
      print(err);
    });
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      handleSignIn(account);
    }).catchError((err) {
      print(err);
    });
    pageController = PageController(); //can change initital page
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
