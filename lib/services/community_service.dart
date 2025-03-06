import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/community_post_model.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<CommunityPost>> getCommunityPosts() {
    return _firestore
        .collection('community_posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromFirestore(doc))
            .toList());
  }

  Future<void> createPost(String content) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      String username = currentUser.displayName ?? '';

      // Eğer username boşsa, e-mail adresinin @ işaretinden önceki kısmını kullan
      if (username.isEmpty && currentUser.email != null) {
        username = currentUser.email!.split('@')[0];
      }

      // Yine de boşsa, varsayılan 'Anonymous' kullan
      if (username.isEmpty) {
        username = 'Anonymous';
      }

      await _firestore.collection('community_posts').add(
            CommunityPost(
              id: '',
              userId: currentUser.uid,
              username: username,
              content: content,
              timestamp: DateTime.now(),
              likes: 0,
              userProfileImage: currentUser.photoURL,
            ).toFirestore(),
          );
    }
  }

  Future<void> likePost(CommunityPost post) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentReference postRef =
          _firestore.collection('community_posts').doc(post.id);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(postRef);
        if (snapshot.exists) {
          int newLikes =
              (snapshot.data() as Map<String, dynamic>)['likes'] ?? 0;
          newLikes += 1;
          transaction.update(postRef, {'likes': newLikes});
        }
      });
    }
  }
}
