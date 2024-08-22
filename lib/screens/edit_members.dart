import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_crafter_app/screens/selectmemberpage.dart';

class EditMembersPage extends StatefulWidget {
  final String projectId;
  final List<dynamic> members;

  const EditMembersPage({
    Key? key,
    required this.projectId,
    required this.members,
  }) : super(key: key);

  @override
  _EditMembersPageState createState() => _EditMembersPageState();
}

class _EditMembersPageState extends State<EditMembersPage> {
  late List<dynamic> members;
  List<Map<String, dynamic>> selectedMembers = [];

  @override
  void initState() {
    super.initState();
    members = widget.members;
  }

  void _addMembers(List<Map<String, dynamic>> newMembers) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update({
        'members': FieldValue.arrayUnion(newMembers),
      });
      setState(() {
        members.addAll(newMembers);
      });
    } catch (e) {
      print('Error adding members: $e');
    }
  }

  void _removeMember(String memberId) async {
    try {
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .update({
        'members': FieldValue.arrayRemove([
          {'id': memberId}
        ]),
      });
      setState(() {
        members.removeWhere((member) => member['id'] == memberId);
      });
    } catch (e) {
      print('Error removing member: $e');
    }
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
          if (selectedMembers != null && selectedMembers.isNotEmpty) {
            _addMembers(selectedMembers);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Members'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddMembers(context),
            SizedBox(height: 20),
            Text('Members:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    title: Text('${member['firstName']} ${member['lastName']}'),
                    subtitle: Text(member['role']),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle),
                      onPressed: () {
                        _removeMember(member['id']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
