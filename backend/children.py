# from fastapi import APIRouter, HTTPException, Query, Form
# import sqlite3
# from db import DB_NAME

# children_router = APIRouter()

# @children_router.get("/list/{userID}")
# def list_children(userID: int):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT childID, name, age, gender FROM children WHERE userID=?", (userID,))
#     rows = c.fetchall()
#     conn.close()
#     children = [{"childID": r[0], "name": r[1], "age": r[2], "gender": r[3]} for r in rows]
#     return {"children": children}

# @children_router.post("/add/")
# def add_child(userID: int = Form(...), name: str = Form(...), age: int = Form(...), gender: str = Form(...)):
#     if gender not in ["Male", "Female"]:
#         raise HTTPException(status_code=400, detail="Gender must be 'Male' or 'Female'")
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("INSERT INTO children (userID, name, age, gender) VALUES (?, ?, ?, ?)", (userID, name, age, gender))
#     conn.commit()
#     child_id = c.lastrowid
#     conn.close()
#     return {"message": "Child added", "childID": child_id}

# @children_router.put("/edit/{childID}")
# def edit_child(childID: int, name: str = Form(...), age: int = Form(...), gender: str = Form(...)):
#     if gender not in ["Male", "Female"]:
#         raise HTTPException(status_code=400, detail="Gender must be 'Male' or 'Female'")
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("UPDATE children SET name=?, age=?, gender=? WHERE childID=?", (name, age, gender, childID))
#     conn.commit()
#     conn.close()
#     return {"message": "Child updated"}

# @children_router.post("/delete/{childID}")
# def delete_child(childID: int):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("DELETE FROM children WHERE childID=?", (childID,))
#     conn.commit()
#     conn.close()
#     return {"message": "Child deleted"}

# # SELECT endpoint (frontend calls this BEFORE /chat/start)
# @children_router.get("/select/{childID}")
# def select_child(childID: int, userID: int = Query(...)):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("SELECT childID, name, age, gender FROM children WHERE childID=? AND userID=?", (childID, userID))
#     row = c.fetchone()
#     conn.close()
#     if not row:
#         raise HTTPException(status_code=404, detail="Child not found for this user")
#     child = {"childID": row[0], "name": row[1], "age": row[2], "gender": row[3]}
#     # return child data for frontend to show/select; frontend then calls /chat/start with childID & userID
#     return {"selected_child": child}









# from fastapi import APIRouter, HTTPException, Query, Form
# import sqlite3
# from db import DB_NAME

# children_router = APIRouter()

# @children_router.get("/list/{userID}")
# def list_children(userID: int):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     # <-- (1) إضافة grade للـ SELECT
#     c.execute("SELECT childID, name, age, gender, grade FROM children WHERE userID=?", (userID,))
#     rows = c.fetchall()
#     conn.close()
#     # <-- (2) إضافة grade للـ response
#     children = [{"childID": r[0], "name": r[1], "age": r[2], "gender": r[3], "grade": r[4]} for r in rows]
#     return {"children": children}

# @children_router.post("/add/")
# def add_child(
#     userID: int = Form(...), 
#     name: str = Form(...), 
#     age: int = Form(...), 
#     gender: str = Form(...),
#     grade: str = Form(...)  # <-- (3) إضافة grade كـ Form field
# ):
#     if gender not in ["Male", "Female"]:
#         raise HTTPException(status_code=400, detail="Gender must be 'Male' or 'Female'")
    
#     # <-- (4) التحقق من الـ grade (اختياري لكن جيد)
#     valid_grades = ['KG', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6']
#     if grade not in valid_grades:
#         raise HTTPException(status_code=400, detail=f"Grade must be one of: {valid_grades}")

#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     # <-- (5) إضافة grade للـ INSERT
#     c.execute("INSERT INTO children (userID, name, age, gender, grade) VALUES (?, ?, ?, ?, ?)", 
#               (userID, name, age, gender, grade))
#     conn.commit()
#     child_id = c.lastrowid
#     conn.close()
#     return {"message": "Child added", "childID": child_id}

# @children_router.put("/edit/{childID}")
# def edit_child(
#     childID: int, 
#     name: str = Form(...), 
#     age: int = Form(...), 
#     gender: str = Form(...),
#     grade: str = Form(...)  # <-- (6) إضافة grade كـ Form field
# ):
#     if gender not in ["Male", "Female"]:
#         raise HTTPException(status_code=400, detail="Gender must be 'Male' or 'Female'")
    
