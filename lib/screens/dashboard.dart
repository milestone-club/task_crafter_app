import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_crafter_app/screens/calendar.dart';
import 'package:task_crafter_app/screens/create_task.dart';
import 'package:task_crafter_app/screens/messaging.dart';
import 'package:task_crafter_app/screens/openpage.dart';
import 'package:task_crafter_app/screens/profile_page.dart';

class dashboard extends StatefulWidget {
  final int initialIndex;

  const dashboard({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _dashboardState createState() => _dashboardState();
}

class _dashboardState extends State<dashboard> {
  late int activeIndex;

  @override
  void initState() {
    super.initState();
    activeIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const OpenPage(),
    const MessagePage(),
    const new_task(),
    CalendarPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: _buildAppBar(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: _pages[activeIndex],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 10)
          ]),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: Color.fromARGB(255, 28, 27, 28),
          unselectedItemColor: Color.fromARGB(255, 28, 24, 26),
          items: const [
            BottomNavigationBarItem(
                label: 'Home',
                icon: Icon(
                  Icons.home_rounded,
                  size: 30,
                )),
            BottomNavigationBarItem(
                label: 'Messaging',
                icon: Icon(
                  Icons.message_rounded,
                  size: 30,
                )),
            BottomNavigationBarItem(
                label: 'Create Task',
                backgroundColor: Color.fromARGB(255, 247, 82, 137),
                icon: Icon(
                  Icons.add_box_rounded,
                  size: 30,
                )),
            BottomNavigationBarItem(
                label: 'Calender',
                icon: Icon(
                  Icons.calendar_month_rounded,
                  size: 30,
                )),
            BottomNavigationBarItem(
              label: 'Profile',
              icon: Icon(
                Icons.person_rounded,
                size: 30,
              ),
            ),
          ],
          onTap: (index) {
            setState(() {
              activeIndex = index;
            });
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      elevation: 0,
      title: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('profiles')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Row(
              children: [
                CircularProgressIndicator(),
                const SizedBox(width: 10),
                const Text(
                  'Hi, ...',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                )
              ],
            );
          }

          if (snapshot.hasError) {
            return const Text('Error loading data');
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Text('No profile data available');
          }

          var userDoc = snapshot.data!;
          String firstName = userDoc['firstName'];
          String profileImage = userDoc['profileImageUrl'];

          return Row(
            children: [
              Container(
                height: 45,
                width: 45,
                margin: const EdgeInsets.only(left: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: profileImage.isNotEmpty
                      ? Image.network(profileImage, fit: BoxFit.cover)
                      : Image.asset('assets/images/img_group_1.png',
                          fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Hi, $firstName',
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              )
            ],
          );
        },
      ),
      //actions: const [
      //Icon(
      //Icons.more_vert,
      //color: Colors.black,
      //size: 40,
      //),
      //],
    );
  }
}
