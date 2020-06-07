import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:flutter/rendering.dart';
import 'package:socialize/models/user.dart';
import 'package:socialize/pages/home.dart';
import 'package:socialize/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserID;
  EditProfile({this.currentUserID});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey =GlobalKey<ScaffoldState>();
  bool isLoading=false,_bioValid=true,_displayNameValid=true;
  User user;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();

  Column buildDisplayField()
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top:12.0),
          child: Text('Display Name'),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: 'Update Display Name',
            errorText: _displayNameValid?null:"Display name is too short",
          ),
        ),
      ],
    );
  }
  Column buildBioField()
  {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top:12.0),
          child: Text('Bio'),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: 'Update Bio',
            errorText: _bioValid?null:'Bio is too long',
          ),
        )
      ],
    );
  }
  getUser()async{
    setState(() {
      isLoading=true;
    });
    DocumentSnapshot doc = await usersRef.document(widget.currentUserID).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading=false;
    });
  }

  updateProfileData()
  {
    setState(() {
      displayNameController.text.trim().length<3||displayNameController.text.isEmpty?_displayNameValid=false:_displayNameValid=true;
      bioController.text.trim().length>150?_bioValid=false:_bioValid=true;
    });
    if (_displayNameValid&&_bioValid)
      {
        usersRef.document(widget.currentUserID).updateData({
          'diplayName': displayNameController.text,
          'bio':bioController.text
        });
      }
    SnackBar snackBar =SnackBar(content: Text('Profile updated successfully!'),);
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }
  logout() {
    googleSignIn.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context)=>Home()));
  }
  @override
  void initState() {
    getUser();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.done,size: 30.0,color: Colors.green,
            ),
            onPressed: ()=>Navigator.pop(context),
          ),
        ],
      ),
      body: isLoading?circularProgress():
      ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 16,bottom: 8.0),
                  child: CircleAvatar(radius: 50.0,backgroundImage: CachedNetworkImageProvider(currentUser.photoUrl),),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      buildDisplayField(),
                      buildBioField(),
                    ],
                  ),
                ),
                RaisedButton(
                  onPressed: updateProfileData,
                  child: Text('Update Profile',style: TextStyle(fontSize: 20.0,fontWeight: FontWeight.bold),),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FlatButton.icon(onPressed: logout, icon: Icon(Icons.cancel,color: Colors.red,), label: Text('Log Out',style: TextStyle(color: Colors.red),),),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
