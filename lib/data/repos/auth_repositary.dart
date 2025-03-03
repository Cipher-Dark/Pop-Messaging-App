import 'dart:developer';

import 'package:pop_chat/data/models/user_model.dart';
import 'package:pop_chat/data/services/base_repositary.dart';

class AuthRepositary extends BaseRepositary {
  Future<UserModel> signUp({
    required String fullName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final formattedPhoneNumber = phoneNumber.replaceAll(
        RegExp(r'\s+'),
        "".trim(),
      );
      final userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user == null) {
        throw "Failed to create user";
      }
      //create a user model and save the user in the db firestore
      final user = UserModel(
        uid: userCredential.user!.uid,
        fullName: fullName,
        username: username,
        email: email,
        phoneNumber: formattedPhoneNumber,
      );
      await saveUserData(user);
      return user;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<void> saveUserData(UserModel user) async {
    try {
      await firestore.collection("users").doc(user.uid).set(user.toMap());
    } catch (e) {
      throw "Failed to save user data";
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);
      if (userCredential.user == null) {
        throw "failed to signIn";
      }
      final userData = await getUserData(userCredential.user!.uid);
      return userData;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<UserModel> getUserData(String uid) async {
    try {
      final doc = await firestore.collection("users").doc(uid).get();
      if (!doc.exists) {
        throw "User data not found";
      }
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw "Failed to get user data";
    }
  }
}
