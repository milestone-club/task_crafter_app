import 'package:flutter/material.dart';
import 'package:task_crafter_app/screens/signup1.dart';

void main() {
  runApp(homepage());
}

class homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Crafter',
      theme: ThemeData(
        fontFamily: 'Roboto', // Set the default font family to Roboto
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color.fromARGB(255, 249, 251, 255), // Background color set to white
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.71,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/TC-front.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Color.fromARGB(255, 249, 251,
                      255), // Ensure this matches the background color
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Boost your productivity with\n',
                              style: TextStyle(
                                fontSize: 22, // Adjusted text size
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: 'Task Crafter',
                              style: TextStyle(
                                fontSize: 29, // Adjusted text size
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(
                                    255, 247, 82, 137), // Pink color
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15), // Add space between texts
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Signup1()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(255, 247, 82, 137)
                                .withOpacity(0.9), // Transparent pink color
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.3),
                                spreadRadius: 3,
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(15), // Decreased padding
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 24, // Decreased icon size
                          ),
                        ),
                      ),
                      SizedBox(height: 65), // Add some space at the bottom
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Powered by',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5),
                Image.asset(
                  'assets/images/milestone.logo.jpg', // Corrected the image path
                  width: 55, // Adjust the width as needed
                  height: 55, // Adjust the height as needed
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
