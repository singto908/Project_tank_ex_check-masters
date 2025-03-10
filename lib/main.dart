import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// นำเข้าหน้าต่าง ๆ ที่ต้องใช้
import 'admin/inspection_history.dart';
import 'admin/dashboard.dart';
import 'admin/fire_tank_status.dart';
import 'user/form_check.dart';
import 'admin/fire_tank_management.dart';
import 'admin/buildings_management.dart';
import 'admin/fire_tank_types.dart';
import 'admin/admin_damage.dart';
import 'technician/form_tech.dart';
import 'technician/dashboardTech.dart';
import 'Account/signin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ใช้ PathUrlStrategy เพื่อให้ URL ไม่มีเครื่องหมาย #
  setUrlStrategy(PathUrlStrategy());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firecheck System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      onGenerateRoute: _generateRoute,
    );
  }
}

Route<dynamic> _generateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '/');

  switch (uri.path) {
    case '/login':
      return MaterialPageRoute(
          builder: (context) => LoginPage(onLoginSuccess: _handleLoginSuccess));

    case '/user':
      final tankId = uri.queryParameters['tankId'];
      return _handleTankIdRoute(tankId, (id) => FormCheckPage(tankId: id));

    case '/Tech':
      final tankId = uri.queryParameters['tankId'];
      return _handleTankIdRoute(tankId, (id) => FormTechCheckPage(tankId: id));

    case '/dashboardTech':
      return MaterialPageRoute(builder: (context) => DashboardTechPage());

    case '/admin':
      return MaterialPageRoute(builder: (context) => DashboardPage());

    case '/firetankstatus':
      return MaterialPageRoute(builder: (context) => FireTankStatusPage());

    case '/inspectionhistory':
      return MaterialPageRoute(builder: (context) => InspectionHistoryPage());

    case '/fire_tank_management':
      return MaterialPageRoute(builder: (context) => FireTankManagementPage());

    case '/BuildingManagement':
      return MaterialPageRoute(
          builder: (context) => BuildingManagementScreen());

    case '/FireTankTypes':
      return MaterialPageRoute(builder: (context) => FireTankTypes());

    case '/FireTankStatusPage':
      return MaterialPageRoute(builder: (context) => FireTankStatusPage());

    case '/AdminReport':
      return MaterialPageRoute(builder: (context) => AdminReportPage());

    default:
      return MaterialPageRoute(builder: (context) => const DashboardPage());
  }
}

Route<dynamic> _handleTankIdRoute(
    String? tankId, Widget Function(String) builder) {
  if (tankId == null) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('ข้อผิดพลาด')),
        body: const Center(child: Text('Tank ID ไม่ถูกต้องหรือไม่ได้ระบุ.')),
      ),
    );
  }
  return MaterialPageRoute(builder: (context) => builder(tankId));
}

void _handleLoginSuccess(BuildContext context, User user) async {
  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (userDoc.exists) {
    final role = userDoc.data()?['role'] ?? '';
    if (role == 'technician') {
      Navigator.pushReplacementNamed(context, '/dashboardTech');
    } else if (role == 'admin') {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }
}
