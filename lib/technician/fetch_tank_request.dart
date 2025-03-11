import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianRequestsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('คำขอของช่างเทคนิค', style: TextStyle(color: Colors.white)),
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TechnicianRequestDetailScreen(request: request),
                      ),
                    );
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

class TechnicianRequestDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot request;

  TechnicianRequestDetailScreen({required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดคำขอ', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('รหัสถัง: ${request['tank_id']}',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
                Divider(color: Colors.orange, thickness: 1.5),
                SizedBox(height: 8),
                _buildDetailRow(Icons.business, 'อาคาร', request['building']),
                _buildDetailRow(Icons.layers, 'ชั้น', request['floor']),
                _buildDetailRow(Icons.warning, 'เหตุผล',
                    request['reason'] ?? 'ไม่มีเหตุผล'),
                _buildDetailRow(Icons.verified, 'สถานะ', request['status']),
                _buildDetailRow(Icons.category, 'ประเภท', request['type']),
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
                    onPressed: () {},
                    child: Text('เสร็จสิ้น',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}