#     valid_grades = ['KG', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6']
#     if grade not in valid_grades:
#         raise HTTPException(status_code=400, detail=f"Grade must be one of: {valid_grades}")

#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     # <-- (7) إضافة grade للـ UPDATE
#     c.execute("UPDATE children SET name=?, age=?, gender=?, grade=? WHERE childID=?", 
#               (name, age, gender, grade, childID))
#     conn.commit()
#     conn.close()
#     return {"message": "Child updated"}

# @children_router.post("/delete/{childID}")
# def delete_child(childID: int):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     c.execute("DELETE FROM children WHERE childID=?", (childID,))
#     conn.commit()
#     conn.close()
#     return {"message": "Child deleted"}

# @children_router.get("/select/{childID}")
# def select_child(childID: int, userID: int = Query(...)):
#     conn = sqlite3.connect(DB_NAME)
#     c = conn.cursor()
#     # <-- (8) إضافة grade للـ SELECT
#     c.execute("SELECT childID, name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
#     row = c.fetchone()
#     conn.close()
#     if not row:
#         raise HTTPException(status_code=404, detail="Child not found for this user")
#     # <-- (9) إضافة grade للـ response
#     child = {"childID": row[0], "name": row[1], "age": row[2], "gender": row[3], "grade": row[4]}
#     return {"selected_child": child}


from fastapi import APIRouter, HTTPException, Query, Form
import sqlite3
from db import DB_NAME

children_router = APIRouter()

@children_router.get("/list/{userID}")
def list_children(userID: int):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    # (1) إضافة grade للـ SELECT
    c.execute("SELECT childID, name, age, gender, grade FROM children WHERE userID=?", (userID,))
    rows = c.fetchall()
    conn.close()
    # (2) إضافة grade للـ response
    children = [{"childID": r[0], "name": r[1], "age": r[2], "gender": r[3], "grade": r[4]} for r in rows]
    return {"children": children}

@children_router.post("/add/")
def add_child(
    userID: int = Form(...), 
    name: str = Form(...), 
    age: int = Form(...), 
    gender: str = Form(...),
    grade: str = Form(...)  # (3) إضافة grade كـ Form field
):
    if gender not in ["Male", "Female"]:
        raise HTTPException(status_code=400, detail="Gender must be 'Male' or 'Female'")
    
    valid_grades = ['KG', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6']
    if grade not in valid_grades:
        raise HTTPException(status_code=400, detail=f"Grade must be one of: {valid_grades}")

    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    # (4) إضافة grade للـ INSERT
    c.execute("INSERT INTO children (userID, name, age, gender, grade) VALUES (?, ?, ?, ?, ?)", 
              (userID, name, age, gender, grade))
    conn.commit()
    child_id = c.lastrowid
    conn.close()
    return {"message": "Child added", "childID": child_id}

@children_router.put("/edit/{childID}")
def edit_child(
    childID: int, 
    name: str = Form(...), 
    age: int = Form(...), 
    gender: str = Form(...),
    grade: str = Form(...)  # (5) إضافة grade كـ Form field
):
    if gender not in ["Male", "Female"]:
        raise HTTPException(status_code=400, detail="Gender must be 'Male' or 'Female'")
    
    valid_grades = ['KG', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6']
    if grade not in valid_grades:
        raise HTTPException(status_code=400, detail=f"Grade must be one of: {valid_grades}")

    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    # (6) إضافة grade للـ UPDATE
    c.execute("UPDATE children SET name=?, age=?, gender=?, grade=? WHERE childID=?", 
              (name, age, gender, grade, childID))
    conn.commit()
    conn.close()
    return {"message": "Child updated"}

@children_router.post("/delete/{childID}")
def delete_child(childID: int):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    c.execute("DELETE FROM children WHERE childID=?", (childID,))
    conn.commit()
    conn.close()
    return {"message": "Child deleted"}

@children_router.get("/select/{childID}")
def select_child(childID: int, userID: int = Query(...)):
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    # (7) إضافة grade للـ SELECT
    c.execute("SELECT childID, name, age, gender, grade FROM children WHERE childID=? AND userID=?", (childID, userID))
    row = c.fetchone()
    conn.close()
    if not row:
        raise HTTPException(status_code=404, detail="Child not found for this user")
    # (8) إضافة grade للـ response
    child = {"childID": row[0], "name": row[1], "age": row[2], "gender": row[3], "grade": row[4]}
    return {"selected_child": child}