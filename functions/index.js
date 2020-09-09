const functions = require('firebase-functions');
const admin = require('firebase-admin');
//const { user } = require('firebase-functions/lib/providers/auth');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
exports.onCreateFollower = functions.firestore
.document('/followers/{userId}/userFollowers/{followerId}')
.onCreate(async (snapshot, context) => {
    console.log("Follower created", snapshot.id);
    const userId = context.params.userId;
    const followerId = context.params.followerId;

    // create followed users posts
    const followedUserPostsRef = admin
    .firestore()
    .collection('posts')
    .doc(userId)
    .collection('userPosts');

    //create following users timeline
    const timelinePostsRef = admin
    .firestore()
    .collection('timeline')
    .doc(followerId)
    .collection('timelinePosts');

    //get followed users posts
    const querySnapshot = await followedUserPostsRef.get();

    //add each user post to following users timeline

    querySnapshot.forEach(doc => {
        if(doc.exists) {
            const postId = doc.id;
            const postData = doc.data();
            timelinePostsRef.doc(postId).set(postData);
        }
    });
});

exports.onDeleteFollower = functions.firestore
.document('/followers/{userId}/userFollowers/{followerId}')
.onDelete(async (snapshot, context) => {
    console.log('Follower deleted', snapshot.id);

    const userId = context.params.userId;
    const followerId = context.params.followerId;

    const timelinePostsRef = admin
    .firestore()
    .collection('timeline')
    .doc(followerId)
    .collection('timelinePosts')
    .where('ownerId', "==", userId);

    const querySnapshot = await timelinePostsRef.get();
    querySnapshot.forEach(doc => {
        if(doc.exists) {
            doc.ref.delete();
        }
    });
});

//when a post is crated, add post to timeline of each follower of post owner

exports.onCreatePost = functions.firestore
.document('/posts/{userId}/userPosts/{postId}')
.onCreate(async(snapshot, context) => {
    const postCreated = snapshot.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    //get all the followers of the user post owner
    const userFollowersRef = admin
        .firestore()
        .collection('followers')
        .doc(userId)
        .collection('userFollowers');

    const querySnapshot = await userFollowersRef.get();
    //add new post to each follower timeline

    querySnapshot.forEach(doc => {
        const followerId = doc.id;
    admin
        .firestore()
        .collection('timeline')
        .doc(followerId)
        .collection('timelinePosts')
        .doc(postId)
        .set(postCreated);
    });
});

//when a post is updated, update the posts for the timelines

exports.onUpdatePost = functions.firestore
.document('/posts/{userId}/userPosts/{postId}')
.onUpdate(async (change, context) => {
    const postUpdated = change.after.data();
    const userId = context.params.userId;
    const postId = context.params.postId;

    //get all the followers of the user post owner
    const userFollowersRef = admin
        .firestore()
        .collection('followers')
        .doc(userId)
        .collection('userFollowers');
    const querySnapshot = await userFollowersRef.get();
//update each post
    querySnapshot.forEach(doc => {
    const followerId = doc.id;

    admin
    .firestore()
    .collection('timeline')
    .doc(followerId)
    .collection('timelinePosts')
    .doc(postId)
    .get()
    .then(doc => {
        if(doc.exists) {
            doc.ref.update(postUpdated);
        }
    });
    });

});

exports.onDeletePost = functions.firestore
.document('/posts/{userId}/userPosts/{postId}')
.onDelete(async (snapshot, context) => {

    const userId = context.params.userId;
    const postId = context.params.postId;

    //get all the followers of the user post owner
    const userFollowersRef = admin
        .firestore()
        .collection('followers')
        .doc(userId)
        .collection('userFollowers');
    const querySnapshot = await userFollowersRef.get();
//delete each post
    querySnapshot.forEach(doc => {
        const followerId = doc.id;
    admin
    .firestore()
    .collection('timeline')
    .doc(followerId)
    .collection('timelinePosts')
    .doc(postId)
    .get()
    .then(doc => {
        if(doc.exists) {
            doc.ref.delete();
        }
    });
    });
});

exports.onCreateActivityFeedItem = functions.firestore
.document('feed/{userId}/feedItems/{activityFeedItem}')
.onCreate(async (snapshot, context) => {
    console.log('activity feed item created', snapshot.data());

    //get user connected to feed
    const userId = context.params.userId;
    const userRef = admin.firestore().doc(`users/${userId}`);
    const doc = await userRef.get();

    //once we have user, check if they have a notification token and send notification if have token
    const androidNotificationToken =  doc.data().androidNotificationToken;
    const createdActivityFeedItem = snapshot.data();

    if(androidNotificationToken) {
        //send notif
        sendNotification(androidNotificationToken, createdActivityFeedItem);
    } else {
        console('no token avaible for user');
    }

    function sendNotification(androidNotificationToken, activityFeedItem) {
        let body;

        //switch body value based on notification type
        switch (activityFeedItem.type) {
            case 'comment':
                body = `${activityFeedItem.username} replied: ${activityFeedItem.commentData}`;
                break;
                case 'like':
                    body = `${activityFeedItem.username} liked your post. ❤️`;
                    break;
                case 'follow':
                body = `${activityFeedItem.username} started following you 👀`;
                break;
            default:
                break;
        }
        // create message for push notification
        const message = {
            notification: {body},
            token: androidNotificationToken,
            data: {recipient: userId }
        };
        // send message with admin messaging
        admin
            .messaging
            .send(message)
            .then(response => {
                //response is a message ID string
                console.log('successfully sent message', response);
            })
            .catch(error => {
                console.log('error sending message', error);
            });
    }
});