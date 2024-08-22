import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectMembersPage extends StatefulWidget {
  final List<Map<String, dynamic>> selectedMembers;

  const SelectMembersPage({required this.selectedMembers, Key? key})
      : super(key: key);

  @override
  State<SelectMembersPage> createState() => _SelectMembersPageState();
}

class _SelectMembersPageState extends State<SelectMembersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> selectedMembers = [];
  String searchQuery = '';
  String selectedRole = 'Member';

  final List<String> roles = ['Member', 'Project Manager', 'Team Lead'];

  @override
  void initState() {
    super.initState();
    selectedMembers = widget.selectedMembers;
  }

  Future<void> _selectMember(String userId) async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(userId).get();
    Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;

    setState(() {
      selectedMembers.add({
        'id': userId,
        'firstName': userData['fName'],
        'lastName': userData['lastName'],
        'role': selectedRole,
      });
    });
  }

  void _removeMember(String userId) {
    setState(() {
      selectedMembers.removeWhere((member) => member['id'] == userId);
    });
  }

  Future<List<DocumentSnapshot>> _searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('fName', isGreaterThanOrEqualTo: query)
        .where('fName', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Members'),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for members',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      searchQuery = _searchController.text;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectedMembers.length,
                      itemBuilder: (context, index) {
                        final member = selectedMembers[index];
                        return ListTile(
                          title: Text(
                              '${member['firstName']} ${member['lastName']}'),
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
                  Divider(),
                  Expanded(
                    flex: 2,
                    child: FutureBuilder<List<DocumentSnapshot>>(
                      future: _searchUsers(searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('No members found'));
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot userDoc = snapshot.data![index];
                            String userId = userDoc.id;
                            String firstName = userDoc['fName'];
                            String lastName = userDoc['lastName'];

                            return ListTile(
                              title: Text('$firstName $lastName'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  DropdownButton<String>(
                                    value: selectedRole,
                                    items: roles.map((String role) {
                                      return DropdownMenuItem<String>(
                                        value: role,
                                        child: Text(role),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedRole = newValue!;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () async {
                                      await _selectMember(userId);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, selectedMembers);
        },
        child: Icon(Icons.check),
      ),
    );
  }
}
