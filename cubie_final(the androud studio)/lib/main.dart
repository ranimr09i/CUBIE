import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes.dart';
import 'app_state.dart';
import 'services/bluetooth_manager.dart';
void main() {
  runApp(
    // 2. التغيير إلى MultiProvider لإتاحة أكثر من حالة
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => BluetoothManager()), // <-- 3. إضافة مدير البلوتوث هنا
      ],
      child: const CubieUIApp(),
    ),
  );
}



class CubieUIApp extends StatelessWidget {
  const CubieUIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CUBIE UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xff254865),
        scaffoldBackgroundColor: const Color(0xffe6eceb),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff224562),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Color(0xff8dd6bb)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff4ab0d1),
            foregroundColor: const Color(0xff254865),
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xff4ab0d1),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: Routes.adminLogin,
      routes: Routes.getRoutes(),
    );
  }
}