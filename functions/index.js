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