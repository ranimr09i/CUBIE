# import sqlite3

# DB_NAME = "cubie.db"

# def init_db():
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()


#     # جدول المستخدم
#     c.execute("""
#     CREATE TABLE IF NOT EXISTS users (
#         userID INTEGER PRIMARY KEY AUTOINCREMENT,
#         name VARCHAR(100) NOT NULL,
#         email VARCHAR(255) UNIQUE NOT NULL,
#         password VARCHAR(100) NOT NULL
#     )
#     """)

#     # جدول الأطفال
#     c.execute("""
#     CREATE TABLE IF NOT EXISTS children (
#         childID INTEGER PRIMARY KEY AUTOINCREMENT,
#         userID INTEGER NOT NULL,
#         name VARCHAR(100) NOT NULL,
#         grade VARCHAR(50) NOT NULL,
#         age INTEGER NOT NULL,
#         gender TEXT CHECK(gender IN ('Male','Female')),
#         FOREIGN KEY(userID) REFERENCES users(userID)
#     )
#     """)

#     # جدول القصص
#     c.execute("""
#     CREATE TABLE IF NOT EXISTS stories (
#         storyID INTEGER PRIMARY KEY AUTOINCREMENT,
#         userID INTEGER NOT NULL,
#         genre VARCHAR(100),
#         preferences TEXT,
#         prompt TEXT,
#         generated_story TEXT,
#         audio_path VARCHAR(255),
#         FOREIGN KEY(userID) REFERENCES users(userID)
#     )
#     """)

#     conn.commit()
#     conn.close()



import sqlite3

DB_NAME = "cubie.db"

def init_db():
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()


    # جدول المستخدم
    c.execute("""
    CREATE TABLE IF NOT EXISTS users (
        userID INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(100) NOT NULL
    )
    """)

    # جدول الأطفال
    c.execute("""
    CREATE TABLE IF NOT EXISTS children (
        childID INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER NOT NULL,
        name VARCHAR(100) NOT NULL,
        grade VARCHAR(50) NOT NULL,  -- (1) تم إضافة القريد هنا
        age INTEGER NOT NULL,
        gender TEXT CHECK(gender IN ('Male','Female')),
        FOREIGN KEY(userID) REFERENCES users(userID)
    )
    """)

    # جدول القصص
    c.execute("""
    CREATE TABLE IF NOT EXISTS stories (
        storyID INTEGER PRIMARY KEY AUTOINCREMENT,
        userID INTEGER NOT NULL,
        genre VARCHAR(100),
        preferences TEXT,
        prompt TEXT,
        generated_story TEXT,
        audio_path VARCHAR(255),
        FOREIGN KEY(userID) REFERENCES users(userID)
    )
    """)

    conn.commit()
    conn.close()

# (قم بتشغيل هذا الملف مرة واحدة لإنشاء/تحديث الجداول)
if __name__ == "__main__":
    init_db()
    print("Database initialized.")
    
    # (أضف هذا الكود في نهاية ملف backend/db.py)

def get_user_id_for_story(conn, story_id):
    """
    (جديد) يجيب الـ userID المرتبط بالقصة
    """
    try:
        c = conn.cursor()
        c.execute("SELECT userID FROM stories WHERE storyID=?", (story_id,))
        row = c.fetchone()
        return row[0] if row else None
    except Exception as e:
        print(f"Error getting userID for story: {e}")
        return None