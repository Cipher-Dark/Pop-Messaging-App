import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:pop_chat/data/models/user_model.dart';
import 'package:pop_chat/data/services/base_repositary.dart';

class ContactRepositary extends BaseRepositary {
  String get currentUserID => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<bool> requestContactPermission() async {
    return await FlutterContacts.requestPermission();
  }

  Future<List<Map<String, dynamic>>> getRegisteredContacts() async {
    try {
      // get all device contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      // extract the phone numbers and normalize them or format in simple number like 766**198**

      final phoneNumber = contacts
          .where((contact) => contact.phones.isNotEmpty)
          .map((contact) => {
                'name': contact.displayName,
                'phoneNumber': contact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), ''),
                'photo': contact.photo,
              })
          .toList();

      // get all users form users
      final usersSnapshot = await firestore.collection("users").get();
      final registeredUsers = usersSnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();

      //match contact with registered users
      final matchedContacts = phoneNumber.where((contact) {
        final phoneNumber = contact['phoneNumber'];
        return registeredUsers.any(
          (user) => user.phoneNumber == phoneNumber && user.uid != currentUserID,
        );
      }).map((contact) {
        final registerUser = registeredUsers.firstWhere((user) => user.phoneNumber == contact['phoneNumber']);
        return {
          'id': registerUser.uid,
          'name': contact['name'],
          'phoneNumber': contact['phoneNumber'],
        };
      }).toList();
      return matchedContacts;
    } catch (e) {
      log("error getting users");
      return [];
    }
  }
}
