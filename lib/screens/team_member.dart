// ignore_for_file: camel_case_types, use_super_parameters, prefer_const_constructors_in_immutables, library_private_types_in_public_api, prefer_const_constructors, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_crafter_app/screens/login.dart';

class team_member extends StatefulWidget {
  team_member({Key? key}) : super(key: key);
  @override
  _team_memberState createState() => _team_memberState();
}

class _team_memberState extends State<team_member> {
  final user = FirebaseAuth.instance.currentUser;

  signout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => Login()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: TextStyle(
          color: Colors.deepPurple,
          fontSize: 20.0,
        ),
        centerTitle: true,
        title: Text('Home Page'),
      ),
      body: FloatingActionButton(
        onPressed: (() => signout()),
        child: Icon(Icons.login_rounded),
      ),
    );
  }
}
