import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'user';
  String _selectedUserId = '';

  void _editUser(String userId, String username, String email, String role) {
    setState(() {
      _selectedUserId = userId;
      _nameController.text = username;
      _emailController.text = email;
      _selectedRole = role;
    });

    // เปิด Popup Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('แก้ไขข้อมูลผู้ใช้'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'ชื่อ-นามสกุล'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'อีเมล'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              items: ['user', 'technician']
                  .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role == 'technician'
                          ? 'ช่างเทคนิค'
                          : 'ผู้ใช้ทั่วไป')))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
              decoration: InputDecoration(labelText: 'ประเภทผู้ใช้'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: _updateUser,
            child: Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _updateUser() async {
    if (_selectedUserId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_selectedUserId)
        .update({
      'username': _nameController.text,
      'email': _emailController.text,
      'role': _selectedRole,
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
    Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ลบผู้ใช้งาน"),
        content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบผู้ใช้งานนี้?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("ลบผู้ใช้สำเร็จ")),
              );
            },
            child: Text("ลบ", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('จัดการผู้ใช้งาน')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', whereIn: ['user', 'technician']).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('ไม่มีข้อมูลผู้ใช้งาน'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              String userId = users[index].id;
              String userName = user['username'] ?? 'ไม่ระบุ';
              String email = user['email'] ?? 'ไม่ระบุ';
              String role = user['role'] ?? 'ไม่ระบุ';

              Timestamp? lastLoginTimestamp = user['last_login'];
              String lastLogin = lastLoginTimestamp != null
                  ? DateFormat('yyyy-MM-dd HH:mm')
                      .format(lastLoginTimestamp.toDate())
                  : 'ไม่เคยเข้าสู่ระบบ';

              return Card(
                child: ListTile(
                  leading: Icon(
                    role == 'technician' ? Icons.engineering : Icons.person,
                    color: role == 'technician' ? Colors.blue : Colors.green,
                  ),
                  title: Text(userName,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('อีเมล: $email'),
                      Text(
                          'ประเภทผู้ใช้: ${role == "technician" ? "ช่างเทคนิค" : "ผู้ใช้ทั่วไป"}'),
                      Text('เข้าสู่ระบบล่าสุด: $lastLogin'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () =>
                            _editUser(userId, userName, email, role),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, userId),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
