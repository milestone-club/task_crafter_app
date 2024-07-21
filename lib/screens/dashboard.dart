// ignore_for_file: camel_case_types, use_super_parameters, library_private_types_in_public_api, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_crafter_app/screens/calendar.dart';
import 'package:task_crafter_app/screens/create_task.dart';
import 'package:task_crafter_app/screens/messaging.dart';
import 'package:task_crafter_app/screens/openpage.dart';
import 'package:task_crafter_app/screens/profile_page.dart';

class dashboard extends StatefulWidget {
  const dashboard({Key? key}) : super(key: key);
  @override
  _dashboardState createState() => _dashboardState();
}

class _dashboardState extends State<dashboard> {
  String userName = '';
  String profileImageUrl = '';
  final List<Widget> _pages = [
    const OpenPage(),
    const MessagePage(),
    const new_task(),
    const CalendarPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    getUserProfileData(); // Call method to get user's profile data on widget initialization
  }

  Future<void> getUserProfileData() async {
    try {
      // Get current user from FirebaseAuth
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Get user document from Firestore using the UID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          // Retrieve the first name and profile image URL from the document
          String firstName = userDoc.get('firstName');
          String profileImage = userDoc.get('profileImageUrl');
          setState(() {
            userName =
                firstName; // Update the userName variable with the first name
            profileImageUrl =
                profileImage; // Update the profileImageUrl variable with the image URL
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  int activeIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.black,
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
                backgroundColor: Colors.black,
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
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            height: 45,
            width: 45,
            margin: const EdgeInsets.only(left: 15),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: profileImageUrl.isNotEmpty
                  ? Image.network(profileImageUrl, fit: BoxFit.cover)
                  : Image.asset('assets/images/img_group_1.png',
                      fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Hi, $userName',
            style: const TextStyle(
                color: Colors.black, fontSize: 26, fontWeight: FontWeight.bold),
          )
        ],
      ),
      actions: const [
        Icon(
          Icons.more_vert,
          color: Colors.black,
          size: 40,
        ),
      ],
    );
  }
}
