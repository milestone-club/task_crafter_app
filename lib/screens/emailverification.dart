// ignore_for_file: camel_case_types, use_super_parameters, library_private_types_in_public_api

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task_crafter_app/screens/login.dart';

class verify extends StatefulWidget {
  const verify({Key? key}) : super(key: key);
  @override
  _verifyState createState() => _verifyState();
}

class _verifyState extends State<verify> {
  @override
  void initState() {
    sendverifylink();
    super.initState();
  }

  sendverifylink() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.sendEmailVerification().then((value) => Get.snackbar(
        'Link sent', 'A link has been send to your email',
        margin: const EdgeInsets.all(30)));
  }

  reload() async {
    await FirebaseAuth.instance.currentUser!
        .reload()
        .then((value) => {Get.offAll(const Login())});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(28.0),
        child: Center(
          child: Text(
              'Open your email and click on the link provided to verify email & reload this page'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (() => reload()),
        child: const Icon(Icons.restart_alt_rounded),
      ),
    );
  }
}
