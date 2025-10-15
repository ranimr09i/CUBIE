import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_scaffold.dart';
import '../routes.dart';
import '../app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return AppScaffold(
      title: 'الإعدادات',
      showLogo: true,
      centerTitle: false,
      body: Column(
        children: [
          if (appState.currentUserName != null) ...[
            Card(
              margin: const EdgeInsets.all(12),
              color: const Color(0xff4ab0d1),
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.white),
                title: Text(
                  'مرحباً, ${appState.currentUserName}!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'ID: ${appState.currentUserID}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ],

          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.person, color: Color(0xff4ab0d1)),
                  title: const Text('تعديل ملف المشرف', style: TextStyle(color: Color(0xff254865))),
                  onTap: () => Navigator.pushNamed(context, Routes.editAdmin),
                ),
                ListTile(
                  leading: const Icon(Icons.child_care, color: Color(0xff4ab0d1)),
                  title: const Text('تحرير الأطفال', style: TextStyle(color: Color(0xff254865))),
                  onTap: () => Navigator.pushNamed(context, Routes.editChildren),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    appState.logout();
                    Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.adminLogin,
                            (route) => false
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}