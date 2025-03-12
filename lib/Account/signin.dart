import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'signup.dart';

class LoginPage extends StatefulWidget {
  final Function(BuildContext, User) onLoginSuccess;

  const LoginPage({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // โหลดข้อมูลที่เคยบันทึกไว้
  }

  /// ✅ โหลดอีเมลและรหัสผ่านที่เคยบันทึกไว้
  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('saved_email') ?? '';
      _passwordController.text = prefs.getString('saved_password') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  /// ✅ บันทึกอีเมลและรหัสผ่านลง `SharedPreferences`
  Future<void> _saveCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text);
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  /// ✅ ฟังก์ชันล็อกอิน
  Future<void> _login() async {
    try {
      await _auth.setPersistence(Persistence.LOCAL); // จดจำการล็อกอินแบบถาวร

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          String userStatus = userDoc['status'] ?? 'Inactive';
          if (userStatus == 'Inactive') {
            await _auth.signOut();
            setState(() {
              errorMessage = 'บัญชีของคุณถูกปิดใช้งาน กรุณาติดต่อผู้ดูแลระบบ';
            });
            return;
          }

          // ✅ อัปเดต last_login ใน Firestore
          await _firestore.collection('users').doc(user.uid).update({
            'last_login': FieldValue.serverTimestamp(),
          });

          // ✅ บันทึก login_history
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('login_history')
              .add({
            'timestamp': FieldValue.serverTimestamp(),
            'device': 'web',
          });

          // ✅ บันทึกอีเมลและรหัสผ่าน
          await _saveCredentials();

          // ✅ นำทางไปยังหน้า Dashboard ตามสิทธิ์ของผู้ใช้
          widget.onLoginSuccess(context, user);
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'เข้าสู่ระบบล้มเหลว: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('เข้าสู่ระบบ'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.blue),
            SizedBox(height: 32),

            // ✅ ช่องกรอกอีเมล
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // ✅ ช่องกรอกรหัสผ่าน
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            // ✅ Checkbox "จำรหัสผ่าน"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                    ),
                    Text("จำรหัสผ่าน"),
                  ],
                ),
              ],
            ),

            SizedBox(height: 10),

            // ✅ ปุ่มล็อคอิน
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),

            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),

            // ✅ ลิงก์ไปหน้าสมัครสมาชิก
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: Text('สร้างบัญชีผู้ใช้'),
            ),
          ],
        ),
      ),
    );
  }
}
