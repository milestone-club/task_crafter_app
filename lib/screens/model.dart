// ignore_for_file: non_constant_identifier_names

import 'package:get/get.dart';

class UserModel {
  String? email;
  String? uid;
  String? SurName;

  // receiving data
  UserModel({this.uid, this.email, this.SurName});

  factory UserModel.fromMap(map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      SurName: map['firstName'],
    );
  }

  // sending data
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': SurName,
    };
  }

  // extract first name from email address
  static String extractFirstNameFromEmail(String email) {
    final parts = email.split('@');
    if (parts.length > 1) {
      return parts[0].split('.').map((e) => e.capitalize).join(' ');
    }
    return '';
  }
}
