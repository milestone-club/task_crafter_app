import 'package:flutter/material.dart';
import 'package:task_crafter_app/screens/signup1.dart';
import 'package:task_crafter_app/screens/signup2.dart';

class Signupas extends StatefulWidget {
  Signupas({Key? key}) : super(key: key);
  @override
  _SignupasState createState() => _SignupasState();
}

class _SignupasState extends State<Signupas> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleTextStyle: TextStyle(
          color: Colors.deepPurple,
          fontSize: 20.0,
        ),
        centerTitle: true,
        title: Text(''),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'Task Crafter',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                  fontSize: 30,
                ),
              ),
            ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              child: const Text(
                'Signup As',
                style: TextStyle(fontSize: 20),
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
                    onPressed: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Signup1(),
                        ),
                      ),
                    },
                    child: Text(
                      'Project Manager',
                      style: TextStyle(fontSize: 14.0, color: Colors.white),
                    ),
                  ),
                ],
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
                    onPressed: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Signup2(),
                        ),
                      ),
                    },
                    child: Text(
                      'Team Member',
                      style: TextStyle(fontSize: 14.0, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
