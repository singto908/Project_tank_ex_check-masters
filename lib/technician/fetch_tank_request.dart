import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianRequestsScreen extends StatefulWidget {
  @override
  _TechnicianRequestsScreenState createState() =>
      _TechnicianRequestsScreenState();
}

class _TechnicianRequestsScreenState extends State<TechnicianRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('คำขอเปลี่ยนถัง', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('technician_chang_requests')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          var requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return Center(
              child: Text(
                'ไม่มีคำร้องขอเปลี่ยนถัง',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    'รหัสถัง: ${request['tank_id']}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.orange),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text('อาคาร: ${request['building']}',
                          style: TextStyle(fontSize: 16)),
                      Text('ชั้น: ${request['floor']}',
                          style: TextStyle(fontSize: 16)),
                      Text('สถานะ: ${request['status']}',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.orange),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TechnicianRequestDetailScreen(
                            requestId: request.id),
                      ),
                    );
                    setState(() {}); // รีเฟรชหน้าหลังจากกลับจากหน้ารายละเอียด
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TechnicianRequestDetailScreen extends StatefulWidget {
  final String requestId;

  TechnicianRequestDetailScreen({required this.requestId});

  @override
  _TechnicianRequestDetailScreenState createState() =>
      _TechnicianRequestDetailScreenState();
}

class _TechnicianRequestDetailScreenState
    extends State<TechnicianRequestDetailScreen> {
  bool isAccepted = false;
  bool isProcessing = false;
  bool isCompleted = false;
  Map<String, dynamic>? requestData;

  @override
  void initState() {
    super.initState();
    _fetchRequestData();
  }

  void _fetchRequestData() async {
    var doc = await FirebaseFirestore.instance
        .collection('technician_chang_requests')
        .doc(widget.requestId)
        .get();
    if (doc.exists) {
      setState(() {
        requestData = doc.data();
        isAccepted = requestData!['status'] == 'running';
        isCompleted = requestData!['status'] == 'completed';
      });
    }
  }

  void _handleAcceptPress() async {
    await FirebaseFirestore.instance
        .collection('technician_chang_requests')
        .doc(widget.requestId)
        .update({'status': 'running'});
    setState(() {
      isAccepted = true;
      isProcessing = true;
    });
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        isProcessing = false;
        isCompleted = true;
      });
    });
  }

  void _handleCompletePress() async {
    await FirebaseFirestore.instance
        .collection('record_update')
        .add(requestData!);
    await FirebaseFirestore.instance
        .collection('technician_chang_requests')
        .doc(widget.requestId)
        .delete();
    await FirebaseFirestore.instance
        .collection('firetank_Collection')
        .where('tank_id', isEqualTo: requestData!['tank_id'])
        .get()
        .then((querySnapshot) {
      if (querySnapshot.docs.isEmpty) {
        print(
            'Error: No document found with tank_id = ${requestData!['tank_id']}');
      } else {
        for (var doc in querySnapshot.docs) {
          doc.reference.update({
            'status': 'ตรวจสอบแล้ว',
            'status_technician': 'ตรวจสอบแล้ว',
            'type': requestData!['new_tank_type'] ?? 'ไม่ระบุ'
          });
        }
      }
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดคำขอเปลี่ยนถัง',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: requestData == null
          ? Center(child: CircularProgressIndicator(color: Colors.orange))
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('รหัสถัง: ${requestData!['tank_id']}',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                      Divider(color: Colors.orange, thickness: 1.5),
                      SizedBox(height: 8),
                      _buildDetailRow(
                          Icons.business, 'อาคาร', requestData!['building']),
                      _buildDetailRow(
                          Icons.layers, 'ชั้น', requestData!['floor']),
                      _buildDetailRow(Icons.warning, 'เหตุผล',
                          requestData!['reason'] ?? 'ไม่มีเหตุผล'),
                      _buildDetailRow(
                          Icons.verified, 'สถานะ', requestData!['status']),
                      _buildDetailRow(Icons.category, 'ถังเก่าประเภท',
                          requestData!['current_tank_type']),
                      _buildDetailRow(Icons.category, 'ถังใหม่ประเภท',
                          requestData!['new_tank_type']),
                      Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: isAccepted
                              ? (isProcessing ? null : _handleCompletePress)
                              : _handleAcceptPress,
                          child: isAccepted
                              ? (isProcessing
                                  ? CircularProgressIndicator(
                                      color: Colors.white)
                                  : Text('เสร็จสิ้น',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18)))
                              : Text('ยอมรับ',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18)),
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

Widget _buildDetailRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, color: Colors.orange, size: 22),
        SizedBox(width: 10),
        Text('$label: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 16))),
      ],
    ),
  );
}
