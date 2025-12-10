from fastapi import APIRouter, Depends, HTTPException, Form
from sqlalchemy.orm import Session
from database import User, get_db
from passlib.context import CryptContext


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
router = APIRouter()

@router.post("/users/signup/")
async def signup(
    name: str = Form(...), 
    email: str = Form(...), 
    password: str = Form(...), 
    db: Session = Depends(get_db)
):
    existing_user = db.query(User).filter(User.email == email).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already exists")
    
    hashed_password = pwd_context.hash(password) 
    new_user = User(
        name=name,
        email=email,
        password=hashed_password 
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"message": "User created", "userID": new_user.userID}


@router.post("/users/login/")
async def login(email: str = Form(...), password: str = Form(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == email).first()
    

    if not user or not pwd_context.verify(password, user.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    print(f"🎯 [BACKEND] طلب تسجيل دخول: {email}")
    print(f"✅ [BACKEND] تسجيل الدخول ناجح للمستخدم: {user.userID}")

    return {
        "message": "Login successful",
        "userID": user.userID,
        "name": user.name
    }

@router.put("/users/edit/{user_id}")
async def edit_profile(
    user_id: int, 
    name: str = Form(...), 
    email: str = Form(...), 
    password: str = Form(None), 
    db: Session = Depends(get_db)
):
    user = db.query(User).get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.name = name
    user.email = email
    if password:
        user.password = pwd_context.hash(password) # تشفير الباسورد الجديد
        
    db.commit()
    return {"message": "Profile updated"}