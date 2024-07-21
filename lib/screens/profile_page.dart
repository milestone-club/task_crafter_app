// ignore_for_file: unused_local_variable, use_super_parameters, avoid_print, use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:task_crafter_app/screens/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String firstName = userDoc.get('firstName');
          String lastName = userDoc.get('lastName');
          String email = userDoc.get('email');

          // Update text controllers with fetched data
          firstNameController.text = firstName;
          lastNameController.text = lastName;
          emailController.text = email;

          if (userDoc.get('profileImageUrl') != null) {
            String profileImageUrl = userDoc.get('profileImageUrl');
            setState(() {
              _profileImageUrl = profileImageUrl;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImageUrl = pickedFile.path;
      });
    }
  }

  Future<void> uploadProfileImage() async {
    if (_profileImageUrl != null) {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          final storageRef = FirebaseStorage.instanceFor(
                  bucket: 'gs://taskcrafter-a7c64.appspot.com')
              .ref()
              .child('profile_images')
              .child(user.uid);
          final uploadTask = storageRef.putFile(File(_profileImageUrl!));
          final snapshot = await uploadTask.whenComplete(() {});
          final downloadUrl = await snapshot.ref.getDownloadURL();

          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(user.uid)
              .update({'profileImageUrl': downloadUrl});
        }
      } catch (e) {
        print('Error uploading profile image: $e');
      }
    }
  }

  void saveProfile() async {
    String firstName = firstNameController.text;
    String lastName = lastNameController.text;
    String userEmail = emailController.text;

    if (firstName.isNotEmpty && lastName.isNotEmpty && userEmail.isNotEmpty) {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await FirebaseFirestore.instance
              .collection('profiles')
              .doc(user.uid)
              .set({
            'firstName': firstName,
            'lastName': lastName,
            'email': userEmail,
          });

          await uploadProfileImage();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully!')),
          );
        }
      } catch (e) {
        print('Error saving profile data: $e');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter first name, last name, and email.')),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var screenWidth = screenSize.width;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : AssetImage('assets/images/img_group_1.png')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: pickImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: saveProfile,
                    child: const Text('Save'),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton(
                    onPressed: signOut,
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
