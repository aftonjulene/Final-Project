import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserCredential> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await _createUserProfileIfNeeded(user);
    return credential;
  }

  Future<UserCredential> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await _updateLastLogin(user);
    return credential;
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> _createUserProfileIfNeeded(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      final profile = UserProfile(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await ref.set(profile.toMap());
    } else {
      await _updateLastLogin(user);
    }
  }

  Future<void> _updateLastLogin(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    await ref.update({'lastLoginAt': Timestamp.fromDate(DateTime.now())});
  }
}
