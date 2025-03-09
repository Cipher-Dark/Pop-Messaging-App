import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:pop_chat/data/models/user_model.dart';
import 'package:pop_chat/data/services/base_repositary.dart';

class AuthRepository extends BaseRepositary {
  Stream<User?> get authStateChnages => auth.authStateChanges();

  Future<UserModel> signUp({
    required String fullName,
    required String userName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final formattedPhoneNumber = phoneNumber.replaceAll(
        RegExp(r'\s+'),
        "".trim(),
      );
      final emailExist = await checkEmailExists(email);
      if (emailExist) {
        throw "An account with same email already exist";
      }
      final phoneExist = await checkPhoneExists(formattedPhoneNumber);
      if (phoneExist) {
        throw "An account with same phone number already exist";
      }
      final userNameExist = await checkUserNameExists(userName);
      if (userNameExist) {
        throw "An account with same user Name already exist";
      }
      final userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user == null) {
        throw "Failed to create user";
      }
      //create a user model and save the user in the db firestore
      final user = UserModel(
        uid: userCredential.user!.uid,
        fullName: fullName,
        username: userName,
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

  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      log("Error checking email $e");
      return false;
    }
  }

  Future<bool> checkPhoneExists(String phone) async {
    try {
      final formattedPhoneNumber = phone.replaceAll(
        RegExp(r'\s+'),
        "".trim(),
      );
      final querySnapshot = await firestore.collection("users").where("phoneNumber", isEqualTo: formattedPhoneNumber).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log("Error checking phone $e");
      return false;
    }
  }

  Future<bool> checkUserNameExists(String username) async {
    try {
      final querySnapshot = await firestore.collection("users").where("username", isEqualTo: username).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      log("Error checking username $e");
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      auth.signOut();
    } catch (e) {
      throw "Failed to Sign Out";
    }
  }
}
