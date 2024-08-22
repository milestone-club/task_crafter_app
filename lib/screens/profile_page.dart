import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
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
  File? _image;
  String profileImageUrl = '';

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
          profileImageUrl = userDoc.get('profileImageUrl');

          // Update text controllers with fetched data
          firstNameController.text = firstName;
          lastNameController.text = lastName;
          emailController.text = email;
          setState(() {});
        }
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  Future<void> saveProfile() async {
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
            'profileImageUrl': profileImageUrl,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile saved successfully!')),
          );

          // Fetch updated profile data
          await fetchProfileData();
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

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage();
    }
  }

  Future<void> _uploadImage() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && _image != null) {
        String fileName = path.basename(_image!.path);
        Reference storageRef = FirebaseStorage.instanceFor(
                bucket: 'gs://taskcrafter-a7c64.appspot.com')
            .ref()
            .child('profile_images/${user.uid}/$fileName');
        UploadTask uploadTask = storageRef.putFile(_image!);

        TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
        profileImageUrl = await taskSnapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('profiles')
            .doc(user.uid)
            .update({'profileImageUrl': profileImageUrl});

        // Update state with new profile image URL
        setState(() {});
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      // Updated background color
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
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage('assets/images/img_group_1.png')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 247, 82, 137),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          firstNameController.text,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -8,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt,
                            color: Color.fromARGB(255, 255, 255, 255)),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: TextFormField(
                    controller: firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.pink), // Pink border
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: TextFormField(
                    controller: lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.pink), // Pink border
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.pink), // Pink border
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ElevatedButton(
                      onPressed: saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 247, 82, 137)
                            .withOpacity(1), // Pink background
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                            color: Colors.white), // Change text color to white
                      ),
                    ),
                  ),
                ),
                Center(
                  child: OutlinedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Color.fromARGB(255, 247, 82, 137).withOpacity(1),
                      ), // Pink border
                    ),
                    child: const Text(
                      'Logout',
                      style:
                          TextStyle(color: Color.fromARGB(255, 247, 82, 137)),
                    ),
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
