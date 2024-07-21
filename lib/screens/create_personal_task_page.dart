// ignore_for_file: use_key_in_widget_constructors, library_private_types_in_public_api, use_build_context_synchronously, prefer_const_constructors, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreatePersonalTaskPage extends StatefulWidget {
  @override
  _CreatePersonalTaskPageState createState() => _CreatePersonalTaskPageState();
}

class _CreatePersonalTaskPageState extends State<CreatePersonalTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _pickDeadline(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDeadline) {
      setState(() {
        _selectedDeadline = pickedDate;
      });
    }
  }

  void _createTask() async {
    String uid = _auth.currentUser?.uid ?? '';

    if (_titleController.text.isEmpty || _selectedDeadline == null) {
      // Show an error message if title or deadline is not set
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and select a deadline.')),
      );
      return;
    }

    CollectionReference tasks = FirebaseFirestore.instance.collection('tasks');

    await tasks.add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'deadline': _selectedDeadline,
      'createdBy': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isCompleted': false, // Ensure this line is included
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Personal Task',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Deadline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _selectedDeadline == null
                    ? 'No date chosen!'
                    : DateFormat.yMMMMd().format(_selectedDeadline!),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDeadline(context),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _createTask,
                child: Text('Create task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 234, 193, 241),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
