import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestTankChangePage extends StatefulWidget {
  final String tankId; // รับค่า tank_id ที่ส่งมาจาก FormTechCheckPage

  RequestTankChangePage({required this.tankId});

  @override
  _RequestTankChangePageState createState() => _RequestTankChangePageState();
}

class _RequestTankChangePageState extends State<RequestTankChangePage> {
  final TextEditingController reasonController = TextEditingController();
  bool isLoading = true;
  bool isSubmitting = false;
  Map<String, dynamic>? tankData;

  @override
  void initState() {
    super.initState();
    fetchTankData();
  }

  /// ดึงข้อมูลถังดับเพลิงจาก Firestore โดยใช้ tank_id
  Future<void> fetchTankData() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('firetank_Collection')
          .where('tank_id', isEqualTo: widget.tankId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          tankData = snapshot.docs.first.data();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่พบข้อมูลถังดับเพลิง')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ร้องขอเปลี่ยนถัง')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : tankData == null
                ? Center(child: Text('ไม่พบข้อมูลถังดับเพลิง'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tank ID: ${widget.tankId}',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ประเภท: ${tankData!['type']}'),
                              Text('อาคาร: ${tankData!['building']}'),
                              Text('ชั้น: ${tankData!['floor']}'),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text('เหตุผลในการเปลี่ยน',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      TextField(
                        controller: reasonController,
                        decoration:
                            InputDecoration(hintText: 'เช่น ถังรั่ว, หมดอายุ'),
                      ),
                      SizedBox(height: 24),
                      isSubmitting
                          ? Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: () {
                                // ฟังก์ชันส่งคำขอเปลี่ยนถัง
                              },
                              child: Text('ส่งคำขอ'),
                            ),
                    ],
                  ),
      ),
    );
  }
}
