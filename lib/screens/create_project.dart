import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_crafter_app/constants/colors.dart';
import 'package:task_crafter_app/screens/dashboard.dart';
import 'package:task_crafter_app/screens/selectmemberpage.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({Key? key}) : super(key: key);

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDeadline;
  List<Map<String, dynamic>> selectedMembers =
      []; // Track selected members with roles

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xFFF1F4F8),
      appBar: AppBar(
        backgroundColor: Color(0xFFF1F4F8),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back to previous screen
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: he * 0.03,
              right: he * 0.03,
              bottom: he * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: he * 0),
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Create',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.normal,
                      color: Color.fromARGB(255, 247, 82, 137).withOpacity(1),
                    ),
                  ),
                ),
                Text(
                  'New Project',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.normal,
                    color: Color.fromARGB(255, 247, 82, 137).withOpacity(1),
                  ),
                ),
                SizedBox(height: he * 0.03),
                _buildNewProject(context),
                SizedBox(height: he * 0.03),
                _buildDeadlinePicker(context),
                SizedBox(height: he * 0.03),
                _buildAddMembers(context), // Display the "Add members" section
                SizedBox(height: he * 0.05),
                _buildCreateProjectButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewProject(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Title',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Enter title',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Description',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
          SizedBox(height: 10),
          TextFormField(
            controller: _descController,
            decoration: InputDecoration(
              hintText: 'Enter description',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMembers(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SelectMembersPage(selectedMembers: selectedMembers),
          ),
        ).then((selectedMembers) {
          if (selectedMembers != null) {
            setState(() {
              this.selectedMembers = selectedMembers;
            });
          }
        });
      },
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add members',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/img_image_3.png',
                  height: 45,
                  width: 45,
                  fit: BoxFit.cover,
                ),
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 35,
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Selected Members: ${selectedMembers.length}',
              style: TextStyle(fontSize: 16),
            ),
            // Display the selected members and their roles
            for (var member in selectedMembers)
              Text(
                '${member['firstName']} ${member['lastName']}: ${member['role']}',
                style: TextStyle(fontSize: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlinePicker(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deadline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (picked != null) {
                setState(() {
                  _selectedDeadline = picked;
                });
              }
            },
            child: Text(
              _selectedDeadline == null
                  ? 'Select Deadline'
                  : 'Deadline: ${_selectedDeadline!.toLocal()}'.split(' ')[0],
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 247, 82, 137),
              ),
            ),
          ),
          SizedBox(height: 10),
          if (_selectedDeadline != null)
            Text(
              'Selected Deadline: ${_selectedDeadline!.toLocal()}'
                  .split(' ')[0],
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateProjectButton(BuildContext context) {
    return Center(
      child: Container(
        height: 40,
        width: 150,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 247, 82, 137).withOpacity(1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: ElevatedButton(
          onPressed: _createProject,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color.fromARGB(255, 247, 82, 137).withOpacity(1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            'Create Project',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createProject() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      // Handle user not signed in
      return;
    }

    try {
      DocumentReference projectRef =
          await _firestore.collection('projects').add({
        'userId': user.uid,
        'title': _titleController.text,
        'desc': _descController.text,
        'bgColor': kBlue.value,
        'textColor': Colors.black.value,
        'deadline': _selectedDeadline?.millisecondsSinceEpoch,
        'members':
            selectedMembers, // Add selected members with roles to Firestore
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Get the generated project ID
      String projectId = projectRef.id;
      await projectRef.update({'projectId': projectId});

      // Optionally navigate to a different screen or show a success message
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              dashboard(), // Navigate to home page after project creation
        ),
      );

      // Clear input fields and reset state
      _titleController.clear();
      _descController.clear();
      setState(() {
        _selectedDeadline = null;
        selectedMembers.clear();
      });
    } catch (e) {
      print('Error creating project: $e');
      // Handle error
    }
  }
}
