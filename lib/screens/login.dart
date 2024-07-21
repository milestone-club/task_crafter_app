// ignore_for_file: use_super_parameters, library_private_types_in_public_api, avoid_print, avoid_unnecessary_containers

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
          MaterialPageRoute(builder: (context) => const dashboard()),
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
            appBar: AppBar(
              titleTextStyle: const TextStyle(
                color: Colors.deepPurple,
                fontSize: 20.0,
              ),
              centerTitle: true,
              title: const Text("TaskCrafter"),
            ),
            body: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: ListView(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: TextFormField(
                        autofocus: true,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.email_outlined),
                          labelText: 'Email',
                          labelStyle: const TextStyle(fontSize: 20.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          errorStyle: const TextStyle(
                              color: Colors.redAccent, fontSize: 15),
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
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: TextFormField(
                        obscureText: true,
                        autofocus: false,
                        decoration: InputDecoration(
                          icon: const Icon(Icons.password_outlined),
                          labelText: 'Password',
                          labelStyle: const TextStyle(fontSize: 20.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          errorStyle: const TextStyle(
                              color: Colors.redAccent, fontSize: 15),
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all<Color>(
                                const Color.fromRGBO(0, 0, 255, 0.4),
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
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                  fontSize: 14.0, color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () => {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPassword(),
                                ),
                              )
                            },
                            child: const Text(
                              'Forgot Password ?',
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an Account? "),
                          TextButton(
                            onPressed: () => {
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (context, a, b) =>
                                        const Signup1(),
                                    transitionDuration:
                                        const Duration(seconds: 0),
                                  ),
                                  (route) => false)
                            },
                            child: const Text(
                              'Signup',
                              style: TextStyle(
                                  color: Colors.deepPurple, fontSize: 14.0),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
  }
}
