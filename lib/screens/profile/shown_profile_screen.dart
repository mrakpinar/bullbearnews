import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ShownProfileScreen extends StatefulWidget {
  final String userId;

  const ShownProfileScreen({super.key, required this.userId});

  @override
  State<ShownProfileScreen> createState() => _ShownProfileScreenState();
}

class _ShownProfileScreenState extends State<ShownProfileScreen> {
  DocumentSnapshot? _userDoc;
  bool _isFollowing = false;
  bool _isLoading = true;
  final bool _isCurrentUser = false;
  bool _isCurrentUserLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final isFollowing = (userDoc['followers'] as List).contains(currentUserId);

    setState(() {
      _userDoc = userDoc;
      _isFollowing = isFollowing;
      _isLoading = false;
    });
  }

  Future<void> _toggleFollow() async {
    if (_isCurrentUser) return; // Eğer kullanıcı kendisini takip edemez
    setState(() {
      _isCurrentUserLoading = true;
    });

    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final targetRef =
        FirebaseFirestore.instance.collection('users').doc(widget.userId);
    final currentRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);

    if (_isFollowing) {
      await targetRef.update({
        'followers': FieldValue.arrayRemove([currentUserId])
      });

      await currentRef.update({
        'following': FieldValue.arrayRemove([widget.userId])
      });
    } else {
      await targetRef.update({
        'followers': FieldValue.arrayUnion([currentUserId])
      });

      await currentRef.update({
        'following': FieldValue.arrayUnion([widget.userId])
      });
    }

    setState(() {
      _isFollowing = !_isFollowing;
      _isCurrentUserLoading = false;
    });

    // Kullanıcıyı güncelle
    // _userDoc = await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(widget.userId)
    //     .get(); // güncelle
    // _isFollowing = (_userDoc!['followers'] as List).contains(currentUserId);
    await _loadUser(); // güncelle
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _userDoc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final nickname = _userDoc!['nickname'];
    final email = _userDoc!['email'];
    final followers = (_userDoc!['followers'] as List).length;
    final following = (_userDoc!['following'] as List).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$nickname\'s Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(
                  _userDoc!['profileImageUrl'],
                  scale: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                nickname,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Followers: $followers',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      )),
                  const SizedBox(width: 16),
                  Text('Following: $following',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      )),
                ],
              ),
              const Divider(
                color: Colors.grey,
                thickness: 1,
                height: 32,
              ),
              const SizedBox(height: 16),
              const Text(
                'User Info',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(
                color: Colors.grey,
                thickness: 1,
                height: 32,
              ),
              const SizedBox(height: 16),
              Text(
                'Username: $nickname',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'E-mail: $email',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFollowing ? Colors.red : Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isFollowing ? 'Unfollow' : 'Follow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
