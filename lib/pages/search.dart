import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialize/pages/activity_feed.dart';
import 'package:socialize/pages/home.dart';
import 'package:socialize/widgets/progress.dart';
import 'package:socialize/models/user.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  handleSearch(String query) {
    Future<QuerySnapshot> users = usersRef
        .where('displayName', isGreaterThanOrEqualTo: query)
        .getDocuments();
    setState(() {
      searchResultsFuture = users;
    });
  }

  buildSearchResults() {
    return FutureBuilder(
        future: searchResultsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return circularProgress();
          List<UserResult> searchResults = [];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromDocument(doc);
            UserResult searchResult = UserResult(user);
            searchResults.add(searchResult);
          });
          return ListView(children: searchResults);
        });
  }

  AppBar buildSearchField() {
    return AppBar(
      title: TextFormField(
        controller: searchController,
        onFieldSubmitted: handleSearch,
        decoration: InputDecoration(
            hintText: "Serach for User ...",
            filled: true,
            prefixIcon: Icon(
              Icons.account_box,
              size: 28.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                Icons.clear,
              ),
              onPressed: () {
                searchController.clear();
              },
            )),
      ),
    );
  }

  Container buildNoContent() {
    final orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/search.svg',
              height: orientation == Orientation.portrait ? 300 : 200,
            ),
            Text(
              'Find User',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 60.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSearchField(),
      body:
          searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColorLight,
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () =>showProfile(context,profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
              ),
              title: Text(
                user.displayName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.username,
            ),
          ),
          ),
          Divider(
            height: 2.0,
            color: Colors.teal,
          )
        ],
      ),
    );
  }
}
