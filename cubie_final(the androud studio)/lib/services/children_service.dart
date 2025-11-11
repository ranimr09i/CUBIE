// // import 'api_service.dart';
// //
// // class ChildrenService {
// //   static Future<Map<String, dynamic>> getChildren(int userID) async {
// //     return await ApiService.getRequest('/children/list/$userID');
// //   }
// //
// //   static Future<Map<String, dynamic>> addChild(
// //       int userID, String name, int age, String gender
// //       ) async {
// //     return await ApiService.postRequest('/children/add/', {
// //       'userID': userID.toString(),
// //       'name': name,
// //       'age': age.toString(),
// //       'gender': gender == 'ذكر' ? 'Male' : 'Female',
// //     });
// //   }
// //
// //   static Future<Map<String, dynamic>> editChild(
// //       int childID, String name, int age, String gender
// //       ) async {
// //     return await ApiService.putRequest('/children/edit/$childID', {
// //       'name': name,
// //       'age': age.toString(),
// //       'gender': gender == 'ذكر' ? 'Male' : 'Female',
// //     });
// //   }
// //
// //   static Future<Map<String, dynamic>> deleteChild(int childID) async {
// //     return await ApiService.postRequest('/children/delete/$childID', {});
// //   }
// //
// //   static Future<Map<String, dynamic>> selectChild(int childID, int userID) async {
// //     return await ApiService.getRequest('/children/select/$childID?userID=$userID');
// //   }
// // }
//
// import 'api_service.dart';
//
// class ChildrenService {
//   static Future<Map<String, dynamic>> getChildren(int userID) async {
//     return await ApiService.getRequest('/children/list/$userID');
//   }
//
//   // (1) تم إضافة String grade هنا
//   static Future<Map<String, dynamic>> addChild(
//       int userID, String name, int age, String gender, String grade
//       ) async {
//     return await ApiService.postRequest('/children/add/', {
//       'userID': userID.toString(),
//       'name': name,
//       'age': age.toString(),
//       'gender': gender == 'ذكر' ? 'Male' : 'Female',
//       'grade': grade, // (2) تم إرسال القريد
//     });
//   }
//
//   // (3) تم إضافة String grade هنا
//   static Future<Map<String, dynamic>> editChild(
//       int childID, String name, int age, String gender, String grade
//       ) async {
//     return await ApiService.putRequest('/children/edit/$childID', {
//       'name': name,
//       'age': age.toString(),
//       'gender': gender == 'ذكر' ? 'Male' : 'Female',
//       'grade': grade, // (4) تم إرسال القريد
//     });
//   }
//
//   static Future<Map<String, dynamic>> deleteChild(int childID) async {
//     return await ApiService.postRequest('/children/delete/$childID', {});
//   }
//
//   static Future<Map<String, dynamic>> selectChild(int childID, int userID) async {
//     return await ApiService.getRequest('/children/select/$childID?userID=$userID');
//   }
// }
import 'api_service.dart';

class ChildrenService {
  static Future<Map<String, dynamic>> getChildren(int userID) async {
    // GET requests remain the same
    return await ApiService.getRequest('/children/list/$userID');
  }

  static Future<Map<String, dynamic>> addChild(
      int userID, String name, int age, String gender, String grade
      ) async {

    // !! --- (التعديل هنا) --- !!
    // (استخدام postFormRequest بدلاً من postRequest)
    return await ApiService.postFormRequest('/children/add/', {
      'userID': userID.toString(),
      'name': name,
      'age': age.toString(),
      'gender': gender == 'ذكر' ? 'Male' : 'Female',
      'grade': grade,
    });
    // !! --- (نهاية التعديل) --- !!
  }

  static Future<Map<String, dynamic>> editChild(
      int childID, String name, int age, String gender, String grade
      ) async {

    // !! --- (التعديل هنا) --- !!
    // (استخدام postFormRequest بدلاً من putRequest لأن الباك اند يتوقع فورم)
    // (ملاحظة: الباك اند عندك غالباً يستخدم POST للـ edit وليس PUT)
    return await ApiService.postFormRequest('/children/edit/$childID', {
      'name': name,
      'age': age.toString(),
      'gender': gender == 'ذكر' ? 'Male' : 'Female',
      'grade': grade,
    });
    // !! --- (نهاية التعديل) --- !!
  }

  static Future<Map<String, dynamic>> deleteChild(int childID) async {
    // !! --- (التعديل هنا) --- !!
    // (استخدام postFormRequest بدلاً من postRequest)
    return await ApiService.postFormRequest('/children/delete/$childID', {});
    // !! --- (نهاية التعديل) --- !!
  }

  static Future<Map<String, dynamic>> selectChild(int childID, int userID) async {
    // GET requests remain the same
    return await ApiService.getRequest('/children/select/$childID?userID=$userID');
  }
}