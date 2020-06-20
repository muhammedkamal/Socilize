const functions = require('firebase-functions');
const admin = require("firebase-admin");
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });
exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async (snapshot, context) => {
        console.log("follower created", snapshot.id);
        const userId = context.params.userId;
        const followerId = context.params.followerId;
        // 1) create follower users posts
        const followerUserPostsRef = admin.firestore().collection("posts").doc(userId).collection("usersPosts");
        // 2) create following users's timeline
        const timelinePostRef = admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts");
        // 3) get followed users post 
        const querySnapshot = await followerUserPostsRef.get();
        // 4) add each user post to following timeline 
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                timelinePostRef.doc(postId).set(postData);
            }

        });

    });

exports.onDeleteFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onDelete(async (snapshot, context) => {
        console.log("follower deleted", snapshot.id);
        const userId = context.params.userId;
        const followerId = context.params.followerId;


        const timelinePostRef = admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts")
            .where("ownerId", "==", userId);

        const querySnapshot = await timelinePostRef.get();
        // 4) add each user post to following timeline 
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        })

    });

exports.onCreatePost = functions.firestore.document("/posts/{userId}/usersPosts/{postId}")
    .onCreate(async (snapshot, context) => {
        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;
        // get all followers of the post craetor
        const userFollowersRef = admin.firestore().collection("followers").doc(userId)
            .collection("userFollowers");
        const querySnapshot = await userFollowersRef.get();
        // add new post to each follower timeline
        querySnapshot.forEach(doc => {
            const followerId = doc.id;
            admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts")
                .doc(postId).set(postCreated);
        });
    });

exports.onUpdatePost = functions.firestore.document("/posts/{userId}/usersPosts/{postId}")
    .onUpdate(async (change, context) => {
        const postUpdate = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;
        // get all followers of the post craetor
        const userFollowersRef = admin.firestore().collection("followers").doc(userId)
            .collection("userFollowers");
        const querySnapshot = await userFollowersRef.get();
        // update post to each follower timeline
        querySnapshot.forEach(doc => {
            const followerId = doc.id;
            admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts")
                .doc(postId).get().then(doc => {
                    if (doc.exists)
                        doc.ref.update(postUpdate);
                });
        });
    });


exports.onDeletePost = functions.firestore.document("/posts/{userId}/usersPosts/{postId}")
    .onDelete(async (snapshot, context) => {
        const postDelete = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;
        // get all followers of the post craetor
        const userFollowersRef = admin.firestore().collection("followers").doc(userId)
            .collection("userFollowers");
        const querySnapshot = await userFollowersRef.get();
        // update post to each follower timeline
        querySnapshot.forEach(doc => {
            const followerId = doc.id;
            admin.firestore().collection("timeline").doc(followerId).collection("timelinePosts")
                .doc(postId).get().then(doc => {
                    if (doc.exists)
                        doc.ref.delete(postDelete);
                });
        });
    });
exports.onCreateActivityFeedItem = functions.firestore
  .document("/feed/{userId}/feedItems/{activityFeedItem}")
  .onCreate(async (snapshot, context) => {
    console.log("Activity Feed Item Created", snapshot.data());

    // 1) Get user connected to the feed
    const userId = context.params.userId;

    const userRef = admin.firestore().doc("users/${userId}");
    const doc = await userRef.get();

    // 2) Once we have user, check if they have a notification token; send notification, if they have a token
    const androidNotificationToken = doc.data().androidNotificationToken;
    const createdActivityFeedItem = snapshot.data();
    if (androidNotificationToken) {
      sendNotification(androidNotificationToken, createdActivityFeedItem);
    } else {
      console.log("No token for user, cannot send notification");
    }

    function sendNotification(androidNotificationToken, activityFeedItem) {
      let body;

      // 3) switch body value based off of notification type
      switch (activityFeedItem.type) {
        case "comment":
          body = `${activityFeedItem.username} replied: ${
            activityFeedItem.commentData
          }`;
          break;
        case "like":
          body = `${activityFeedItem.username} liked your post`;
          break;
        case "follow":
          body = `${activityFeedItem.username} started following you`;
          break;
        default:
          break;
      }

      // 4) Create message for push notification
      const message = {
        notification: { body },
        token: androidNotificationToken,
        data: { recipient: userId }
      };

      // 5) Send message with admin.messaging()
      admin
        .messaging()
        .send(message)
        .then(response => {
          // Response is a message ID string
          console.log("Successfully sent message", response);
        })
        .catch(error => {
          console.log("Error sending message", error);
        });
    }
  });
