import 'package:flutter/material.dart';
import 'package:task_crafter_app/screens/login.dart';

class Signup2 extends StatefulWidget {
  const Signup2({Key? key}) : super(key: key);
  @override
  _Signup2State createState() => _Signup2State();
}

class _Signup2State extends State<Signup2> {
  final _formKey = GlobalKey<FormState>();

  var email = '';
  var password = '';
  var confirmpassword = '';
  var selectedOption = '';

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
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "TaskCrafter",
          style: TextStyle(color: Colors.deepPurple),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: TextFormField(
                  obscureText: true,
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(fontSize: 20.0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    errorStyle:
                        TextStyle(color: Colors.redAccent, fontSize: 15),
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
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                child: TextFormField(
                  obscureText: true,
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(fontSize: 20.0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    errorStyle:
                        TextStyle(color: Colors.redAccent, fontSize: 15),
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
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                child: TextFormField(
                  obscureText: true,
                  autofocus: false,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(fontSize: 20.0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    errorStyle:
                        TextStyle(color: Colors.redAccent, fontSize: 15),
                  ),
                  controller: confirmPasswordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please Enter Confirm Password';
                    } else if (value != password) {
                      return "Password doesn't match";
                    }
                    return null;
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromRGBO(0, 0, 255, 0.4),
                        ),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            email = emailController.text;
                            password = passwordController.text;
                            confirmpassword = confirmPasswordController.text;
                          });
                        }
                      },
                      child: Text(
                        'Signup',
                        style: TextStyle(fontSize: 14.0, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an Account? "),
                    TextButton(
                      onPressed: () => {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, a, b) => Login(),
                            transitionDuration: Duration(seconds: 0),
                          ),
                        )
                      },
                      child: Text('Login'),
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
