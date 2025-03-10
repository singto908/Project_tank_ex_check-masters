import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late QRViewController _qrController;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _controller = CameraController(camera, ResolutionPreset.high);
    await _controller.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Scanner'),
      ),
      body: Stack(
        children: [
          _controller.value.isInitialized
              ? CameraPreview(_controller)
              : Center(child: CircularProgressIndicator()),
          Positioned(
            top: 100,
            left: 50,
            child: QRView(
              key: Key('qr_view'), // กำหนด key สำหรับ QRView
              onQRViewCreated: (controller) {
                _qrController = controller;
                _qrController.scannedDataStream.listen((scanData) {
                  // ไปยังหน้าต่าง UI ตามข้อมูลที่สแกน
                  if (scanData != null && !_isScanning) {
                    setState(() {
                      _isScanning = true;
                    });
                    Navigator.pushNamed(
                        context, '/nextPage'); // หรือหน้าอื่น ๆ ที่คุณต้องการ
                  }
                });
              },
              overlay: QrScannerOverlayShape(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _qrController.dispose();
    super.dispose();
  }
}
