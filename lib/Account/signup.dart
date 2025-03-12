import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String selectedRole = 'user'; // ค่าเริ่มต้นของ role
  bool isLoading = false; // เพิ่มตัวแปร Loading

  Future<void> register() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("รหัสผ่านไม่ตรงกัน!")),
      );
      return;
    }

    setState(() {
      isLoading = true; // แสดง Loading
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid, // เพิ่ม UID ลงไปใน Firestore
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'role': selectedRole, // กำหนด role
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("สมัครสมาชิกสำเร็จ!")),
        );

        Navigator.pop(context); // กลับไปหน้า Login
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาด: ${e.toString()}")),
      );
    } finally {
      setState(() {
        isLoading = false; // ซ่อน Loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_add, size: 80, color: Colors.green),
              SizedBox(height: 32),
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                    labelText: 'Username', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                    labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder()),
                obscureText: true,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(
                      value: 'technician', child: Text('Technician'))
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
                decoration: InputDecoration(
                    border: OutlineInputBorder(), labelText: 'Select Role'),
              ),
              SizedBox(height: 24),
              isLoading
                  ? CircularProgressIndicator() // แสดง Loading เมื่อสมัคร
                  : ElevatedButton(
                      onPressed: register,
                      child: Text('Register'),
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50)),
                    ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
