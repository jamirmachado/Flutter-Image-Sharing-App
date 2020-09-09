import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:savepoint/models/user.dart';
import 'package:savepoint/pages/home.dart';
import 'package:savepoint/widgets/post.dart';
import 'package:savepoint/widgets/post_tile.dart';
import 'package:savepoint/widgets/progress.dart';

import '../widgets/header.dart';
import 'edit_profile.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final String currentUserId = currentUser?.id;
  String postOrientation = "grid";
  bool isLoading = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followersCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildProfileHeader() {
    Column buildCountColumn(String label, int count) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            count.toString(),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w400),
            ),
          ),
        ],
      );
    }

    editProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfile(currentUserId: currentUserId),
        ),
      ).then((value) {
        setState(() {});
      });
    }

    buildButton({String text, Function function}) {
      return Container(
        padding: EdgeInsets.only(top: 2),
        child: FlatButton(
          onPressed: function,
          child: Container(
            width: 250,
            height: 27,
            child: Text(
              text,
              style: TextStyle(
                color: isFollowing ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFollowing ? Colors.white : Colors.blue,
              border: Border.all(
                color: isFollowing ? Colors.grey : Colors.blue,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      );
    }

    buildProfileButton() {
      //view own profile, sho profile button to edit
      bool isProfileOwner = currentUserId == widget.profileId;

      //follow / unfollow handles
      handleUnfollowUser() {
        setState(() {
          isFollowing = false;
        });
        //remove de follower
        followersRef
            .document(widget.profileId)
            .collection('userFollowers')
            .document(currentUserId)
            .get()
            .then((doc) {
          if (doc.exists) {
            doc.reference.delete();
          }
        });
        //remove following
        followingRef
            .document(currentUserId)
            .collection('userFollowing')
            .document(widget.profileId)
            .get()
            .then((doc) {
          if (doc.exists) {
            doc.reference.delete();
          }
        });
      }

      handleFollowUser() {
        setState(() {
          isFollowing = true;
        });
        //make auth user follower of THAT user (update THEIR followers collection)
        followersRef
            .document(widget.profileId)
            .collection('userFollowers')
            .document(currentUserId)
            .setData({});
        // Put THAT user on YOUR following colletion (update your following colletion)
        followingRef
            .document(currentUserId)
            .collection('userFollowing')
            .document(widget.profileId)
            .setData({});
        //add notification about follow
        activityFeedRef
            .document(widget.profileId)
            .collection('feedItems')
            .document(currentUserId)
            .setData({
          'type': 'follow',
          'ownerId': widget.profileId,
          'username': currentUser.username,
          'userId': currentUserId,
          'userProfileImg': currentUser.avatar,
          'timestamp': timestamp,
        });
      }

      if (isProfileOwner) {
        return buildButton(
          text: "Edit profile",
          function: editProfile,
        );
      } else if (isFollowing) {
        return buildButton(
          text: "Unfollow",
          function: handleUnfollowUser,
        );
      } else if (!isFollowing) {
        return buildButton(
          text: "Follow",
          function: handleFollowUser,
        );
      }
    }

    return FutureBuilder(
        future: usersRef.document(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromDocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey,
                      backgroundImage: CachedNetworkImageProvider(user.avatar),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              buildCountColumn("posts", postCount),
                              buildCountColumn("followers", followersCount),
                              buildCountColumn("following", followingCount),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              buildProfileButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    user.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    "@" + user.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    user.bio,
                  ),
                ),
              ],
            ),
          );
        });
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: 260,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'No posts yet ;(',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1,
        crossAxisSpacing: 1,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }

  setPostsOrientation(String postOrientation) {
    setState(() {
      this.postOrientation = postOrientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => setPostsOrientation("grid"),
          icon: Icon(Icons.grid_on),
          color: postOrientation == 'grid' ? Colors.black : Colors.grey,
        ),
        IconButton(
          onPressed: () => setPostsOrientation("list"),
          icon: Icon(Icons.list),
          color: postOrientation == 'list' ? Colors.black : Colors.grey,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
