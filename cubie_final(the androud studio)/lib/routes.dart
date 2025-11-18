
import 'package:flutter/material.dart';
import 'screens/admin_login.dart';
import 'screens/admin_signup.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
import 'screens/edit_admin_profile.dart';
import 'screens/edit_children.dart';
import 'screens/edit_child.dart';
import 'screens/add_child.dart';
import 'screens/connect_cube.dart'; // (تم استيراد الملف الصحيح)
import 'screens/history_page.dart';
import 'screens/create_story.dart';
import 'screens/story_progress.dart'; // (تم استيراد الملف الصحيح)
import 'screens/error_page.dart';

class Routes {
  static const adminLogin = '/';
  static const adminSignup = '/signup';
  static const home = '/home';
  static const settings = '/settings';
  static const editAdmin = '/edit-admin';
  static const editChildren = '/edit-children';
  static const editChild = '/edit-child';
  static const addChild = '/add-child';
  static const connectCube = '/connect-cube';
  static const history = '/history';
  static const createStory = '/create-story';
  static const storyProgress = '/story-progress';
  static const error = '/error';

  static Map<String, WidgetBuilder> getRoutes() => {
    adminLogin: (_) => const AdminLoginScreen(),
    adminSignup: (_) => const AdminSignupScreen(),
    home: (_) => const HomePage(),
    settings: (_) => const SettingsPage(),
    editAdmin: (_) => const EditAdminProfilePage(),
    editChildren: (_) => const EditChildrenPage(),
    editChild: (_) => const EditChildPage(),
    addChild: (_) => const AddChildPage(),

    // !! --- (التعديل هنا) --- !!
    // (تم تغيير الأسماء لتطابق أسماء الكلاسات الجديدة)
    connectCube: (_) => const ConnectCubeScreen(),
    history: (_) => const HistoryPage(),
    createStory: (_) => const CreateStoryPage(),
    storyProgress: (_) => const StoryProgressScreen(), // (كان الاسم خطأ)
    // !! --- (نهاية التعديل) --- !!

    error: (_) => const ErrorPage(),
  };
}
