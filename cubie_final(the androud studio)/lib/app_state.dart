import 'package:flutter/foundation.dart';

class AppState with ChangeNotifier {
  int? _currentUserID;
  String? _currentUserName;
  String? _currentUserEmail; // (1) إضافة متغير الإيميل

  int? _selectedChildID;
  Map<String, dynamic>? _currentChild;
  List<Map<String, dynamic>> _children = [];

  int? _currentStoryID;
  String? _currentStoryTitle;

  int? get currentUserID => _currentUserID;
  String? get currentUserName => _currentUserName;
  String? get currentUserEmail => _currentUserEmail; // (2) Getter للإيميل

  int? get selectedChildID => _selectedChildID;
  Map<String, dynamic>? get currentChild => _currentChild;
  List<Map<String, dynamic>> get children => _children;

  int? get currentStoryID => _currentStoryID;
  String? get currentStoryTitle => _currentStoryTitle;

  // (3) تحديث دالة setUser لتستقبل الإيميل
  void setUser(int userID, String userName, String userEmail) {
    _currentUserID = userID;
    _currentUserName = userName;
    _currentUserEmail = userEmail; // حفظ الإيميل
    notifyListeners();
  }

  void setSelectedChild(int childID, Map<String, dynamic> child) {
    _selectedChildID = childID;
    _currentChild = child;
    notifyListeners();
  }

  void setCurrentStory(int storyID, String title) {
    _currentStoryID = storyID;
    _currentStoryTitle = title;
    notifyListeners();
  }

  void setChildren(List<Map<String, dynamic>> children) {
    _children = children;
    notifyListeners();
  }

  void addChild(Map<String, dynamic> child) {
    _children.add(child);
    notifyListeners();
  }

  void updateChild(int childID, Map<String, dynamic> updatedChild) {
    final index = _children.indexWhere((child) => child['childID'] == childID);
    if (index != -1) {
      _children[index] = updatedChild;
      if (_selectedChildID == childID) {
        _currentChild = updatedChild;
      }
      notifyListeners();
    }
  }

  void removeChild(int childID) {
    _children.removeWhere((child) => child['childID'] == childID);
    if (_selectedChildID == childID) {
      _selectedChildID = null;
      _currentChild = null;
    }
    notifyListeners();
  }

  void clearSelectedChild() {
    _selectedChildID = null;
    _currentChild = null;
    notifyListeners();
  }

  void logout() {
    _currentUserID = null;
    _currentUserName = null;
    _currentUserEmail = null; // تصفير الإيميل
    _selectedChildID = null;
    _currentChild = null;
    _children = [];
    _currentStoryID = null;
    _currentStoryTitle = null;
    notifyListeners();
  }
}