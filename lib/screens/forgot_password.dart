// ignore_for_file: unused_local_variable, use_super_parameters, library_private_types_in_public_api, avoid_unnecessary_containers

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_crafter_app/screens/login.dart';
import 'package:task_crafter_app/screens/signup1.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formkey = GlobalKey<FormState>();

  reset() async {
    await FirebaseAuth.instance
        .sendPasswordResetEmail(email: emailController.text);
  }

  var email = '';
  final emailController = TextEditingController();

  @override
  void dispose();

  @override
  Widget build(BuildContext context) {
    var formkey = _formkey;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: const Text(
              'Reset Link will be sent to your email id !',
              style: TextStyle(fontSize: 20.0),
            ),
          ),
          Expanded(
              child: Form(
                  key: _formkey,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: ListView(
                      children: [
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: TextFormField(
                            autofocus: false,
                            decoration: InputDecoration(
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
                                return 'Please enter Email';
                              } else if (!value.contains('@')) {
                                return 'Please enter valid Email';
                              }
                              return null;
                            },
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.all<Color>(
                                    const Color.fromRGBO(0, 0, 255, 0.4),
                                  ),
                                ),
                                onPressed: () {
                                  if (_formkey.currentState!.validate()) {
                                    setState(() {
                                      email = emailController.text;
                                    });
                                    reset();
                                  }
                                },
                                child: const Text(
                                  'Send Email',
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.white),
                                ),
                              ),
                              TextButton(
                                onPressed: () => {
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, a, b) =>
                                            const Login(),
                                        transitionDuration:
                                            const Duration(seconds: 0),
                                      ),
                                      (route) => false)
                                },
                                child: const Text(
                                  'Login',
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
                              const Text("Don't have an Account?"),
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
                                  child: const Text('Signup'))
                            ],
                          ),
                        )
                      ],
                    ),
                  )))
        ],
      ),
    );
  }
}
