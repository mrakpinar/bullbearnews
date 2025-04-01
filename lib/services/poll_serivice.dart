import 'package:bullbearnews/models/poll_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> _checkIfUserVoted(String pollId) async {
    final user = _auth.currentUser;
    if (user == null) return true; // Giriş yapmamış kullanıcı oy kullanamaz

    final doc = await _firestore.collection('polls').doc(pollId).get();
    final votedUserIds = List<String>.from(doc.data()?['votedUserIds'] ?? []);
    return votedUserIds.contains(user.uid);
  }

  Stream<List<Poll>> getActivePolls() {
    return _firestore
        .collection('polls')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Poll.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> vote(String pollId, int optionIndex) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Oy kullanmak için giriş yapmalısınız');
    }

    final hasVoted = await _checkIfUserVoted(pollId);
    if (hasVoted) {
      throw Exception('Zaten bu ankete oy kullandınız');
    }

    await _firestore.runTransaction((transaction) async {
      final docRef = _firestore.collection('polls').doc(pollId);
      final doc = await transaction.get(docRef);

      if (doc.exists) {
        final options = (doc.data()!['options'] as List<dynamic>)
            .map((opt) => PollOption.fromMap(opt))
            .toList();

        if (optionIndex >= 0 && optionIndex < options.length) {
          // Oyu güncelle
          options[optionIndex] = PollOption(
            text: options[optionIndex].text,
            votes: options[optionIndex].votes + 1,
          );

          // Kullanıcıyı oy kullananlar listesine ekle
          final votedUserIds =
              List<String>.from(doc.data()?['votedUserIds'] ?? []);
          votedUserIds.add(user.uid);

          transaction.update(docRef, {
            'options': options.map((opt) => opt.toMap()).toList(),
            'votedUserIds': votedUserIds,
          });
        }
      }
    });
  }
}
