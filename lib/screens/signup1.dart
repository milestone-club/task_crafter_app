import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_crafter_app/screens/login.dart';
import 'package:task_crafter_app/screens/model.dart';

class Signup1 extends StatefulWidget {
  const Signup1({Key? key}) : super(key: key);

  @override
  _Signup1State createState() => _Signup1State();
}

class _Signup1State extends State<Signup1> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  CollectionReference ref = FirebaseFirestore.instance.collection('users');

  void signup(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      if (mounted) {
        postDetailsToFirestore(email);
      }
    } catch (e) {
      print('Error during sign up: $e');
    }
  }

  postDetailsToFirestore(String email) async {
    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    User? user = _auth.currentUser;
    UserModel userModel = UserModel();
    userModel.email = email;
    userModel.uid = user!.uid;
    userModel.SurName = UserModel.extractFirstNameFromEmail(email);
    await firebaseFirestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => Login()));
    }
  }

  var email = '';
  var password = '';
  var confirmpassword = '';
  File? file;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login-background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: Container(
                color: Color.fromARGB(255, 250, 250, 250).withOpacity(0.2),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(30.0),
                child: Form(
                  key: _formKey,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 60),
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(164, 218, 65, 136)
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                                height: 28), // For spacing the profile circle
                            Container(
                              height: 75, // Adjusted height
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 237, 3, 96)
                                    .withOpacity(0),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextFormField(
                                obscureText: false,
                                autofocus: true,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                      fontSize: 20.0, color: Colors.white),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color.fromARGB(159, 128, 3, 45)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  errorStyle: TextStyle(
                                      color: Colors.redAccent, fontSize: 15),
                                  prefixIcon:
                                      Icon(Icons.email, color: Colors.white),
                                ),
                                controller: emailController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Valid Email';
                                  } else if (!value.contains('@')) {
                                    return 'Please Enter Valid Email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 15),
                            Container(
                              height: 69, // Adjusted height
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 237, 3, 96)
                                    .withOpacity(0),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextFormField(
                                obscureText: true,
                                autofocus: false,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(
                                      fontSize: 20.0, color: Colors.white),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color.fromARGB(159, 128, 3, 45)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  errorStyle: TextStyle(
                                      color: Colors.redAccent, fontSize: 15),
                                  prefixIcon:
                                      Icon(Icons.lock, color: Colors.white),
                                ),
                                controller: passwordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Password';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 15),
                            Container(
                              height: 69, // Adjusted height
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 237, 3, 96)
                                    .withOpacity(0),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: TextFormField(
                                obscureText: true,
                                autofocus: false,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  labelStyle: TextStyle(
                                      fontSize: 20.0, color: Colors.white),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color.fromARGB(159, 128, 3, 45)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  errorStyle: TextStyle(
                                      color: Colors.redAccent, fontSize: 15),
                                  prefixIcon:
                                      Icon(Icons.lock, color: Colors.white),
                                ),
                                controller: confirmPasswordController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Password';
                                  } else if (value != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                  Color.fromARGB(255, 237, 3, 96)
                                      .withOpacity(0.8),
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    email = emailController.text;
                                    password = passwordController.text;
                                    confirmpassword =
                                        confirmPasswordController.text;
                                  });
                                  signup(email, password);
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 26, vertical: 9),
                                child: Text(
                                  'Signup',
                                  style: TextStyle(
                                      fontSize: 22.0, color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Already have an Account? ",
                                    style: TextStyle(
                                        fontSize: 15.0, color: Colors.white)),
                                TextButton(
                                  onPressed: () => {
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, a, b) => Login(),
                                        transitionDuration:
                                            Duration(seconds: 0),
                                      ),
                                    )
                                  },
                                  child: Text('Login',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            Color.fromARGB(255, 237, 3, 96).withOpacity(1),
                        child:
                            Icon(Icons.person, size: 80, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
