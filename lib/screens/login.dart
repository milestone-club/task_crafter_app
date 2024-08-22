// ignore_for_file: use_super_parameters, library_private_types_in_public_api, avoid_print, avoid_unnecessary_containers

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:task_crafter_app/screens/dashboard.dart';
import 'package:task_crafter_app/screens/forgot_password.dart';
import 'package:task_crafter_app/screens/signup1.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  bool isloading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  userLogin() async {
    setState(() {
      isloading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text, password: passwordController.text);

      await _saveFCMToken(); // Save FCM token after successful login

      route();
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.code);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
    setState(() {
      isloading = false;
    });
  }

  Future<void> _saveFCMToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      String? deviceToken =
          await FirebaseMessaging.instance.getToken(); // Generate device token
      if (fcmToken != null && deviceToken != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': fcmToken,
          'deviceToken': deviceToken,
        });
      }
    }
  }

  void route() {
    User? user = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => dashboard()),
        );
      } else {
        print('Document does not exist on the database');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return isloading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
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
                      color:
                          Color.fromARGB(255, 250, 250, 250).withOpacity(0.2),
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
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(164, 218, 65, 136)
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                      height:
                                          28), // For spacing the profile circle
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
                                            fontSize: 20.0,
                                            color: Colors.white),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  159, 128, 3, 45)),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        errorStyle: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 15),
                                        prefixIcon: Icon(Icons.email,
                                            color: Colors.white),
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
                                    height: 75, // Adjusted height
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
                                            fontSize: 20.0,
                                            color: Colors.white),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color: Color.fromARGB(
                                                  159, 128, 3, 45)),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        errorStyle: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 15),
                                        prefixIcon: Icon(Icons.lock,
                                            color: Colors.white),
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
                                          // Get values from the controllers
                                        });
                                        userLogin();
                                      }
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 26, vertical: 9),
                                      child: Text(
                                        'Login',
                                        style: TextStyle(
                                            fontSize: 22.0,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPassword(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password ?',
                                      style: TextStyle(
                                          fontSize: 14.0, color: Colors.white),
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Don't have an Account? ",
                                          style: TextStyle(
                                              fontSize: 15.0,
                                              color: Colors.white)),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushAndRemoveUntil(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, a, b) =>
                                                  const Signup1(),
                                              transitionDuration:
                                                  const Duration(seconds: 0),
                                            ),
                                            (route) => false,
                                          );
                                        },
                                        child: Text(
                                          'Signup',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Color.fromARGB(255, 237, 3, 96)
                                  .withOpacity(1),
                              child: Icon(Icons.person,
                                  size: 80, color: Colors.white),
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
