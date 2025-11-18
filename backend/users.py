
# from fastapi import APIRouter, HTTPException, Form
# import sqlite3
# from db import DB_NAME
# import bcrypt
 
# users_router = APIRouter()
 
# @users_router.post("/signup/")
# def signup(name: str = Form(...), email: str = Form(...), password: str = Form(...)):
#     """
#     تسجيل مستخدم جديد
#     """
#     print(f"🎯 [BACKEND] طلب تسجيل جديد: {name}, {email}")
#     # تشفير كلمة المرور
#     hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     try:
#         c.execute("INSERT INTO users (name, email, password) VALUES (?, ?, ?)", (name, email, hashed))
#         conn.commit()
#         user_id = c.lastrowid
#         print(f"✅ [BACKEND] تم إنشاء المستخدم: {user_id}")
#         return {"message": "Signup successful", "userID": user_id, "name": name}
#     except sqlite3.IntegrityError:
#         print("❌ [BACKEND] البريد الإلكتروني مسجل مسبقاً")
#         raise HTTPException(status_code=400, detail="Email already exists")
#     except Exception as e:
#         print(f"❌ [BACKEND] خطأ غير متوقع: {e}")
#         raise HTTPException(status_code=500, detail=str(e))
#     finally:
#         conn.close()
 
 
# @users_router.post("/login/")
# def login(email: str = Form(...), password: str = Form(...)):
#     """
#     تسجيل دخول مستخدم
#     """
#     print(f"🎯 [BACKEND] طلب تسجيل دخول: {email}")
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT userID, name, password FROM users WHERE email=?", (email,))
#     user = c.fetchone()
#     conn.close()
#     if user:
#         user_id, name, hashed_text = user
#         print(f"🔍 [BACKEND] وجد المستخدم: {name}, الهاش: {hashed_text[:20]}...")
#         try:
#             # تحويل النص المخزن إلى bytes للمقارنة
#             hashed_bytes = hashed_text.encode("utf-8")
#             # التحقق من كلمة المرور
#             if bcrypt.checkpw(password.encode("utf-8"), hashed_bytes):
#                 print(f"✅ [BACKEND] تسجيل الدخول ناجح للمستخدم: {user_id}")
#                 return {"userID": user_id, "name": name}
#             else:
#                 print("❌ [BACKEND] كلمة المرور غير صحيحة")
#                 raise HTTPException(status_code=401, detail="Invalid credentials")
#         except Exception as e:
#             print(f"❌ [BACKEND] خطأ في المصادقة: {e}")
#             raise HTTPException(status_code=500, detail="Server error during authentication")
#     print("❌ [BACKEND] المستخدم غير موجود")
#     raise HTTPException(status_code=401, detail="Invalid credentials")
 
 
# @users_router.put("/edit/{userID}")
# def edit_profile(userID: int, name: str = Form(...), email: str = Form(...), password: str = Form(...)):
#     """
#     تعديل بيانات المستخدم
#     """
#     hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     try:
#         c.execute("UPDATE users SET name=?, email=?, password=? WHERE userID=?", 
#                  (name, email, hashed, userID))
#         conn.commit()
#         return {"message": "Profile updated"}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=str(e))
#     finally:
#         conn.close()
 
 
# @users_router.post("/logout/")
# def logout():
#     """
#     تسجيل خروج (رمزياً)
#     """
#     return {"message": "Logged out"}

from fastapi import APIRouter, HTTPException, Form
import sqlite3
from db import DB_NAME
import bcrypt
 
users_router = APIRouter()
 
@users_router.post("/signup/")
def signup(name: str = Form(...), email: str = Form(...), password: str = Form(...)):
    print(f"🎯 [BACKEND] طلب تسجيل جديد: {name}, {email}")
    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    try:
        c.execute("INSERT INTO users (name, email, password) VALUES (?, ?, ?)", (name, email, hashed))
        conn.commit()
        user_id = c.lastrowid
        print(f"✅ [BACKEND] تم إنشاء المستخدم: {user_id}")
        return {"message": "Signup successful", "userID": user_id, "name": name}
    except sqlite3.IntegrityError:
        print("❌ [BACKEND] البريد الإلكتروني مسجل مسبقاً")
        raise HTTPException(status_code=400, detail="Email already exists")
    except Exception as e:
        print(f"❌ [BACKEND] خطأ غير متوقع: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()
 
@users_router.post("/login/")
def login(email: str = Form(...), password: str = Form(...)):
    print(f"🎯 [BACKEND] طلب تسجيل دخول: {email}")
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    # (1) جلبنا الإيميل أيضاً من قاعدة البيانات للتأكد
    c.execute("SELECT userID, name, password, email FROM users WHERE email=?", (email,))
    user = c.fetchone()
    conn.close()
    if user:
        user_id, name, hashed_text, db_email = user
        print(f"🔍 [BACKEND] وجد المستخدم: {name}")
        try:
            hashed_bytes = hashed_text.encode("utf-8")
            if bcrypt.checkpw(password.encode("utf-8"), hashed_bytes):
                print(f"✅ [BACKEND] تسجيل الدخول ناجح للمستخدم: {user_id}")
                # (2) نرجع الإيميل هنا
                return {"userID": user_id, "name": name, "email": db_email}
            else:
                print("❌ [BACKEND] كلمة المرور غير صحيحة")
                raise HTTPException(status_code=401, detail="Invalid credentials")
        except Exception as e:
            print(f"❌ [BACKEND] خطأ في المصادقة: {e}")
            raise HTTPException(status_code=500, detail="Server error during authentication")
    print("❌ [BACKEND] المستخدم غير موجود")
    raise HTTPException(status_code=401, detail="Invalid credentials")
 
@users_router.put("/edit/{userID}")
def edit_profile(userID: int, name: str = Form(...), email: str = Form(...), password: str = Form(...)):
    # إذا كانت كلمة المرور المرسلة هي الكلمة الخاصة "SAME_PASSWORD" أو فارغة، لا نغيرها
    # ولكن للتبسيط سنقوم بتشفير ما يصلنا، تأكد من الفرونت اند
    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    try:
        # يمكن تحسين هذا للتحقق إذا الباسورد تغير أم لا، لكن سنمشي مع التحديث الكامل
        c.execute("UPDATE users SET name=?, email=?, password=? WHERE userID=?", 
                 (name, email, hashed, userID))
        conn.commit()
        return {"message": "Profile updated"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        conn.close()

@users_router.post("/logout/")
def logout():
    return {"message": "Logged out"}