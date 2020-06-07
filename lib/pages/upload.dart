import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:socialize/models/user.dart';
import 'package:image/image.dart' as Im;
import 'package:socialize/pages/home.dart';
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  TextEditingController locationController =TextEditingController();
  TextEditingController captionController =TextEditingController();
  bool isUploading = false;
  File file;
  String postId = Uuid().v4();
  handleTakePhoto() async{
    Navigator.pop(context);
    File file =await ImagePicker.pickImage(source: ImageSource.camera);
    setState(() {
      this.file =file;
    });
  }
  handleGallaryPhoto() async{
    Navigator.pop(context);
    File file =await ImagePicker.pickImage(source: ImageSource.gallery,);
    setState(() {
      this.file =file;
    });
  }
  selectImage(parentContext)
  {
    return showDialog(
      context: parentContext,
      builder: (context){
        return SimpleDialog(
          title: Text('Craete Post'),
          children: <Widget>[
            SimpleDialogOption(
              child: Text(
                'Take a Photo'
              ),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text(
                  'Photo from Gallary'
              ),
              onPressed: handleGallaryPhoto,
            ),
            SimpleDialogOption(
              child: Text(
                  'Cancel'
              ),
              onPressed: (){
                Navigator.pop(context);
              },
            ),
          ],
        );
      }
    );
  }
  Container buildSplashScreen() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset('assets/images/upload.svg'),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              onPressed: ()=>selectImage(context),
              child: Text(
                'Upload Image',
                style: TextStyle(
                  fontSize: 22.0,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
  clearImage(){
    setState(() {
      file=null;
    });
  }
  compressImage() async{
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')..writeAsBytesSync(Im.encodeJpg(imageFile,quality: 85));
    setState(() {
      file=compressedImageFile;
    });
  }
  Future<String>uploadImage(imageFile)async
  {
    StorageUploadTask uploadTask=storageRef.child('post_$postId.jpg').putFile(imageFile);
    StorageTaskSnapshot storageSnap =await uploadTask.onComplete;
    return await storageSnap.ref.getDownloadURL();
  }
  createPostInFireStore({String mediaUrl,String location,String caption})
  {
   postsRef.document((widget.currentUser.id)).collection('usersPosts').document(postId)
   .setData({
     'postId':postId,
     'ownerId':widget.currentUser.id,
     'username':widget.currentUser.username,
     'mediaUrl':mediaUrl,
     'caption':caption,
     "location":location,
     'timeStamp':timeStamp,
     'likes':{}

   });
  }
  handleSubmit() async
  {
    setState(() {
      isUploading =true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    await createPostInFireStore(mediaUrl: mediaUrl,location: locationController.text,caption: captionController.text);
    locationController.clear();
    captionController.clear();
    setState(() {
      isUploading =false;
      file=null;
    });
  }
  Scaffold buildUploadForm(){
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: clearImage,
        ),
        title: Center(child: Text('Caption Post')),
        actions: <Widget>[
          FlatButton(
            child: Text('Post',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0
              ),
            ),
            onPressed: isUploading?null:()=>handleSubmit(),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width*.8,
            child: Center(
              child: AspectRatio(aspectRatio: 16/9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file),
                    )
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Write a caption ...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.pin_drop,size: 35.0,),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Where this photo taken!',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              label: Text('Use current location'),
              icon: Icon(Icons.my_location,),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
              color: Theme.of(context).accentColor,
              onPressed: getUserLocation,
            ),
          )
        ],
      ),
    );
  }
  getUserLocation() async{
    Position position = await Geolocator().getCurrentPosition(desiredAccuracy : LocationAccuracy.low);
    List<Placemark> placeMarks = await Geolocator().placemarkFromCoordinates(position.latitude, position.longitude);

    Placemark placeMark = placeMarks[0];
    String adress= '${placeMark.locality}, ${placeMark.country}';
    locationController.text =adress;
  }
  @override
  Widget build(BuildContext context) {
    return file ==null ?buildSplashScreen():buildUploadForm();
  }
}
